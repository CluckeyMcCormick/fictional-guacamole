import multiprocessing as mp
import numpy
import random
import math
import noise
import operator
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool, c_int16

from .assets.terrain_primary import PrimaryKey
from .assets.terrain_detail import EdgeKey, DetailKey
from .data import AVERAGE_ZONE_LEN

# Everytime we do a parallel-izable process, how many workers work on it?
DEFAULT_WORKERS = 8

# How many Voroni Points/Polygons do we generate?
VORONI_POINTS = 256

MAX_VORONI_DIST = 64

DEFAULT_CHOICE = 1

BASE = 1

def build_world(world_data, complete_val, primary_ts, detail_ts):
    """
    The build_world function is our main building algorithm. It's main role is
    in deciding what arguments to pass to our world painting methods and what
    order to call them in.
    """
    scale = 100.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    print("\n\tStarting perlin gen..\n\n")
    kw_args = {
        "tile_set" : primary_ts
    }
    perform_spatial_work(only_grass, world_data, kw_args=kw_args)

    print("\n\tLake Painting...\n\n")
    lakes = generate_lake_chains( world_data )
    kw_args = { "tile_set" : primary_ts }
    perform_work(paint_square_lake, world_data, lakes, kw_args=kw_args)

    print("\n\tAssigning averages...\n\n")
    assign_averages(world_data)

    print("\n\tPerforming the ever important edge pass...\n\n")

    kw_args = {
        "world_ts" : primary_ts, "detail_ts" : detail_ts, 
    }
    perform_spatial_work(edge_pass, world_data, kw_args=kw_args)

    # Since this a mp.Value object, we have to manually change 
    # the Value.value's value. Ooof.
    complete_val.value = True

# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~

def perform_spatial_work(func, world_data, in_args=[], kw_args={}):
    """
    Divies up the given world into DEFAULT_WORKERS chunks, then supplies those
    as orders to the given func
    """
    CHUNK_COUNT = DEFAULT_WORKERS

    # Starts the worker processes for building the world
    orders = []

    # Get the x_len and y_len, but dump the y_len since we don't need it
    x_len, _ = world_data.get_sizes()

    # How many x-columns will each process be responsible for?
    x_step = x_len // CHUNK_COUNT

    # For each worker process
    for i in range(CHUNK_COUNT):
        # If we're on the last iteration, do last
        if i == CHUNK_COUNT - 1:
            o = (x_step * i, x_len)
        # Otherwise, divy up the world
        else:
            o = (x_step * i, x_step * (i + 1))

        orders.append(o)

    perform_work(func, world_data, orders, in_args=in_args, kw_args=kw_args)

def perform_work(func, world_data, orders, in_args=[], kw_args={}):
    """
    For each item in orders, starts a Process running *func* with world_data,
    orders, in_args, and kw_args as arguments.
    """
    # Starts the worker processes for building the world
    procs = []
    
    # For each worker process
    for o in orders:
        # First args are always world_data and orders
        args = [world_data, o]
        args.extend(in_args)

        p = mp.Process(target=func, args=args, kwargs=kw_args)

        # Store the process
        procs.append(p)

        p.start()

    # Join the processes
    # We don't care if the world build process blocks, so we just try and join
    # straight away
    for p in procs:
        p.join()


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#       World Painting Methods!!!!!!!!!!!!!!
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def assign_averages(world_data):
    x_len, y_len = world_data.get_sizes()

    avg_x_len = x_len // AVERAGE_ZONE_LEN
    avg_y_len = y_len // AVERAGE_ZONE_LEN

    average_shaped = world_data.make_average_shaped()
    counts_shaped = world_data.make_counts_shaped()

    for x in range(avg_x_len):
        for y in range(avg_y_len):
            # Get the maximum value
            max_val = None
            max_amount = -1

            for key in range(world_data.primary_types):
                if counts_shaped[x, y, key] > max_amount:
                    max_val = key
                    max_amount = counts_shaped[x, y, key]

            average_shaped[x, y] = max_val

# The mean lake size
LAKE_SIZE_MU = 4

# The variance in lake size
LAKE_SIZE_SIGMA = 1

