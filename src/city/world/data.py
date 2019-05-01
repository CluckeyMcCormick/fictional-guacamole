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
        self.item_type = item_type

    @property
    def sizes(self):
        return (self.x_len, self.y_len)

    def __getitem__(self, key):
        x, y = key
        
        if not (0 <= x < self.x_len and 0 <= y < self.y_len):
            raise Exception(
                "Invalid WorldLayer index: ({0},{1}) vs. [{2}, {3}]".format(
                    x, y, self.x_len, self.y_len
                )
            )

        return self.array[ (y * self.x_len) + x ]

    def __setitem__(self, key, value):

        if isinstance(self.item_type, Structure):
            raise Exception("Cannot set Structure type of {0} to {1}!".format(self.item_type, value))

        x, y = key
        
        if not (0 <= x < self.x_len and 0 <= y < self.y_len):
            raise Exception(
                "Invalid WorldLayer index: ({0},{1}) vs. [{2}, {3}]".format(
                    x, y, self.x_len, self.y_len
                )
            )

        self.array[ (y * self.x_len) + x ] = value

    def in_bounds(self, key):
        x, y = key
        return 0 <= x < self.x_len and 0 <= y < self.y_len

class AveragedWorldLayer(WorldLayer):
    """
    Represents a world layer that notes changes made to itself in the provided
    "Average" world layer. Neat!
    """
    def __init__(self, x_len, y_len, item_type, average_layer, avg_factors):
        super(AveragedWorldLayer, self).__init__(x_len, y_len, item_type)
        self.avg_x_len, self.avg_y_len = average_layer.sizes
        self.average_layer = average_layer
        self.avg_x_factor, self.avg_y_factor = avg_factors

    def __setitem__(self, key, value):
        x, y = key
        
        if not (0 <= x < self.x_len and 0 <= y < self.y_len):
            raise Exception(
                "Invalid WorldLayer index: ({0},{1}) vs. [{2}, {3}]".format(
                    x, y, self.x_len, self.y_len
                )
            )

        old_val = self.array[ (y * self.x_len) + x ]
        self.array[ (y * self.x_len) + x ] = value

        # If the value changed...
        if old_val != value:
            # Figure out where our average is
            x, y = key
            avg_x = x // self.avg_x_factor
            avg_y = y // self.avg_y_factor

            avg_index = (y // self.avg_y_factor) * self.avg_x_len + (x // self.avg_x_factor)

            # Update the new value
            self.average_layer.array[avg_index].counts[value] += 1

            # Get rid of the old value. Minimum possible value is 0.
            self.average_layer.array[avg_index].counts[old_val] = max(self.average_layer.array[avg_index].counts[old_val] - 1, 0)

class WorldData(object):
    """
    Collates all of our world layers together into one fat class.
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

        self.primary_types = len(primary_ts)

        # In order to save time on rendering tiles, we divide the map up into
        # squares. We then assign each square the most common terrain tile type
        # there-in.
        # AVERAGE_ZONE_LEN x AVERAGE_ZONE_LEN Tiles
        x_avg_len = self._x_len // AVERAGE_ZONE_LEN
        y_avg_len = self._y_len // AVERAGE_ZONE_LEN

        # Okay, here's some Pythonic black magic for you - we're going to
        # create an "AVERAGE_CHUNK" struct on the fly to hold information on our
        # average chunks.
        # We need to build this on the fly because the size changes based on 
        # the length of primary_ts.
        class AVERAGE_CHUNK(Structure):
            _fields_ = [
                ('avg', c_byte),
                ('counts', c_byte * self.primary_types)
            ]

        avg_factors = (AVERAGE_ZONE_LEN, AVERAGE_ZONE_LEN)

        self.base_average = WorldLayer(x_avg_len, y_avg_len, AVERAGE_CHUNK)

        # The terrain of the map.
        # Grass, Sand, Dirt, Stone, Water, Snow. All that stuff. 
        # 32 x 32 Tiles
        self.base = AveragedWorldLayer(self._x_len, self._y_len, c_byte, self.base_average, avg_factors)

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

