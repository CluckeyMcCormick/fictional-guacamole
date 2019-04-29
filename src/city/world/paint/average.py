
"""
average.py

Contains functions for evaluating the averages in 
"""

def assign_averages(world_data):
    avg_x_len, avg_y_len = world_data.base_average.sizes

    for x in range(avg_x_len):
        for y in range(avg_y_len):
            # Get the maximum value
            max_val = None
            max_amount = -1

            for key in range(world_data.primary_types):
                count = world_data.base_average[x, y].counts[key]
                if count > max_amount:
                    max_val = key
                    max_amount = count

            world_data.base_average[x, y].avg = max_val
