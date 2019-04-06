from . import (
	tiles
)

def range_convert(old_min, old_max, new_min, new_max, in_val):

    val = in_val - old_min
    val /= (old_max - old_min)
    val *= new_max - new_min
    val += new_min

    return val;