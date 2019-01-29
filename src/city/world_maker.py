import multiprocessing as mp
import numpy
import random
import math
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

# Everytime we do a parallel-izable process, how many workers work on it?
DEFAULT_WORKERS = 8

# How many Voroni Points/Polygons do we generate?
VORONI_POINTS = 256

def build_world(raw_arr, complete_val, sizes):

    x_len, y_len = sizes

    # First, build some Voroni Points:
    voronis = []

    for i in range(VORONI_POINTS):
        choice = i % 8
        x = random.randint(0, x_len - 1)
        y = random.randint(0, y_len - 1)

        voronis.append( ( (x, y), choice ) )

    perform_work(paint_terrain_voroni, raw_arr[0], sizes, extra_args=[voronis])

    # Since this a mp.Value object, we have to manually change 
    # the Value.value's value. Ooof.
    complete_val.value = True

# CRED: Credit goes to Rosetta Code's Voroni Diagram article/thing for
# at least some of this algorithm (especially the math.hypot part)
# https://rosettacode.org/wiki/Voronoi_diagram#Python

def paint_terrain_voroni(world_raw, orders, sizes, points):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            # Find the closest point
            closest_dist = math.inf
            closest_choice = 0

            # For each point...
            for coord, choice in points:
                c_x, c_y = coord
                # Calculate the distance
                dist = math.hypot( c_x - x, c_y - y )
                # If it's closer, than use that point!
                if dist < closest_dist:
                    closest_dist = dist
                    closest_choice = choice
            
            # Set the current tile to the closest point type
            shaped_world[x, y] = closest_choice

def paint_terrain_random(world_raw, orders, sizes):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            shaped_world[x, y] = random.randint(0, 7)

# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~

def perform_work(func, raw_world, lens, extra_args=[]):
    """
    Divies up the given world into DEFAULT_WORKERS chunks, then calls func on
    each chunk (as it's own process)
    """
    workers = DEFAULT_WORKERS

    # Starts the worker processes for building the world
    procs = [None for _ in range(workers)]

    # Get the x_len and y_len, but dump the y_len since we don't need it
    x_len, _ = lens

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

        args = [raw_world, orders, lens]
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
