import pyglet
import enum

from ..tile_set import TileEnum

class PrimaryTileEnum(TileEnum):
    def __new__(cls, index, is_animation, has_edge):
        obj = object.__new__(cls)
        # Assign an aribitrary value for value
        obj._value_ = len(cls.__members__)
        obj._is_animation_ = is_animation
        obj._index_ = index
        obj._has_edge_ = has_edge
        return obj

    @property
    def has_edge(self):
        # Hide the has_edge value behind a property
        return self._has_edge_

    @property
    def proxy(self):
        """
        Occassionally, it may be desirable, for whatever reason, for a primary
        tile to appear as another tile. For example, we would want river water
        to appear to some portions of the program as just water. The proxy
        property is what we'll access for when this deferrment occurs.
        """
        return self # For the base class, just return this object

    @property
    def precedence(self):
        """
        When we're drawing up edge tiles, we need to know the precedence score
        of each tile so we can determine which tiles cover what. A lower score
        is considered to have more precedence.
        """
        # Return the assigned value.
        # Note that, since the "value" field is automatically determined with 0
        # being the first enum defined, the order of Enums is very important!
        return self.value

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

class PrimaryKey(PrimaryTileEnum):
    """
    The ImageGrid indices for each item in the Terrain Primary Tile set. The
    primary tileset provides the primary version for each terrain type that we
    then layer over with detail tiles.
    """
    SNOW =  0, False, False
    GRASS =  1, False, False
    DIRT =  2, False, False
    SAND =  3, False, False
    STONE =  4, False, False
    ICE =  5, False, False
    WATER =  6, False, True # Water doesn't have edges
    LOW_STONE =  7, False, False

    @property
    def image_path(self):
        return IMAGE_PATH
