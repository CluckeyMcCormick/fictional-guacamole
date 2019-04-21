
import pyglet
import enum

from ..tile_set import TileEnum
from .terrain_primary import PrimaryKey

# terrain_detail.png is organized into squares. Currently, that's a detail
# square and an edge square. Each square is of N x N.
# IMAGE_SECTION_TILE_SIZE is N.
IMAGE_SECTION_TILE_SIZE = 4

# How many tiles is terrain_detail.png, left to right?
IMAGE_TILE_WIDTH = IMAGE_SECTION_TILE_SIZE * 2
# How many tiles is terrain_detail.png, top to bottom?
IMAGE_TILE_HEIGHT = IMAGE_SECTION_TILE_SIZE * 8

IMAGE_PATH = "terrain_detail.png"

def load():
    file = pyglet.resource.file(IMAGE_PATH)

    # Load the image using the specified file.
    # For some reason, loading using pyglet.resource.image creates a pixel
    # bleed when we break up the image into an ImageGrid - even if atlas=False
    # So we grab the file first
    image = pyglet.image.load(IMAGE_PATH, file=file)

    grid = pyglet.image.ImageGrid(
        image, rows=IMAGE_TILE_HEIGHT, columns=IMAGE_TILE_WIDTH,
    )

    return image, grid, [EdgeKey, DetailKey], IMAGE_PATH

class PrototypeEdgeKey(enum.Enum):
    """
    The indices for each edge in the Terrain Detail tile set. Since these are
    the same for each primary terrain type (unlike the rest of the detail set),
    we keep them separate.
    """
    LOWER_LEFT_INNER = (0, 4)
    BOTTOM_EDGE_A = (0, 5)
    BOTTOM_EDGE_B = (0, 6)
    LOWER_RIGHT_INNER = (0, 7)

    LEFT_EDGE_A = (1, 4)
    LOWER_LEFT_OUTER = (1, 5)
    LOWER_RIGHT_OUTER = (1, 6)
    RIGHT_EDGE_A = (1, 7)

    LEFT_EDGE_B = (2, 4)
    UPPER_LEFT_OUTER = (2, 5)
    UPPER_RIGHT_OUTER = (2, 6)
    RIGHT_EDGE_B = (2, 7)

    UPPER_LEFT_INNER = (3, 4)
    TOP_EDGE_A = (3, 5)
    TOP_EDGE_B = (3, 6)
    UPPER_RIGHT_INNER = (3, 7)

"""
Manually annotating each of the edge pieces would be annoying, as they're all
more or less duplicates (unlike the regular detail pieces). 

Our solution? Generate an enum on the fly!
"""

edge_key_dict = {}

# Iterate through of the primary terrain types
for prime_name, prime_mem in PrimaryKey.__members__.items():
    # Iterate through of the edge types
    for edge_name, edge_mem in PrototypeEdgeKey.__members__.items():
        # Create a new edge type by combining the primary name and edge name
        string = prime_name + "_" + edge_name
        y, x = edge_mem.value
        mult = prime_mem.value

        # Create the Enum entry
        edge_key_dict[string] = (y + (mult * IMAGE_SECTION_TILE_SIZE), x), False

"""
#
#   This enum is just like PrototypeEdgeKey, but with primary tile names appended
#   in front of the edge name.
#
"""
EdgeKey = TileEnum('EdgeKey', edge_key_dict)
# Redefine the image_path property
EdgeKey.image_path = property(lambda self: IMAGE_PATH )

class DetailKey(TileEnum):
    """
    The indices for each item in the Terrain Primary Tile set. The primary
    tileset provides the primary version for each terrain type that we then
    layer over with detail tiles.
    """
    # Special value - skips the current detail; doesn't render it.
    NONE = (-1, -1), False

    #
    # SNOW
    #
    SNOW_BUMP_A = (3, 2), False
    SNOW_BUMP_B = (2, 2), False
    SNOW_LOG_A = (1, 2), False
    SNOW_LOG_B = (0, 2), False
    SNOW_ROCK_A = (2, 3), False
    SNOW_ROCK_B = (1, 3), False

    #
    # GRASS
    #
    GRASS_PLANT_A = (4, 0), False
    GRASS_PLANT_B = (4, 1), False
    GRASS_PLANT_C = (4, 2), False
    GRASS_TEXTURE_A = (5, 0), False
    GRASS_TEXTURE_B = (5, 1), False
    GRASS_TEXTURE_C = (6, 0), False
    GRASS_TEXTURE_D = (6, 1), False
    GRASS_LOG_A = (5, 2), False
    GRASS_LOG_B = (6, 2), False
    GRASS_ROCK_A = (5, 3), False
    GRASS_ROCK_B = (6, 3), False
    GRASS_FLOWER_A = (7, 0), False
    GRASS_FLOWER_B = (7, 1), False
    GRASS_FLOWER_C = (7, 2), False
    GRASS_FLOWER_D = (7, 3), False
    GRASS_FLOWER_E = (4, 3), False

    #
    # DIRT
    #
    DIRT_BUMP_A = (8, 0), False
    DIRT_BUMP_B = (8, 1), False
    DIRT_TEXTURE_A = (9, 0), False
    DIRT_TEXTURE_B = (9, 1), False
    DIRT_TEXTURE_C = (10, 1), False
    DIRT_TEXTURE_D = (9, 2), False
    DIRT_PLANT_A = (10, 2), False
    DIRT_ROCK_A = (9, 3), False
    DIRT_ROCK_B = (10, 3), False

    #
    # SAND
    #
    SAND_BUMP_A = (12, 0), False
    SAND_BUMP_B = (12, 1), False
    SAND_TEXTURE_A = (13, 0), False
    SAND_TEXTURE_B = (13, 1), False
    SAND_TEXTURE_C = (14, 1), False
    SAND_TEXTURE_D = (13, 2), False
    SAND_PLANT_A = (14, 2), False
    SAND_ROCK_A = (13, 3), False
    SAND_ROCK_B = (14, 3), False

    #
    # STONE
    #
    STONE_TEXTURE_A = (17, 0), False
    STONE_TEXTURE_B = (17, 1), False
    STONE_TEXTURE_C = (18, 1), False
    STONE_ROCK_A = (17, 3), False
    STONE_ROCK_B = (18, 3), False

    #
    # ICE
    # 
    ICE_SHINE = (23, 0), False
    ICE_CRACK = (22, 0), False

    #
    # WATER
    #     

    # Nothing here!

    #
    # LOW_STONE
    #
    LOW_STONE_TEXTURE_A = (29, 0), False
    LOW_STONE_TEXTURE_B = (29, 1), False
    LOW_STONE_TEXTURE_C = (30, 1), False
    LOW_STONE_ROCK_A = (29, 3), False
    LOW_STONE_ROCK_B = (30, 3), False

    @property
    def image_path(self):
        return IMAGE_PATH
