import numpy
import random
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

def build_world(world_raw, complete_val, orders, sizes):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            shaped_world[x, y] = random.randint(0, 7)

    complete_val = True

def paint_terrain(world_raw, complete_val, orders, sizes):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            shaped_world[x, y] = random.randint(0, 7)

    complete_val = True

def perform_work(func, raw_world, lens, extra_args=[]):
    workers = DEFAULT_WORKERS

    # Starts the worker processes for building the world
    complete_vals = [ mp.Value(c_bool, False) for _ in range(workers) ]
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

        args = [raw_world, complete[i], orders, lens]
        args.extend(extra_args)

        p = mp.Process(
            target=func, 
            args=args
        )
        # Store the process
        procs[i] = p

        p.start()

    complete = False

    # While we're not finished
    while not complete:
        all_comp = True
        # Evaluate each process for completion
        for val in complete_vals:
            if not val:
                all_comp = False
        complete = all_comp

    # Otherwise, joins the processes
    for p in procs:
        p.join()