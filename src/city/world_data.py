import multiprocessing as mp
import numpy

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte


# In order to save time on rendering tiles, we divide the map up into squares.
# We then assign each square the most common terrain tile type there-in.
# These squares are of size AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN.
# The world sizes MUST be divisible by AVERAGE_ZONE_LEN!
AVERAGE_ZONE_LEN = 10

class WorldData(object):
    """docstring for WorldData"""
    def __init__(self, x_len, y_len):
        super(WorldData, self).__init__()

        if (x_len < 0 or y_len < 0):
            raise ValueError("World length not be negative - x:[%d] y[%d]".format(x_len, y_len))

        if (x_len % AVERAGE_ZONE_LEN != 0 or y_len % AVERAGE_ZONE_LEN != 0):
            raise ValueError("World length must be divisible by %d - x:[%d] y[%d]".format(AVERAGE_ZONE_LEN, x_len, y_len))

        self._x_len = x_len
        self._y_len = y_len

        # The terrain of the map.
        # Grass, Sand, Dirt, Stone, Water, Snow. All that stuff. 
        # 32 x 32 Tiles
        self.terrain_raw = mp.Array(c_byte, x_len * y_len)

        # The miscellaneous details that cover our terrain.
        # This can be terrain transitions, or it can be other details (like
        # flowers, or something).
        # Each terrain tile gets 4 tiles : NW, NE, SW, and SE.
        # Ergo, 16 x 16 Tiles
        self.detail_raw = mp.Array(c_byte, (x_len * 2) * (y_len * 2))

        # The structures that go over our terrain. We track them separately so
        # we can more easily see information SPECIFICALLY about structures.
        # 32 x 32 Tiles.
        self.struct_raw = mp.Array(c_byte, x_len * y_len )

        # In order to save time on rendering tiles, we divide the map up into
        # squares. We then assign each square the most common terrain tile type
        # there-in.
        # AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN Tiles
        x_avg_len = x_len // AVERAGE_ZONE_LEN
        y_avg_len = y_len // AVERAGE_ZONE_LEN
        self.average_raw = mp.Array(c_byte, x_avg_len * y_avg_len )

        # Convert all those raw worlds into shaped/usable worlds
        a = numpy.frombuffer( self.terrain_raw.get_obj(), dtype=c_byte )
        self.terrain_shaped = a.reshape( (x_len, y_len) )

        a = numpy.frombuffer( self.detail_raw.get_obj(), dtype=c_byte )
        self.detail_shaped = a.reshape( (x_len * 2, y_len * 2) )

        a = numpy.frombuffer( self.struct_raw.get_obj(), dtype=c_byte )
        self.struct_shaped = a.reshape( (x_len, y_len) )

        a = numpy.frombuffer( self.average_raw.get_obj(), dtype=c_byte )
        self.average_shaped = a.reshape( (x_avg_len, y_avg_len) )

