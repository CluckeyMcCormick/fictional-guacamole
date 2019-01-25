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