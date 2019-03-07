import multiprocessing as mp
import numpy

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_byte, c_int16

# In order to save time on rendering tiles, we divide the map up into squares.
# We then assign each square the most common terrain tile type there-in.
# These squares are of size AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN.
# The world sizes MUST be divisible by AVERAGE_ZONE_LEN!
AVERAGE_ZONE_LEN = 10

class WorldData(object):
    """
    docstring for WorldData
    """
    def __init__(self, x_len, y_len, primary_ts):
        super(WorldData, self).__init__()

        if x_len is None or y_len is None:
            raise ValueError("Handed inconsistent values! x:[%s] y:[%s]".format( str(x_len), str(y_len) ) )

        if x_len < 0 or y_len < 0:
            raise ValueError("World length not be negative - x:[%d] y[%d]".format(x_len, y_len))

        if x_len % AVERAGE_ZONE_LEN != 0 or y_len % AVERAGE_ZONE_LEN != 0:
            raise ValueError("World length must be divisible by %d - x:[%d] y[%d]".format(AVERAGE_ZONE_LEN, x_len, y_len))

        self._x_len = x_len
        self._y_len = y_len

        # The terrain of the map.
        # Grass, Sand, Dirt, Stone, Water, Snow. All that stuff. 
        # 32 x 32 Tiles
        self.terrain_raw = mp.Array(c_byte, self._x_len * self._y_len)

        # The miscellaneous details that cover our terrain.
        # This can be terrain transitions, or it can be other details (like
        # flowers, or something).
        # Each terrain tile gets 4 tiles : NW, NE, SW, and SE.
        # Ergo, 16 x 16 Tiles
        self.detail_raw = mp.Array(c_int16, (self._x_len * 2) * (self._y_len * 2))

        # The structures that go over our terrain. We track them separately so
        # we can more easily see information SPECIFICALLY about structures.
        # 32 x 32 Tiles.
        self.struct_raw = mp.Array(c_byte, self._x_len * self._y_len )

        self.primary_types = len(primary_ts)

        # In order to save time on rendering tiles, we divide the map up into
        # squares. We then assign each square the most common terrain tile type
        # there-in.
        # AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN Tiles
        x_avg_len = self._x_len // AVERAGE_ZONE_LEN
        y_avg_len = self._y_len // AVERAGE_ZONE_LEN
        self.average_raw = mp.Array(c_byte, x_avg_len * y_avg_len)
        self.counts_raw = mp.Array(c_byte, x_avg_len * y_avg_len * self.primary_types)

        self.terrain_shaped = self.make_terrain_shaped()
        self.detail_shaped = self.make_detail_shaped()
        self.struct_shaped = self.make_struct_shaped()
        self.average_shaped = self.make_average_shaped()
        self.counts_shaped = self.make_counts_shaped()

    def get_sizes(self):
        return (self._x_len, self._y_len)

    def make_terrain_shaped(self):
        a = numpy.frombuffer( self.terrain_raw.get_obj(), dtype=c_byte )
        return a.reshape( (self._x_len, self._y_len) )

    def make_detail_shaped(self):
        a = numpy.frombuffer( self.detail_raw.get_obj(), dtype=c_int16 )
        return a.reshape( (self._x_len * 2, self._y_len * 2) )

    def make_struct_shaped(self):
        a = numpy.frombuffer( self.struct_raw.get_obj(), dtype=c_byte )
        return a.reshape( (self._x_len, self._y_len) )

    def make_average_shaped(self):
        x_avg_len = self._x_len // AVERAGE_ZONE_LEN
        y_avg_len = self._y_len // AVERAGE_ZONE_LEN
        a = numpy.frombuffer( self.average_raw.get_obj(), dtype=c_byte )
        return a.reshape( (x_avg_len, y_avg_len) )

    def make_counts_shaped(self):
        x_avg_len = self._x_len // AVERAGE_ZONE_LEN
        y_avg_len = self._y_len // AVERAGE_ZONE_LEN
        a = numpy.frombuffer( self.counts_raw.get_obj(), dtype=c_byte )
        return a.reshape( (x_avg_len, y_avg_len, self.primary_types) )

