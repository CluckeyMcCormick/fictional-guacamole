
import fractions
import random
import enum
import math

import noise

from ..assets.terrain_primary import PrimaryKey
from ..assets.river_dir import RiverDirKey
from game_util.bresenham import func_line, func_circle

import game_util

class ShiftEnum(enum.Enum):
    def __new__(cls, value, shift):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.shift = shift

        return obj

    def __sub__(self, other):
        # Get the class
        typed = type(self)
        # Return enum with that value
        return typed( (self.value - other) % len(typed.__members__) ) 

    def __add__(self, other):
        # Get the class
        typed = type(self)
        # Return enum with that value
        # Return enum with that value
        return typed( (self.value + other) % len(typed.__members__) )

class RiverFlow(ShiftEnum):
    """
    Describes the flow direction of a particular river segment; used for the
    semantics of river flow.
    """
    EAST  = 0, ( 1, 0)
    NORTH = 2, ( 0, 1)
    WEST  = 4, (-1, 0)
    SOUTH = 6, (0, -1)

    NORTH_EAST = 1, ( 1, 1)
    NORTH_WEST = 3, (-1, 1)
    SOUTH_WEST = 5, (-1,-1)
    SOUTH_EAST = 7, ( 1,-1)

class RiverSegment(object):
    """
    Describes a segment of a river, where each segment is a 1-thick slice of a
    river along it's width.
    """
    def __init__(self, pos, flow, size):
        """
        Creates a segment of a river.

        Inputs:

        pos: a (x, y) tuple that specifies the semantic center of the river

        flow: a RiverDirKey enum that describes the flow of the water in this
        segment

        size: the size/width of the river
        """
        super(RiverSegment, self).__init__()
        self.pos = pos
        self.flow = flow
        self.size = size