# The mean distance of each sub-lake from the center lake
LAKE_POS_MU = 3

# The variance in sub-lake distance
LAKE_POS_SIGMA = 2

# The mean number of lakes in a chain
LAKE_CHAIN_MU = 5

# The variance of lakes in a chain.
LAKE_CHAIN_SIGMA = 2

# The mean number of lakes in a chain
LAKE_COUNT_MU = 4

# The variance of lakes in a chain.
LAKE_COUNT_SIGMA = 1

# The margin for placing lake centers
LAKE_CENTER_MARGIN = 24

def generate_lake_chains(world_data):

    lake_list = []

    # Get the maximum values possible for our world 
    world_max_x, world_max_y = world_data.get_sizes()

    # Calculate the minimum position for a lake
    min_x = LAKE_CENTER_MARGIN
    min_y = LAKE_CENTER_MARGIN

    # Calculate the maximum position for a lake
    max_x = world_max_x - LAKE_CENTER_MARGIN
    max_y = world_max_y - LAKE_CENTER_MARGIN

    # Calculate the number of lake chains we'll be making
    lake_count = int(random.gauss(LAKE_COUNT_MU, LAKE_COUNT_SIGMA))

    for _ in range( lake_count ):
        center_x = random.randint(min_x, max_x) 
        center_y = random.randint(min_y, max_y)

        # Stores the points that make up the current lake chain
        current_chain = []

        # Calculate the number of lake points we want in the current chain
        chain_length = int( random.gauss(LAKE_CHAIN_MU, LAKE_CHAIN_SIGMA))
        # There must be at least one lake point in the chain
        chain_length = max( chain_length, 1 )

        for i in range(chain_length):

            # If this is the first lake, then use the generated center
            if i == 0:
                center = (center_x, center_y)

            # Otherwise...
            else:
                # Choose a random center in the chain to shift from
                c_x, c_y = random.choice(current_chain)[0]

                # Calculate a magnitude to shift on
                adj_x = random.gauss(LAKE_POS_MU, LAKE_POS_SIGMA)
                # Then give it a direction...
                adj_x *= random.choice([-1, 1])

                # Ditto for y
                adj_y = random.gauss(LAKE_POS_MU, LAKE_POS_SIGMA)
                adj_y *= random.choice([-1, 1])

                center = ( int(c_x + adj_x), int(c_y + adj_y) )

            size = int(random.gauss(LAKE_SIZE_MU, LAKE_SIZE_SIGMA))

            current_chain.append( (center, size) )

        print( current_chain )

        lake_list.append( current_chain )

    return lake_list

def paint_square_lake(world_data, lake_points, tile_set):

    # Using numpy, reshape the raw array so we can work on it in terms of x, y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    for center, radius in lake_points:

        c_x, c_y = center

        for shift_x in range(-radius, radius + 1):
            for shift_y in range(-radius, radius + 1):

                x = c_x + shift_x
                y = c_y + shift_y

                avg_x = x // AVERAGE_ZONE_LEN
                avg_y = y // AVERAGE_ZONE_LEN

                # Decide whether we're painting sand or water
                if abs(shift_x) == radius or abs(shift_y) == radius:
                    enum = PrimaryKey.SAND
                else:
                    enum = PrimaryKey.WATER

                designate = tile_set.get_designate(enum)

                # If we're going to paint the current tile sand...
                if enum == PrimaryKey.SAND:
                    # Check if it's water...
                    water_designate = tile_set.get_designate(PrimaryKey.WATER)
                    if shaped_world[x, y] == water_designate:
                        # If it is water, then skip. We don't want to ruin an 
                        # existing lake!
                        continue

                # Update the average roster
                shaped_counts[avg_x, avg_y, shaped_world[x, y]] -= 1
                shaped_counts[avg_x, avg_y, designate] += 1

                # Set the current tile to the closest point type
                shaped_world[x, y] = designate

def make_voroni_points(sizes, points, choice_list):

    x_size, y_size = sizes

    # First, build some Voroni Points:
    voronis = []

    for i in range(points):
        choice = random.choice( choice_list )
        x = random.randint(0, x_size - 1)
        y = random.randint(0, y_size - 1)

        voronis.append( ( (x, y), choice ) )

    return voronis

