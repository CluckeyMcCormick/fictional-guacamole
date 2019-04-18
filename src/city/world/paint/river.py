
import fractions
import random
import enum
import math

import noise

from ..assets.terrain_primary import PrimaryKey
from game_util.bresenham import func_line, func_circle

import game_util

class RiverFlow(enum.IntEnum):
    """
    Describes the flow direction of a particular river segment; used for the
    semantics of river flow.
    """
    EAST = 0
    NORTH_EAST = 1
    NORTH = 2
    NORTH_WEST = 3
    WEST = 4
    SOUTH_WEST = 5
    SOUTH = 6
    SOUTH_EAST = 7

"""
The flow_shifts dict contains flow_shifts tuples, which describe the
flow_shifts on x and y that match a particular flow. For example, if we have a
river flowing east, we want to move in an easterly direction. We would index
this dictionary with RiverFlow.EAST and get (1, 0). Thus, we can calculate due
east with x + 1, y + 0.

Also, this had to be defined outside of it's class because OTHERWISE it would
become an enum itself and be useless.
"""
flow_shifts = {
    RiverFlow.EAST: (1, 0),
    RiverFlow.NORTH: (0, 1),
    RiverFlow.WEST: (-1, 0),
    RiverFlow.SOUTH: (0, -1),
    RiverFlow.NORTH_EAST: ( 1, 1),
    RiverFlow.NORTH_WEST: (-1, 1),   
    RiverFlow.SOUTH_WEST: (-1,-1),
    RiverFlow.SOUTH_EAST: ( 1,-1)
}

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

        flow: a RiverFlow enum that describes the flow of the water in this
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
                lp = LatticePoint( self.DEFAULT_RIVER_SIZE, None, (x, y) )

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

    def __getitem__(self, key):
        x, y = key
        return self.lattice[x][y]

class LatticePoint(object):
    """
    A point in our river lattice. Gives the river a vector to follow to the
    next point.
    """
    def __init__(self, size, flow, real_pos):
        super(LatticePoint, self).__init__()
        self.size = size
        self.flow = flow
        # The "real grid" position of this point
        self.real_pos = real_pos
        # The next point on the lattic grid
        self.next_pos = None

    def to_segments(self, to_real_pos):
        segments = []

        args = [ self.flow, self.size, segments ]

        func_line( self.real_pos, to_real_pos, create_river_segs, args )

        return segments

# Helper function for creating river segments on a specific x, y
# Meant to be used in conjunction with the Bresenham line function
def create_river_segs(x, y, flow, size, segments):
    seg = RiverSegment( (x, y), flow, size)

    segments.append(seg)

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
                old_flow = 0
            # Otherwise...
            else:
                # Just check forward, right, and left (in that order).
                flow_range = [0, -1, 1]
        
            # Evaluate the surrounding lattice points, choose the one with the
            # lowest score
            low_val = math.inf
            for turn in flow_range:
                # Calculate our new flow value
                adj_flow = (old_flow + turn) % len(RiverFlow)

                # Unpack our adjustments for our current flow direction
                new_x = lat_x + flow_shifts[adj_flow][0] # First in tuple is X
                new_y = lat_y + flow_shifts[adj_flow][1] # Second in tuple is Y

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
                    curr_lp.flow = adj_flow
                    curr_lp.next_pos = (new_x, new_y)

            # Update the old flow
            old_flow = curr_lp.flow

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
    ~ Step 5: Now that we have a heap of LatticePoints, generate these into
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
        args = [world_data, tile_set]
        # Paint a circle on top of this segment
        func_circle( segment.pos, segment.size, fill_water, args=args, fill=True)

# Helper function for painting a river segment 
# Meant to be used in conjunction with the Bresenham circle function
def fill_water(x, y, world_data, tile_set):
    # Get the size
    x_size, y_size = world_data.base.sizes

    # If we're in the world
    if (0 <= x < x_size) and (0 <= y < y_size):
        # Get the enum's integer designation
        designate = tile_set.get_designate(PrimaryKey.WATER)
        # Set the tile
        world_data.base[x, y] = designate
