import pyglet
import enum

from . import terrain_primary

# How many tiles is river_dir.png, left to right?
IMAGE_TILE_WIDTH = 3

# How many tiles is river_dir.png, top to bottom?
IMAGE_TILE_HEIGHT = 3

IMAGE_PATH = "river_dir.png"

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

    return image, grid, [RiverDirKey], IMAGE_PATH

class RiverDirKey(terrain_primary.PrimaryTileEnum):
    """
    The ImageGrid indices for each item in the Terrain Primary Tile set. The
    primary tileset provides the primary version for each terrain type that we
    then layer over with detail tiles.
    """
    EAST = 0, False, False
    NORTH_EAST = 1, False, False
    NORTH = 2, False, False
    NORTH_WEST = 3, False, False
    WEST = 4, False, False
    SOUTH_WEST = 5, False, False
    SOUTH = 6, False, False
    SOUTH_EAST = 7, False, False
    
    NO_FLOW = 8, False, False

    @property
    def proxy(self):
        return terrain_primary.PrimaryKey.WATER

    @property
    def precedence(self):
        return self.proxy.precedence

    @property
    def image_path(self):
        return IMAGE_PATH
