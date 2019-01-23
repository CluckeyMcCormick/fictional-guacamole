import multiprocessing as mp
import numpy
import random
# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_bool

class WorldMaker(object):
    """docstring for WorldMaker"""
    def __init__(self, x_size, y_size, workers):
        super(WorldMaker, self).__init__()
        self.x_size = x_size
        self.y_size = y_size
        self.workers = workers

        # Create the world data array that we'll be using
        self.world_raw = mp.Array(c_byte, x_size * y_size)
        # Create the status array - are our workers done yet?
        self.complete = [ mp.Value(c_bool, False) for _ in range(workers) ]

        self.procs = [None for _ in range(workers)]

    def build(self):
        # Divy up the workload - how much will each process do?
        x_step = self.x_size // self.workers

        sizes = (self.x_size, self.y_size)

        # For each worker process
        for i in range(self.workers):
            # If we're on the last iteration, do last
            if i == self.workers - 1:
                orders = (x_step * i, self.x_size)
            else:
                orders = (x_step * i, x_step * (i + 1))

            p = mp.Process(
                target=build_world, 
                args=(self.world_raw, self.complete[i], orders, sizes)
            )
            self.procs[i] = p

            p.start()

    def is_done(self):
        # If we're still waiting on a worker, back out
        for val in self.complete:
            if not val:
                return

        for p in self.procs:
            p.join()

        # If all the booleans report true
        # return the raw world array & the sizing
        return self.world_raw

def build_world(world_raw, complete_val, orders, sizes):
    _, y_size = sizes
    first, limit = orders

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = numpy.frombuffer( world_raw.get_obj(), dtype=c_byte ).reshape( sizes )

    for x in range(first, limit):
        for y in range(y_size):
            shaped_world[x, y] = random.randint(0, 7)

    complete_val = True