class RiverLattice(object):
    """
    A tool for generating rivers. Presents a neat grid that's all nice for
    pathfinding, which can then produce RiverSegments for painting a nice,
    flowing river. 
    """
    # Have a river point every X steps
    POINT_STEP = 5
    
    # The standard deviation of a river point on both axes
    POINT_DEVIATION = 1.5

    # The default size/width of the river - in other words, the basic size.
    DEFAULT_RIVER_SIZE = 2
    
    def __init__(self, world_sizes):
        super(RiverLattice, self).__init__()
        # Unpack the world sizes
        self.REAL_X_SIZE, self.REAL_Y_SIZE = world_sizes
        # First, determine the size for each axis of the lattice.
        # We add +2 because we want out-of-bounds points around the margin
        x_range = range((self.REAL_X_SIZE // self.POINT_STEP) + 2)
        y_range = range((self.REAL_Y_SIZE // self.POINT_STEP) + 2)
        
        self.lattice = []

        # For each x...
        for lat_x in x_range:
            # Add another list
            self.lattice.append( [] )
            # For each y...
            for lat_y in y_range:
                # Generate the real river position. This formula means our
                # points will be from POINT_STEP to SIZE + POINT_STEP
                x = lat_x * self.POINT_STEP - self.POINT_STEP
                y = lat_y * self.POINT_STEP - self.POINT_STEP

                # If this point is in bounds, shift it around.
                if (0 <= x < self.REAL_X_SIZE) and (0 <= y < self.REAL_Y_SIZE):
                    x = round(random.gauss(x, self.POINT_DEVIATION))
                    y = round(random.gauss(y, self.POINT_DEVIATION))  

                # Create our LatticePoint object
                lp = LatticePoint( self.DEFAULT_RIVER_SIZE, (x, y) )

                # Stick our LatticePoint on the array.
                self.lattice[lat_x].append( lp )

        # What is the size of our lattice?
        self.X_SIZE = len( self.lattice )
        self.Y_SIZE = len( self.lattice[0] )
        
        # What points are active river points?
        self.active_points = {}

    def mark_point(self, point):
        """
        Marks the given point as being active, and updates it with the provided
        flow and next_point values.

        Returns True if a river was buffed, returns False otherwise. A river
        gets buffed if there is an active river lattice on point or next_point.
        """
        # If this point is already in active points, then buff the river
        if point in self.active_points:
            self.buff_river(point, self.DEFAULT_RIVER_SIZE)
            return True # Return True since we buffed the river

        lp = self.lattice[point[0]][point[1]]

        # Include this point in active points
        self.active_points[point] = lp

        # If the next point is in active points, then buff the river
        if lp.next_pos in self.active_points:
            self.buff_river(lp.next_pos, self.DEFAULT_RIVER_SIZE)
            return True # Return True since we buffed the river

        # Since we only make it here if we haven't buffed a river, return False
        return False

    def buff_river(self, start, add_size):
        lat_x, lat_y = start
        lp = self.lattice[lat_x][lat_y]

        # While we have a next position...
        while lp.next_pos is not None:
            # Increase the size
            lp.size += add_size

            # Move to the next point
            lat_x, lat_y = lp.next_pos
            lp = self.lattice[lat_x][lat_y]

    def to_segments(self):
        segments = []

        for lp_pos, lp in self.active_points.items():
            # Get our target point
            target = self[ lp.next_pos ].real_pos
            # Extend the segments list
            segments.extend( lp.to_segments( target ))

        return segments

    def in_bounds(self, pos):
        x, y = pos
        return 0 <= x < self.X_SIZE and 0 <= y < self.Y_SIZE

    def __getitem__(self, key):
        x, y = key
        return self.lattice[x][y]

class LatticePoint(object):
    """
    A point in our river lattice. Gives the river a vector to follow to the
    next point.
    """
    def __init__(self, size, real_pos):
        super(LatticePoint, self).__init__()
        self.size = size
        # The "real grid" position of this point
        self.real_pos = real_pos
        # The next point on the lattice grid
        self.next_pos = None
        # The direction the river flows on the lattice grid
        self.semantic_flow = None
        # The direction the river flows from real_pos to real_pos
        self.real_flow = RiverDirKey.NO_FLOW

    def to_segments(self, to_real_pos):
        # Create a list of segments, for storage
        segments = []

        # Go over a line, creating river segments.
        func_line( self.real_pos, to_real_pos, self._make_segment, [ segments ] )

        return segments

    # Helper function for creating river segments on a specific x, y
    # Meant to be used in conjunction with the Bresenham line function
    def _make_segment(self, x, y, segments):
        segments.append( RiverSegment( (x, y), self.real_flow, self.size) )

### CRED: MichaelHouse
### https://gamedev.stackexchange.com/questions/31263/road-river-generation-on-2d-grid-map
###
def generate_rivers(world_data, sources):

    BASE = 0

    scale = 100.0
    octaves = 6
    persistence = 0.5
    lacunarity = 2.0

    """
    ~
    ~ Step 1: Prepare a lattice of river points
    ~
    """
    river_lat = RiverLattice(world_data.sizes)

    """
    ~
    ~ Step 2: Create a point for the rivers to flow towards/exit from.
    ~
    """
    exit_choices = [
        (-1,               None),            # Left hand exit, random y
        (river_lat.X_SIZE, None),            # Right hand exit, random y
        (None,             -1),              # Bottom exit, random x
        (None,             river_lat.Y_SIZE) # Top exit, random x
    ]

    exit_x, exit_y = random.choice( exit_choices )

    # If we have None for x, we need to generate a random value
    if exit_x is None:
        exit_x = random.randint(-1, river_lat.X_SIZE)

    # If we have None for y, we need to generate a random value
    if exit_y is None:
        exit_y = random.randint(-1, river_lat.Y_SIZE)

    exit_x, exit_y = (-1, -1)

    """
    ~
    ~ Step 3: Now that the lattice is prepared and the random point is selected,
    ~         generate a river from each source.
    ~
    """

    for src_x, src_y in sources:
        print("NEXT_SRC", src_x, src_y)
        # Calculate the appropriate lattice point to start from
        lat_x = round(src_x / river_lat.POINT_STEP)
        lat_y = round(src_y / river_lat.POINT_STEP)

        # Get the current lp
        curr_lp = river_lat[lat_x, lat_y]

        # Modify the river lattice (at that point) to match the source
        curr_lp.real_pos = (src_x, src_y)

        # We can assume True since we're starting at a source and that MUST be
        # in the map.
        in_map = True
        # We don't start out with a predetermined flow direction
        old_flow = None

        # While we haven't gone out of bounds...
        while in_map:

            # Get the current distance to the exit
            curr_dist = game_util.tuple_distance((lat_x, lat_y), (exit_x, exit_y))

            # If we don't have a flow...
            if old_flow is None:
                # Then check every direction!
                flow_range = range(0, len(RiverFlow))
                old_flow = RiverFlow.EAST
            # Otherwise...
            else:
                # Just check forward, right, and left (in that order).
                flow_range = [0, -1, 1]
        
            # Evaluate the surrounding lattice points, choose the one with the
            # lowest score
            low_val = math.inf
            for turn in flow_range:
                # Calculate our new flow value
                adj_flow = old_flow + turn

                # Unpack our adjustments for our current flow direction
                new_x = lat_x + adj_flow.shift[0] # First in tuple is X
                new_y = lat_y + adj_flow.shift[1] # Second in tuple is Y

                # Sum up this value across all the provided generators
                value = noise.pnoise2(
                    new_x/scale, new_y/scale, 
                    octaves=octaves, persistence=persistence,
                    lacunarity=lacunarity, 
                    repeatx=river_lat.X_SIZE, repeaty=river_lat.Y_SIZE, 
                    base=BASE
                )

                # Get this point's distance from our exit point
                new_dist = game_util.tuple_distance( (new_x, new_y), (exit_x, exit_y))

                # If this point is farther from our goal than the current point...
                if new_dist > curr_dist:
                    # Add a stupidly big number so this doesn't get picked
                    value += 100 + new_dist - curr_dist

                # If this is currently the lowest value, then update our tracking
                if value < low_val:
                    low_val = value
                    curr_lp.semantic_flow = adj_flow 
                    curr_lp.next_pos = (new_x, new_y)

            # Update the old flow
            old_flow = curr_lp.semantic_flow

            # If we're in bounds, then update the flow base on the real pos,
            # using the slope and unit circle values
            if river_lat.in_bounds(curr_lp.next_pos):

                x_diff = river_lat[ curr_lp.next_pos ].real_pos[0] - curr_lp.real_pos[0]
                y_diff = river_lat[ curr_lp.next_pos ].real_pos[1] - curr_lp.real_pos[1]

                # If x_diff is 0...
                if x_diff == 0:
                    # Decide if the flow is North or South
                    if y_diff > 0:
                        curr_lp.real_flow = RiverDirKey.NORTH
                    elif y_diff < 0:
                        curr_lp.real_flow = RiverDirKey.SOUTH

                # Otherwise, if x_diff is less than 0...
                elif x_diff < 0:
                    # Calculate the slope
                    slope = fractions.Fraction(y_diff, x_diff)
                    # Calculate the angle of the slope in radians
                    rads = math.tan(slope)

                    """
                    if rads > math.tan( (11 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH
                    elif rads > math.tan( (9 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH_WEST
                    """
                    if rads > math.tan( (9 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH_WEST
                    elif rads > math.tan( (7 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.WEST
                    else:
                        curr_lp.real_flow = RiverDirKey.NORTH_WEST
                    """
                    elif rads > math.tan( (5 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.NORTH_WEST
                    else:
                        curr_lp.real_flow = RiverDirKey.NORTH
                    """
                # Otherwise, if x_diff is greater than 0 (which it MUST be)...
                elif x_diff > 0:
                    # Calculate the slope
                    slope = fractions.Fraction(y_diff, x_diff)
                    # Calculate the angle of the slope in radians
                    rads = math.tan(slope)
                    """
                    if rads < math.tan( (13 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH
                    elif rads < math.tan( (15 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH_EAST
                    """
                    if rads < math.tan( (15 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.SOUTH_EAST
                    elif rads < math.tan( (1 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.EAST
                    else:
                        curr_lp.real_flow = RiverDirKey.NORTH_EAST
                    """
                    elif rads < math.tan( (3 / 8) * math.pi ):
                        curr_lp.real_flow = RiverDirKey.NORTH_EAST
                    else:
                        curr_lp.real_flow = RiverDirKey.NORTH
                    """

            # If marking the current lattice point returns True, then we're done 
            if river_lat.mark_point( (lat_x, lat_y) ):
                in_map = False

            # Otherwise...
            else:
                # Update our current lattice x and y
                lat_x, lat_y = curr_lp.next_pos

                # Update our current lp in kind
                curr_lp = river_lat[lat_x, lat_y]

                # Check if you're still in bounds.
                in_map = (0 < lat_x < river_lat.X_SIZE - 1) and (0 < lat_y < river_lat.Y_SIZE - 1)
    """
    ~
    ~ Step 4: Now that we have a heap of LatticePoints, generate these into
    ~         a heap of RiverSegment objects.
    ~
    """
    return river_lat.to_segments()

def paint_river(world_data, tile_set, river):
    """
    Paints the provided river, end to end.
    """
    # For each segment that makes up a river...
    for segment in river:
        # Get our arguments together
        args = [world_data, tile_set, segment.flow]
        # Paint a circle on top of this segment
        func_circle( segment.pos, segment.size, fill_water, args=args, fill=True)

# Helper function for painting a river segment 
# Meant to be used in conjunction with the Bresenham circle function
def fill_water(x, y, world_data, tile_set, flow):
    # Get the size
    x_size, y_size = world_data.base.sizes

    # If we're in the world
    if (0 <= x < x_size) and (0 <= y < y_size):

        curr = tile_set.get_enum( world_data.base[x, y] )

        #if curr not in RiverDirKey:
        # Get the enum's integer designation
        designate = tile_set.get_designate(flow)
        # Set the tile
        world_data.base[x, y] = designate
