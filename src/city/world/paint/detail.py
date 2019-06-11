"""
detail.py

Contains functions for spreading detail tiles around the world.
"""
import random
import noise
import numpy

from ..assets.terrain_detail import DetailKey
from ..assets.terrain_primary import PrimaryKey
import game_util

"""
Distro Constants

Constants for choosing which tile distro we use.
"""

# The dictionary that specifies what values correspond to what PerlinDistros
DISTRO_DICT = None

DISTRO_MIN = -0.5
DISTRO_MAX = 0.5

DISTRO_CUSTOM_MIN = 0
DISTRO_CUSTOM_MAX = 30

# Inclusive values used to divide the perlin noise map into equal(ish) thirds
# Tested based on a 30 value range
DISTRO_LOWER_DIV_BOUNDRY = 13
DISTRO_UPPER_DIV_BOUNDRY = 17

"""
Placement Constants

Constants for choosing WHERE we place the detail tiles.
"""
# Places a tile when the perlin noise generator is BELOW this value
PLACE_BELOW = -0.35
# Places a tile when the perlin noise generator is ABOVE this value
PLACE_ABOVE = 0.35


class PerlinDistro(object):
    """
    A distribution for our Perlin blob maker. Describes which detail tiles can
    appear in a Perlin blob, and the probability weight for each tile.
    """
    def __init__(self, choice_weight_zip):
        super(PerlinDistro, self).__init__()
        self.choices, self.weights = zip(*choice_weight_zip)

    def get_choice(self):
        return numpy.random.choice(self.choices, 1, p=self.weights)[0]

# A custom range conversion function, with baked in variables
def noise_to_custom(in_val):
    return game_util.range_convert(
        DISTRO_MIN, DISTRO_MAX, 
        DISTRO_CUSTOM_MIN, DISTRO_CUSTOM_MAX, in_val
    )

def generate_value(x, y, sizes, base):
    x_size, y_size = sizes

    # Only tested with these values, so messing with them could be
    # unpredictable!
    scale = 10.0
    octaves = 10
    persistence = 0.5
    lacunarity = 2.0

    value = noise.pnoise2(
        x/scale, y/scale, 
        octaves=octaves, persistence=persistence, 
        lacunarity=lacunarity, 
        repeatx=x_size, repeaty=y_size, base=base
    )

    value = noise_to_custom(value)

    if value <= DISTRO_LOWER_DIV_BOUNDRY:
        value = 0
    elif value < DISTRO_UPPER_DIV_BOUNDRY:
        value = 1
    else:
        value = 2

    return value

def paint_grassy_detail(world_data, orders, base_set, detail_set):
    x_size, y_size = world_data.sizes
    first, limit = orders

    x_size *= 2
    y_size *= 2

    first *= 2
    limit *= 2

    place_base = 1
    a_layer_base = 2
    b_layer_base = 3

    scale = 10.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    # For each DETAIL TILE in our order set...
    for x in range(first, limit):
        for y in range(y_size):

            world_data.detail[x, y] = detail_set.get_designate(DetailKey.NONE)

            macro_x = x // 2
            macro_y = y // 2

            current_enum = base_set.get_enum( world_data.base[macro_x, macro_y] )
            if current_enum is not PrimaryKey.GRASS:
                continue
    
            place_value = noise.pnoise2(
                x/scale, y/scale, 
                octaves=octaves, persistence=persistence, 
                lacunarity=lacunarity, 
                repeatx=x_size, repeaty=y_size, base=place_base
            )

            if not (PLACE_BELOW < place_value < PLACE_ABOVE):
                a_value = generate_value(x, y, (x_size, y_size), a_layer_base)
                b_value = generate_value(x, y, (x_size, y_size), b_layer_base)

                choice = DISTRO_DICT[(a_value, b_value)].get_choice()
                designate = detail_set.get_designate(choice)

                # Set the current tile to the closest point type
                world_data.detail[x, y] = designate


"""
~~~~~~~~~~~~~~~~~~~~~~
DISTRIBUTION CONSTANTS
~~~~~~~~~~~~~~~~~~~~~~
"""

