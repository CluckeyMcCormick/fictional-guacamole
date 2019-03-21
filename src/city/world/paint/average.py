
"""
average.py

Contains functions for evaluating the averages in 
"""

from ..data import AVERAGE_ZONE_LEN

def assign_averages(world_data):
    x_len, y_len = world_data.get_sizes()

    avg_x_len = x_len // AVERAGE_ZONE_LEN
    avg_y_len = y_len // AVERAGE_ZONE_LEN

    average_shaped = world_data.make_average_shaped()
    counts_shaped = world_data.make_counts_shaped()

    for x in range(avg_x_len):
        for y in range(avg_y_len):
            # Get the maximum value
            max_val = None
            max_amount = -1

            for key in range(world_data.primary_types):
                if counts_shaped[x, y, key] > max_amount:
                    max_val = key
                    max_amount = counts_shaped[x, y, key]

            average_shaped[x, y] = max_val
