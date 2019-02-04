import enum

class EdgeKey(enum.Enum):
    """
    The indices for each edge in the Terrain Detail tile set. Since these are
    the same for each primary terrain type (unlike the rest of the detail set),
    we keep them separate.
    """
    LOWER_LEFT_INNER = (0, 8)
    BOTTOM_EDGE_A = (0, 9)
    BOTTOM_EDGE_B = (0, 10)
    LOWER_RIGHT_INNER = (0, 11)

    LEFT_EDGE_A = (1, 8)
    LOWER_LEFT_OUTER = (1, 9)
    LOWER_RIGHT_OUTER = (1, 10)
    RIGHT_EDGE_A = (1, 11)

    LEFT_EDGE_B = (2, 8)
    UPPER_LEFT_OUTER = (2, 9)
    UPPER_RIGHT_OUTER = (2, 10)
    RIGHT_EDGE_B = (2, 11)

    UPPER_LEFT_INNER = (3, 8)
    TOP_EDGE_A = (3, 9)
    TOP_EDGE_B = (3, 10)
    UPPER_RIGHT_INNER = (3, 11)

    def __init__(self, y, x):
        self.y = y
        self.x = x

    def get_adjusted(self, primary_key):
        return (self.y + (primary_key * 4), self.x)

class DetailKey(enum.Enum):
    """
    The indices for each item in the Terrain Primary Tile set. The primary
    tileset provides the primary version for each terrain type that we then
    layer over with detail tiles.
    """
    #
    # SNOW
    #
    SNOW_BUMP_A = (3, 2)
    SNOW_BUMP_B = (2, 2)
    SNOW_LOG_A = (1, 2)
    SNOW_LOG_B = (0, 2)
    SNOW_ROCK_A = (2, 3)
    SNOW_ROCK_B = (1, 3)

    #
    # GRASS
    #
    GRASS_PLANT_A = (4, 0)
    GRASS_PLANT_B = (4, 1)
    GRASS_PLANT_C = (4, 2)
    GRASS_TEXTURE_A = (5, 0)
    GRASS_TEXTURE_B = (5, 1)
    GRASS_TEXTURE_C = (6, 0)
    GRASS_TEXTURE_D = (6, 1)
    GRASS_LOG_A = (5, 2)
    GRASS_LOG_B = (6, 2)
    GRASS_ROCK_A = (5, 3)
    GRASS_ROCK_B = (6, 3)
    GRASS_FLOWER_A = (7, 0)
    GRASS_FLOWER_B = (7, 1)
    GRASS_FLOWER_C = (7, 2)
    GRASS_FLOWER_D = (7, 3)
    GRASS_FLOWER_E = (4, 3)

    #
    # DIRT
    #
    DIRT_BUMP_A = (8, 0)
    DIRT_BUMP_B = (8, 1)
    DIRT_TEXTURE_A = (9, 0)
    DIRT_TEXTURE_B = (9, 1)
    DIRT_TEXTURE_C = (10, 1)
    DIRT_TEXTURE_D = (9, 2)
    DIRT_PLANT_A = (10, 2)
    DIRT_ROCK_A = (9, 3)
    DIRT_ROCK_B = (10, 3)

    #
    # SAND
    #
    SAND_BUMP_A = (12, 0)
    SAND_BUMP_B = (12, 1)
    SAND_TEXTURE_A = (13, 0)
    SAND_TEXTURE_B = (13, 1)
    SAND_TEXTURE_C = (14, 1)
    SAND_TEXTURE_D = (13, 2)
    SAND_PLANT_A = (14, 2)
    SAND_ROCK_A = (13, 3)
    SAND_ROCK_B = (14, 3)

    #
    # STONE
    #
    STONE_TEXTURE_A = (17, 0)
    STONE_TEXTURE_B = (17, 1)
    STONE_TEXTURE_C = (18, 1)
    STONE_ROCK_A = (17, 3)
    STONE_ROCK_B = (18, 3)

    #
    # ICE
    # 
    ICE_SHINE = (23, 0)
    ICE_CRACK = (22, 0)

    #
    # WATER
    #     

    # Nothing here!

    #
    # LOW_STONE
    #
    LOW_STONE_TEXTURE_A = (29, 0)
    LOW_STONE_TEXTURE_B = (29, 1)
    LOW_STONE_TEXTURE_C = (30, 1)
    LOW_STONE_ROCK_A = (29, 3)
    LOW_STONE_ROCK_B = (30, 3)

