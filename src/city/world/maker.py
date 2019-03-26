import multiprocessing as mp

from . import paint

# Everytime we do a parallel-izable process, how many workers work on it?
DEFAULT_WORKERS = 8

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
    perform_spatial_work(paint.base.only_grass, world_data, kw_args=kw_args)

    print("\n\tLake Painting...\n\n")
    lakes = paint.lake.generate_chain_lakes( world_data )
    kw_args = { "tile_set" : primary_ts }
    perform_work(paint.lake.paint_square_lake_chain, world_data, lakes, kw_args=kw_args)

    print("\n\tAssigning averages...\n\n")
    paint.average.assign_averages(world_data)

    print("\n\tPerforming the ever important edge pass...\n\n")

    kw_args = {
        "world_ts" : primary_ts, "detail_ts" : detail_ts, 
    }
    perform_spatial_work(paint.edge.edge_pass, world_data, kw_args=kw_args)

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
    x_len, _ = world_data.sizes

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