# CRED: Credit goes to Rosetta Code's Voroni Diagram article/thing for
# at least some of this algorithm (especially the math.hypot part)
# https://rosettacode.org/wiki/Voronoi_diagram#Python
def voroni(world_data, orders, tile_set, points, max_dist, default):
    _, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    for x in range(first, limit):
        for y in range(y_size):
            # Find the closest point
            closest_dist = math.inf
            closest_choice = default

            # For each point...
            for coord, choice in points:
                c_x, c_y = coord
                # Calculate the distance
                dist = math.hypot( c_x - x, c_y - y )
                # If it's closer, than use that point!
                if (dist < closest_dist) and (dist < max_dist):
                    closest_dist = dist
                    closest_choice = choice
            
            designate = tile_set.get_designate(closest_choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, shaped_world[x, y]] -= 1
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

# CRED: Credit goes to Yvan Scher's article about Perlin noise in Python.
# Revelead unto me the existence of the Python noise module, and gave some an
# example to start playing with.
# https://medium.com/@yvanscher/playing-with-perlin-noise-generating-realistic-archipelagos-b59f004d8401
def perlin(world_data, orders, tile_set, scale, octaves, persistence, lacunarity, base):
    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    for x in range(first, limit):
        for y in range(y_size):

            value = noise.pnoise2(
                x/scale, y/scale, 
                octaves=octaves, persistence=persistence, 
                lacunarity=lacunarity, 
                repeatx=x_size, repeaty=y_size, base=base
            )

            choice = PrimaryKey.GRASS
            
            if value < -0.4:
                choice = PrimaryKey.STONE 

            elif value < -0.35:
                choice = PrimaryKey.DIRT

            elif value < 0.35:
                choice = PrimaryKey.GRASS

            elif value < 0.4:
                choice = PrimaryKey.DIRT 

            elif value < 1.0:
                choice = PrimaryKey.STONE

            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, shaped_world[x, y]] -= 1
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

def only_grass(world_data, orders, tile_set):
    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    for x in range(first, limit):
        for y in range(y_size):

            choice = PrimaryKey.GRASS

            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

def stochastic(world_data, orders, tile_set):
    _, y_size = world_data.get_sizes()
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    shaped_counts = world_data.make_counts_shaped()

    choice_list = list(PrimaryKey)

    for x in range(first, limit):
        for y in range(y_size):
            choice = random.choice( choice_list )
            designate = tile_set.get_designate(choice)

            avg_x = x // AVERAGE_ZONE_LEN
            avg_y = y // AVERAGE_ZONE_LEN

            # Update the average roster
            shaped_counts[avg_x, avg_y, shaped_world[x, y]] -= 1
            shaped_counts[avg_x, avg_y, designate] += 1

            # Set the current tile to the closest point type
            shaped_world[x, y] = designate

