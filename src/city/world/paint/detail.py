"""
detail.py

Contains functions for spreading detail tiles around the world.
"""
import random
import numpy

from ..assets.terrain_detail import DetailKey

class VoroniDistro(object):
    """
    A distribution for a Voroni Point. Describes which detail tiles can appear
    in a Voroni polygon, and the probability weight for each tile.
    """
    def __init__(self, choice_weight_zip):
        super(VoroniDistro, self).__init__()
        self.choices, self.weights = zip(*choice_weight_zip)

    def get_choice(self):
        return numpy.random.choice(self.choices, 1, p=self.weights)

VD_PURE_MIX = VoroniDistro(
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

VD_PLANT_MIX = VoroniDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.083),
        (DetailKey.GRASS_PLANT_B, 0.083),
        (DetailKey.GRASS_PLANT_C, 0.083),
        (DetailKey.GRASS_TEXTURE_A, 0.083),
        (DetailKey.GRASS_TEXTURE_B, 0.083),
        (DetailKey.GRASS_TEXTURE_C, 0.083),
        (DetailKey.GRASS_TEXTURE_D, 0.083),
        (DetailKey.GRASS_FLOWER_A, 0.083),
        (DetailKey.GRASS_FLOWER_B, 0.083),
        (DetailKey.GRASS_FLOWER_C, 0.083),
        (DetailKey.GRASS_FLOWER_D, 0.083),
        (DetailKey.GRASS_FLOWER_E, 0.083),
    )
)

VD_FLOWER_FIELD = VoroniDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_FLOWER_A, 0.2),
        (DetailKey.GRASS_FLOWER_B, 0.2),
        (DetailKey.GRASS_FLOWER_C, 0.2),
        (DetailKey.GRASS_FLOWER_D, 0.2),
        (DetailKey.GRASS_FLOWER_E, 0.2),
    )
)

VD_GRASS_TEXTURE = VoroniDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_TEXTURE_A, 0.25),
        (DetailKey.GRASS_TEXTURE_B, 0.25),
        (DetailKey.GRASS_TEXTURE_C, 0.25),
        (DetailKey.GRASS_TEXTURE_D, 0.25),
    )
)

VD_FELLED_WOOD = VoroniDistro(
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

VD_GREEN_MIX = VoroniDistro(
    choice_weight_zip=(
        (DetailKey.GRASS_PLANT_A, 0.1429),
        (DetailKey.GRASS_PLANT_B, 0.1429),
        (DetailKey.GRASS_PLANT_C, 0.1429),
        (DetailKey.GRASS_TEXTURE_A, 0.1429),
        (DetailKey.GRASS_TEXTURE_B, 0.1429),
        (DetailKey.GRASS_TEXTURE_C, 0.1429),
        (DetailKey.GRASS_TEXTURE_D, 0.1429),
    )
)

VORONI_CHOICES = [
    VD_PURE_MIX, VD_PLANT_MIX, VD_FLOWER_FIELD,
    VD_GRASS_TEXTURE, VD_FELLED_WOOD, VD_GREEN_MIX
]

class VoroniPoint(object):
    """
    Describes a Voroni point, the center of a Voroni polygon. Provides the
    coordinates for the point and the distribution that describes what tiles to
    place.
    """
    def __init__(self, x, y, distro):
        super(VoroniPoint, self).__init__()
        self.x = x
        self.y = y
        self.distro = distro

    def distance(self, x, y):
        math.hypot( self.x - x, self.y - y )
        

def create_voroni_points(world_data):
    avg_x_size, avg_y_size = world_data.base_average.sizes

    voroni_list = [[None for _ in range(avg_y_size)] for _ in range(avg_x_size)]

    for avg_x in range(voroni_list):
        for avg_y in range(voroni_list[x]):
            distro = random.choice(VORONI_CHOICES)
            x = random.randrange(
                avg_x * world_data.avg_size_x, 
                (avg_x + 1) * world_data.avg_size_x
            )
            y = random.randrange(
                avg_y * world_data.avg_size_y, 
                (avg_y + 1) * world_data.avg_size_y
            )
            voroni_list[avg_x][avg_y] = VoroniPoint(x, y, distro)

