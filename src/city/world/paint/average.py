
import math

"""
average.py

Contains functions for evaluating the averages in 
"""

def assign_averages(world_data):
    avg_x_len, avg_y_len = world_data.base_average.sizes

    for avg_x in range(avg_x_len):
        for avg_y in range(avg_y_len):
            # Get the maximum value
            max_val = None
            max_amount = -math.inf

            origin_x = world_data.avg_size_x * avg_x
            origin_y = world_data.avg_size_y * avg_y

            values = {}

            for add_x in range(world_data.avg_size_x):
                for add_y in range(world_data.avg_size_y):
                    try:
                        current = world_data.base[origin_x + add_x, origin_y + add_y]
                    except Exception as e:
                        raise Exception("({0}, {1}) | [{2}, {3}] | ({4} {5})".format(
                            avg_x, avg_y, origin_x, origin_y,
                            origin_x + add_x, origin_y + add_y
                        ))

                    
                    if current in values:
                        values[current] += 1
                    else:
                        values[current] = 1

                    if values[current] > max_amount:
                        max_val = current
                        max_amount = values[current]

            world_data.base_average[avg_x, avg_y] = max_val
