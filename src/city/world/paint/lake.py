"""
lake.py

Contains functions for generating lakes in the world.
"""

import random
import collections

import noise

from ..assets.terrain_primary import PrimaryKey
import game_util

"""
~~~~~~~~~~~~~~~~~~~~~~~~
~ General Lake Constants
~~~~~~~~~~~~~~~~~~~~~~~~
"""

# The mean number of lakes overall
LAKE_COUNT_MU = 4

# The variance in the number of overall lakes.
LAKE_COUNT_SIGMA = 1

"""
~~~~~~~~~~~~~~~~~~~~~~~~
~ Chain Lake Constants
~~~~~~~~~~~~~~~~~~~~~~~~
"""

# The mean lake size
CHAIN_SIZE_MU = 4

# The variance in lake size
CHAIN_SIZE_SIGMA = 1

# The mean distance of each sub-lake from the center lake
CHAIN_POS_MU = 3

# The variance in sub-lake distance
CHAIN_POS_SIGMA = 2

# The mean number of lakes in a chain
CHAIN_COUNT_MU = 5

# The variance of lakes in a chain.
CHAIN_COUNT_SIGMA = 2

# The margin for placing lake centers
CHAIN_CENTER_MARGIN = 24

class ChainLake(object):
    """
    Stores the necessary information to paint a ChainLake - primarily, a list
    of lake centers and a list of lake radii.
    """
    def __init__(self):
        """
        Creates a ChainLake object.
        """
        super(ChainLake, self).__init__()
        self.center_list = []
        self.radius_list = []

    def add_lake(self, center, radius):
        self.center_list.append( center )
        self.radius_list.append( radius )

    @property
    def center(self):
        if not self.center_list:
            return None
        else:
            return self.center_list[0]

    def __iter__(self):
        return zip( self.center_list, self.radius_list )

def generate_chain_lakes(world_data):

    lake_list = []

    # Get the maximum values possible for our world 
    world_max_x, world_max_y = world_data.sizes

    # Calculate the minimum position for a lake
    min_x = CHAIN_CENTER_MARGIN
    min_y = CHAIN_CENTER_MARGIN

    # Calculate the maximum position for a lake
    max_x = world_max_x - CHAIN_CENTER_MARGIN
    max_y = world_max_y - CHAIN_CENTER_MARGIN

    # Calculate the number of lake chains we'll be making
    lake_count = int(random.gauss(LAKE_COUNT_MU, LAKE_COUNT_SIGMA))

    for _ in range( lake_count ):
        center_x = random.randint(min_x, max_x) 
        center_y = random.randint(min_y, max_y)

        # The current lake chain
        lake = ChainLake()

        # Calculate the number of lake points we want in the current chain
        chain_length = int( random.gauss(CHAIN_COUNT_MU, CHAIN_COUNT_SIGMA))
        # There must be at least one lake point in the chain
        chain_length = max( chain_length, 1 )

        for i in range(chain_length):

            # If this is the first lake, then use the generated center
            if i == 0:
                center = (center_x, center_y)

            # Otherwise...
            else:
                # Choose a random center in the chain to shift from
                c_x, c_y = random.choice(lake.center_list)
                # Calculate a magnitude to shift on
                adj_x = random.gauss(CHAIN_POS_MU, CHAIN_POS_SIGMA)
                # Then give it a direction...
                adj_x *= random.choice([-1, 1])

                # Ditto for y
                adj_y = random.gauss(CHAIN_POS_MU, CHAIN_POS_SIGMA)
                adj_y *= random.choice([-1, 1])

                center = ( int(c_x + adj_x), int(c_y + adj_y) )

            size = int(random.gauss(CHAIN_SIZE_MU, CHAIN_SIZE_SIGMA))

            lake.add_lake(center, size)

        lake_list.append( lake )

    return lake_list

