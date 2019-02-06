import pyglet
import enum

# How many tiles is terrain_primary.png, left to right?
IMAGE_TILE_WIDTH = 1

# How many tiles is terrain_primary.png, top to bottom?
IMAGE_TILE_HEIGHT = 8

IMAGE_PATH = "terrain_primary.png"

def load():
    file = pyglet.resource.file(IMAGE_PATH)

    # Load the image using the specified file.
    # For some reason, loading using pyglet.resource.image creates a pixel
    # bleed when we break up the image into an ImageGrid - even if atlas=False
    # So we grab the file first
    image = pyglet.image.load(IMAGE_PATH, file=file)

    grid = pyglet.image.ImageGrid(
        image, rows=IMAGE_TILE_HEIGHT, columns=IMAGE_TILE_WIDTH
    )

    return image, grid, [PrimaryKey], IMAGE_PATH

class PrimaryKey(enum.Enum):
    """
    The ImageGrid indices for each item in the Terrain Primary Tile set. The
    primary tileset provides the primary version for each terrain type that we
    then layer over with detail tiles.
    """
    SNOW = 0
    GRASS = 1
    DIRT = 2
    SAND = 3
    STONE = 4
    ICE = 5
    WATER = 6
    LOW_STONE = 7