def edge_pass(world_data, orders, world_ts, detail_ts):
    """
    The world is a series of tiles, like this:
         |       |       |
        -+---+---+---+---+- The left hand side is a normal tile, bereft of any
         |       |   |   |  detail markings. The right hand side is a tile with
         |       | 2 | 3 |  detail markings. As you can see, each tile has four
         |       |   |   |  detail tiles that occupy the corners.
         |       |---+---+-
         |       |   |   |  The edge pass algorithm observes each detail tile's
         |       | 0 | 1 |  applicable neighbors: one above or below, one left
         |       |   |   |  or right, and one corner-wise. It then determines
        -+---+---+---+---+- which edge tile would be best for that detail tile.
         |       |       |    
    """

    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # The detail world assigns 4 sub-tiles to each primary tile, and is thusly
    # twice as big on each axis
    x_det_size = x_size * 2
    y_det_size = y_size * 2
    det_sizes = (x_det_size, y_det_size)

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    # Ditto for the detail array
    shaped_detail = world_data.make_detail_shaped()

    # The neighbor shifts on world_x and world_y, for each detail tile
    # We'll use these to quickly check the neighbor tiles for each detail tile
    shifts = [
        # n_horiz_a, n_vert_b, n_corner_c
        ( (-1, 0), (0, -1), (-1, -1) ), #(+0, +0) (0)
        ( ( 1, 0), (0, -1), ( 1, -1) ), #(+1, +0) (1)
        ( (-1, 0), (0,  1), (-1,  1) ), #(+0, +1) (2)
        ( ( 1, 0), (0,  1), ( 1,  1) )  #(+1, +1) (3)
    ]

    """
    Each edge tile has an enum constant, with a name of the form PRIMARY_EDGE,
    where PRIMARY is the primary tile type ( GRASS, STONE, DIRT ) and EDGE is
    the type of tile. 
    
    These strings are the EDGE component of those enum constants. There are four
    possible types of edge tile we'll need to place: an interior corner, a
    horizontal edge, a vertical edge, and an exterior corner. Each set of
    strings lines up with those edge types.
    """
    tile_strings = [
        # int_corner, horiz, vert, ext_corner
        ("LOWER_LEFT_INNER", "LEFT_EDGE_A", "BOTTOM_EDGE_A", "UPPER_RIGHT_OUTER"),  #(+0, +0)
        ("LOWER_RIGHT_INNER", "RIGHT_EDGE_A", "BOTTOM_EDGE_B", "UPPER_LEFT_OUTER"), #(+1, +0)
        ("UPPER_LEFT_INNER", "LEFT_EDGE_B", "TOP_EDGE_A", "LOWER_RIGHT_OUTER"),     #(+0, +1)
        ("UPPER_RIGHT_INNER", "RIGHT_EDGE_B", "TOP_EDGE_B", "LOWER_LEFT_OUTER")     #(+1, +1)
    ]

    for world_x in range(first, limit):
        for world_y in range(y_size):
            current_tile = world_ts.get_enum( shaped_world[world_x, world_y] )

            det_x = world_x * 2
            det_y = world_y * 2

            for i in range(4):

                # Get our neighbor tiles
                neighbor_list = []
                for pair in shifts[i]:
                    adj_x, adj_y = pair

                    # Value is None by default
                    value = None

                    # If we're in the appropriate boundaries...
                    if (0 <= world_x + adj_x < x_size) and (0 <= world_y + adj_y < y_size):
                        value = shaped_world[world_x + adj_x, world_y + adj_y]
                        value = world_ts.get_enum( value )
                    neighbor_list.append( value )

                # Pack those neighbor tiles into a tuple for easy access
                neighbor_tuple = (
                    neighbor_list[0], neighbor_list[1], neighbor_list[2]
                )

                edge_enum = edge_determine(current_tile, neighbor_tuple, tile_strings[i])

                adj_det_x = i % 2
                adj_det_y = i // 2

                value = detail_ts.get_designate( edge_enum )
                shaped_detail[det_x + adj_det_x, det_y + adj_det_y] = value

def enum_sort_key(enum):
    if enum is None:
        return math.inf
    else:
        return enum.value

def edge_determine(current_tile, neighbors, tiles):
    n_horiz_a, n_vert_b, n_corner_c = neighbors
    int_corner, horiz, vert, ext_corner = tiles

    # Step 1 : Determine what our "Dominant" tile type is
    # Sorts the list literal then grabs the first item which will have the
    # highest value enum
    dom_list = [current_tile, n_horiz_a, n_vert_b, n_corner_c]
    dom_list.sort(key=enum_sort_key)
    dominant = dom_list[0]

    # Step 2 : Error catching
    # If the dominant tile is our current one OR the dominant tile was a NONE
    # tile, back out
    if dominant == current_tile or dominant is None:
        return DetailKey.NONE

    # Step 3 : If cascade
    # Check if we want to make an interior corner
    target_tile = DetailKey.NONE

    if n_horiz_a == n_vert_b == dominant:
        target_tile = int_corner

    elif n_horiz_a == dominant:
        target_tile = horiz

    elif n_vert_b == dominant:
        target_tile = vert

    elif n_corner_c == dominant:
        target_tile = ext_corner

    # Return the chosen tile - combine the dominant tile with our edge tile
    return EdgeKey[dominant.name + '_' + target_tile]