PD_PURE_MIX = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.0625),
        (DetailKey.GRASS_PLANT_B, 0.0625),
        (DetailKey.GRASS_PLANT_C, 0.0625),
        (DetailKey.GRASS_TEXTURE_A, 0.0625),
        (DetailKey.GRASS_TEXTURE_B, 0.0625),
        (DetailKey.GRASS_TEXTURE_C, 0.0625),
        (DetailKey.GRASS_TEXTURE_D, 0.0625),
        (DetailKey.GRASS_LOG_A, 0.0625),
        (DetailKey.GRASS_LOG_B, 0.0625),
        (DetailKey.GRASS_ROCK_A, 0.0625),
        (DetailKey.GRASS_ROCK_B, 0.0625),
        (DetailKey.GRASS_FLOWER_A, 0.0625),
        (DetailKey.GRASS_FLOWER_B, 0.0625),
        (DetailKey.GRASS_FLOWER_C, 0.0625),
        (DetailKey.GRASS_FLOWER_D, 0.0625),
        (DetailKey.GRASS_FLOWER_E, 0.0625),
    )
)

PD_PLANT_MIX = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.083),
        (DetailKey.GRASS_PLANT_B, 0.083),
        (DetailKey.GRASS_PLANT_C, 0.083),
        (DetailKey.GRASS_TEXTURE_A, 0.083),
        (DetailKey.GRASS_TEXTURE_B, 0.083),
        (DetailKey.GRASS_TEXTURE_C, 0.083),
        (DetailKey.GRASS_TEXTURE_D, 0.083),
        (DetailKey.GRASS_FLOWER_A, 0.087),
        (DetailKey.GRASS_FLOWER_B, 0.083),
        (DetailKey.GRASS_FLOWER_C, 0.083),
        (DetailKey.GRASS_FLOWER_D, 0.083),
        (DetailKey.GRASS_FLOWER_E, 0.083),
    )
)

PD_FLOWER_FIELD = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_FLOWER_A, 0.2),
        (DetailKey.GRASS_FLOWER_B, 0.2),
        (DetailKey.GRASS_FLOWER_C, 0.2),
        (DetailKey.GRASS_FLOWER_D, 0.2),
        (DetailKey.GRASS_FLOWER_E, 0.2),
    )
)

PD_GRASS_TEXTURE = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_TEXTURE_A, 0.25),
        (DetailKey.GRASS_TEXTURE_B, 0.25),
        (DetailKey.GRASS_TEXTURE_C, 0.25),
        (DetailKey.GRASS_TEXTURE_D, 0.25),
    )
)

PD_FELLED_WOOD = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.1),
        (DetailKey.GRASS_PLANT_B, 0.1),
        (DetailKey.GRASS_PLANT_C, 0.1),
        (DetailKey.GRASS_LOG_A, 0.25),
        (DetailKey.GRASS_LOG_B, 0.25),
        (DetailKey.GRASS_ROCK_A, 0.1),
        (DetailKey.GRASS_ROCK_B, 0.1),
    )
)

PD_GREEN_MIX = PerlinDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.1429),
        (DetailKey.GRASS_PLANT_B, 0.1429),
        (DetailKey.GRASS_PLANT_C, 0.1429),
        (DetailKey.GRASS_TEXTURE_A, 0.1429),
        (DetailKey.GRASS_TEXTURE_B, 0.1429),
        (DetailKey.GRASS_TEXTURE_C, 0.1426),
        (DetailKey.GRASS_TEXTURE_D, 0.1429),
    )
)

DISTRO_DICT = {
    (0, 0): PD_PURE_MIX, 
    (1, 0): PD_PLANT_MIX, 
    (2, 0): PD_FELLED_WOOD,

    (0, 1): PD_GRASS_TEXTURE, 
    (1, 1): PD_FLOWER_FIELD, 
    (2, 1): PD_GREEN_MIX,

    (0, 2): PD_PURE_MIX, 
    (1, 2): PD_PURE_MIX, 
    (2, 2): PD_PURE_MIX  
}