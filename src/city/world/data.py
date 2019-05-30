import multiprocessing as mp
import numpy
import enum

# Only need these two items from ctypes, and they come with prefixes
from ctypes import c_bool, c_byte, c_int16, Structure

# In order to save time on rendering tiles, we divide the map up into squares.
# We then assign each square the most common terrain tile type there-in.
# These squares are of size AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN.
# The world sizes MUST be divisible by AVERAGE_ZONE_LEN!
AVERAGE_ZONE_LEN = 10

class WorldLayer(object):
    """
    Represents a single layer of tiles. More or less acts as a wrapper for the
    multiprocessing Array that it holds. Kind of pointless by itself, but we'll
    use this to build other classes off of.
    """
    def __init__(self, x_len, y_len, item_type):
        super(WorldLayer, self).__init__()
        self.array = mp.Array(item_type, x_len * y_len)
        self.x_len = x_len
        self.y_len = y_len

        # The "C Types" type of the array. We need this to create both the
        # array & the numpy_array.
        self.item_type = item_type

        # Numpy arrays seem to be quicker process-wise to read & write, so
        # we'll use this for read-writing
        a = numpy.frombuffer( self.array.get_obj(), dtype=self.item_type )
        self.numpy_array = a.reshape( (self.x_len, self.y_len) )

    @property
    def sizes(self):
        return (self.x_len, self.y_len)

    def in_bounds(self, key):
        x, y = key
        return 0 <= x < self.x_len and 0 <= y < self.y_len

    def __getitem__(self, key):
        return self.numpy_array[key]

    def __setitem__(self, key, value):
        self.numpy_array[key] = value

class WorldData(object):
    """
    Collates all of our world layers together into one fat class.
    """
    def __init__(self, x_len, y_len):
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
        self.base = WorldLayer(self._x_len, self._y_len, c_byte)

        # In order to save time on rendering tiles, we divide the map up into
        # squares. We then assign each square the most common terrain tile type
        # there-in.
        # AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN Tiles
        x_avg_len = self._x_len // AVERAGE_ZONE_LEN
        y_avg_len = self._y_len // AVERAGE_ZONE_LEN

        self.avg_size_x = AVERAGE_ZONE_LEN
        self.avg_size_y = AVERAGE_ZONE_LEN

        # The average tile for each "section" - an AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN
        # space that we use to help speed up our render processing.
        self.base_average = WorldLayer(x_avg_len, y_avg_len, c_byte)

        # The miscellaneous details that cover our terrain.
        # This can be terrain transitions, or it can be other details (like
        # flowers, or something).
        # Each terrain tile gets 4 tiles : NW, NE, SW, and SE.
        # Ergo, 16 x 16 Tiles
        self.detail = WorldLayer(self._x_len * 2, self._y_len * 2, c_int16)

        # The structures that go over our terrain. We track them separately so
        # we can more easily see information SPECIFICALLY about structures.
        # 32 x 32 Tiles.
        self.struct = WorldLayer(self._x_len, self._y_len, c_byte)

    @property
    def sizes(self):
        return (self._x_len, self._y_len)
