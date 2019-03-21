"""
lake.py

Contains functions for generating lakes in the world.
"""

import random

from ..assets.terrain_primary import PrimaryKey
from ..data import AVERAGE_ZONE_LEN

# The mean lake size
LAKE_SIZE_MU = 4

# The variance in lake size
LAKE_SIZE_SIGMA = 1

# The mean distance of each sub-lake from the center lake
LAKE_POS_MU = 3

# The variance in sub-lake distance
LAKE_POS_SIGMA = 2

# The mean number of lakes in a chain
LAKE_CHAIN_MU = 5

# The variance of lakes in a chain.
LAKE_CHAIN_SIGMA = 2

# The mean number of lakes in a chain
LAKE_COUNT_MU = 4

# The variance of lakes in a chain.
LAKE_COUNT_SIGMA = 1

# The margin for placing lake centers
LAKE_CENTER_MARGIN = 24

def generate_lake_chains(world_data):

    lake_list = []

    # Get the maximum values possible for our world 
    world_max_x, world_max_y = world_data.sizes

    # Calculate the minimum position for a lake
    min_x = LAKE_CENTER_MARGIN
    min_y = LAKE_CENTER_MARGIN

    # Calculate the maximum position for a lake
    max_x = world_max_x - LAKE_CENTER_MARGIN
    max_y = world_max_y - LAKE_CENTER_MARGIN

    # Calculate the number of lake chains we'll be making
    lake_count = int(random.gauss(LAKE_COUNT_MU, LAKE_COUNT_SIGMA))

    for _ in range( lake_count ):
        center_x = random.randint(min_x, max_x) 
        center_y = random.randint(min_y, max_y)

        # Stores the points that make up the current lake chain
        current_chain = []

        # Calculate the number of lake points we want in the current chain
        chain_length = int( random.gauss(LAKE_CHAIN_MU, LAKE_CHAIN_SIGMA))
        # There must be at least one lake point in the chain
        chain_length = max( chain_length, 1 )

        for i in range(chain_length):

            # If this is the first lake, then use the generated center
            if i == 0:
                center = (center_x, center_y)

            # Otherwise...
            else:
                # Choose a random center in the chain to shift from
                c_x, c_y = random.choice(current_chain)[0]

                # Calculate a magnitude to shift on
                adj_x = random.gauss(LAKE_POS_MU, LAKE_POS_SIGMA)
                # Then give it a direction...
                adj_x *= random.choice([-1, 1])

                # Ditto for y
                adj_y = random.gauss(LAKE_POS_MU, LAKE_POS_SIGMA)
                adj_y *= random.choice([-1, 1])

                center = ( int(c_x + adj_x), int(c_y + adj_y) )

            size = int(random.gauss(LAKE_SIZE_MU, LAKE_SIZE_SIGMA))

            current_chain.append( (center, size) )

        lake_list.append( current_chain )

    return lake_list

def paint_square_lake(world_data, lake_points, tile_set):

    for center, radius in lake_points:

        c_x, c_y = center

        for shift_x in range(-radius, radius + 1):
            for shift_y in range(-radius, radius + 1):

                x = c_x + shift_x
                y = c_y + shift_y

                avg_x = x // AVERAGE_ZONE_LEN
                avg_y = y // AVERAGE_ZONE_LEN

                # Decide whether we're painting sand or water
                if abs(shift_x) == radius or abs(shift_y) == radius:
                    enum = PrimaryKey.SAND
                else:
                    enum = PrimaryKey.WATER

                designate = tile_set.get_designate(enum)

                # If we're going to paint the current tile sand...
                if enum == PrimaryKey.SAND:
                    # Check if it's water...
                    water_designate = tile_set.get_designate(PrimaryKey.WATER)
                    if world_data.base[x, y] == water_designate:
                        # If it is water, then skip. We don't want to ruin an 
                        # existing lake!
                        continue

                # Update the world map
                world_data.base[x, y] = designate


