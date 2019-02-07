import multiprocessing as mp
import numpy
import random
import math
import noise
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

from .assets.terrain_primary import PrimaryKey

# Everytime we do a parallel-izable process, how many workers work on it?
DEFAULT_WORKERS = 8

# How many Voroni Points/Polygons do we generate?
VORONI_POINTS = 256

MAX_VORONI_DIST = 64

DEFAULT_CHOICE = 1

BASE = 0

def build_world(raw_arr, complete_val, sizes, primary_ts, detail_ts):
    """
    The build_world function is our main building algorithm. It's main role is
    in deciding what arguments to pass to our world painting methods and what
    order to call them in.
    """
    scale = 100.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    ex_args = [ scale, octaves, persistence, lacunarity, BASE ]
    perform_work(perlin, raw_arr[0], sizes, primary_ts, extra_args=ex_args)

    # Since this a mp.Value object, we have to manually change 
    # the Value.value's value. Ooof.
    complete_val.value = True

# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~

def perform_work(func, raw_world, sizes, tile_set, extra_args=[]):
    """
    Divies up the given world into DEFAULT_WORKERS chunks, then calls func on
    each chunk (as it's own process)
    """
    workers = DEFAULT_WORKERS

    # Starts the worker processes for building the world
    procs = [None for _ in range(workers)]

    # Get the x_len and y_len, but dump the y_len since we don't need it
    x_len, _ = sizes

    # How many x-columns will each process be responsible for?
    x_step = x_len // workers

    # For each worker process
    for i in range(workers):
        # If we're on the last iteration, do last
        if i == workers - 1:
            orders = (x_step * i, x_len)
        # Otherwise, divy up the world
        else:
            orders = (x_step * i, x_step * (i + 1))

        args = [raw_world, orders, sizes, tile_set]
        args.extend(extra_args)

        p = mp.Process(
            target=func, 
            args=args
        )
        # Store the process
        procs[i] = p

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
def voroni(world_raw, orders, sizes, tile_set, points, max_dist, default):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

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
            
            # Set the current tile to the closest point type
            shaped_world[x, y] = tile_set.get_designate(closest_choice)

# CRED: Credit goes to Yvan Scher's article about Perlin noise in Python.
# Revelead unto me the existence of the Python noise module, and gave some an
# example to start playing with.
# https://medium.com/@yvanscher/playing-with-perlin-noise-generating-realistic-archipelagos-b59f004d8401
def perlin(world_raw, orders, sizes, tile_set, scale, octaves, persistence, lacunarity, base):
    x_size, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

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

            # Set the current tile to the closest point type
            shaped_world[x, y] = tile_set.get_designate(choice)

def stochastic(world_raw, orders, sizes, tile_set):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            choice = random.choice( list(PrimaryKey) )
            shaped_world[x, y] = tile_set.get_designate(choice)



