from . import (
	tiles, bresenham, enum
)

import math

def range_convert(old_min, old_max, new_min, new_max, in_val):

    val = in_val - old_min
    val /= (old_max - old_min)
    val *= new_max - new_min
    val += new_min

    return val;

def distance(x1, y1, x2, y2):
	return math.sqrt( (x1 - x2) ** 2 + (y1 - y2) ** 2 )

def tuple_distance(xy1, xy2):
	return distance(xy1[0], xy1[1], xy2[0], xy2[1])