def paint_square_lake_chain(world_data, lake, tile_set):

    print("\tLake: ", lake.center)

    for center, radius in lake:

        c_x, c_y = center

        for shift_x in range(-radius, radius + 1):
            for shift_y in range(-radius, radius + 1):

                x = c_x + shift_x
                y = c_y + shift_y

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
                    if world_data.base[x, y] == water_designate:
                        # If it is water, then skip. We don't want to ruin an 
                        # existing lake!
                        continue

                # Update the world map
                world_data.base[x, y] = designate

"""
~~~~~~~~~~~~~~~~~~~~~
~ Fill Lake Constants
~~~~~~~~~~~~~~~~~~~~~
"""
# The minimum possible tolerance generated
FILL_MIN_TOLERANCE = 0.016

# The maximum possible tolerance generated
FILL_MAX_TOLERANCE = 0.04

class FillLake(object):
    """
    Stores the necessary information to paint a FillLake - the center of the
    lake, and the fill tolerance.
    """
    def __init__(self, center, tolerance):
        """
        Creates a FillLake object.

        Inputs:

        center: The center of the FillLake.

        tolerance: The tolerance for the fill. Given the algorithm we use, it
        is suggested that the value be between 0.016 and 0.04
        """
        super(FillLake, self).__init__()
        self.center = center
        self.tolerance = tolerance

def range_convert(new_min, new_max, in_val, old_min=0.0, old_max=1.0):

    return game_util.range_convert(old_min, old_max, new_min, new_max, in_val)

def generate_fill_lakes(world_data):
    # Calculate the number of FillLakes we'll be making
    lake_count = int( random.gauss(LAKE_COUNT_MU, LAKE_COUNT_SIGMA) )

    # Get the maximum values possible for our world 
    world_max_x, world_max_y = world_data.sizes

    lakes = []

    for _ in range( lake_count ):

        center_x = random.randint(0, world_max_x) 
        center_y = random.randint(0, world_max_y)

        tolerance = range_convert(FILL_MIN_TOLERANCE, FILL_MAX_TOLERANCE, random.random())

        print("\t", center_x, center_y, tolerance)

        lakes.append( FillLake((center_x, center_y), tolerance) )

    return lakes

def paint_fill_lake(world_data, fill_lake, tile_set, base):

    center = fill_lake.center
    tolerance = fill_lake.tolerance

    scale = 100.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    to_fill = collections.deque([center])
    filled = set([center])

    x, y = center

    x_max, y_max = world_data.sizes

    core_value = noise.pnoise2(
        x/scale, y/scale, 
        octaves=octaves, persistence=persistence, 
        lacunarity=lacunarity, 
        repeatx=x_max, repeaty=y_max, base=base
    ) 

    while to_fill:
        # Get the next tile
        x, y = to_fill.popleft()

        # Add it to our "visited" list
        filled.add( (x, y) )

        value = noise.pnoise2(
            x/scale, y/scale, 
            octaves=octaves, persistence=persistence, 
            lacunarity=lacunarity, 
            repeatx=x_max, repeaty=y_max, base=base
        )

        # If we're in the "tolerance" range, then this tile is water
        if core_value - tolerance <= value <= core_value + tolerance:
            enum = PrimaryKey.WATER

        # Otherwise, it's sand.
        else:
            enum = PrimaryKey.SAND

        # Get the enum's integer designation
        designate = tile_set.get_designate(enum)

        # Set the tile
        world_data.base[x, y] = designate

        # If our enum is SAND, then we're on an edge tile; skip adding any tiles
        if enum == PrimaryKey.SAND:
            continue

        for xplus in range(-1, 2):
            for yplus in range(-1, 2):

                # If this tile isn't a legitimate tile, skip it
                if not( 0 <= x + xplus < x_max and 0 <= y + yplus < y_max):
                    continue

                tile = (x + xplus, y + yplus)

                # If we already touched this tile (or will), we don't want to
                # do it again
                if tile in filled or tile in to_fill:
                    continue

                # Otherwise, if we made it here, add this tile to the stack
                to_fill.append( tile )
