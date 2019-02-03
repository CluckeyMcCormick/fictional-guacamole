import multiprocessing as mp
import numpy
import random
import math
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

from . import terrain_painter

# Everytime we do a parallel-izable process, how many workers work on it?
DEFAULT_WORKERS = 8

# How many Voroni Points/Polygons do we generate?
VORONI_POINTS = 256

MAX_VORONI_DIST = 64

DEFAULT_CHOICE = 1

BASE = 0

def build_world(raw_arr, complete_val, sizes):

    scale = 100.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    ex_args = [ scale, octaves, persistence, lacunarity, BASE ]
    perform_work(terrain_painter.perlin, raw_arr[0], sizes, extra_args=ex_args)

    # Since this a mp.Value object, we have to manually change 
    # the Value.value's value. Ooof.
    complete_val.value = True

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
