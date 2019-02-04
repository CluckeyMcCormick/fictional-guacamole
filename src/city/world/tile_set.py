import pylget
import enum

class TerrainPrimaryKey(enum.Enum):
    """
	The indices for each item in the Terrain Primary Tile set. The primary
	tileset provides the primary version for each terrain type that we then
	layer over with detail tiles.
    """
    SNOW = 0
    GRASS = 1
    DIRT = 2
    SAND = 3
    STONE = 4
    ICE = 5
    WATER = 6
    LOW_STONE = 7

def load_tileset():
	pass