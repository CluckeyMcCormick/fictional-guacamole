
import random
import enum
import math

import noise

from ..assets.terrain_primary import PrimaryKey
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

class RiverOrient(enum.Enum):
    """
    Describes the overall orientation of the river; independent from the
    direction of the water's flow.
    """
    # A Left<->Right (West<->East) configuration
    HORIZONTAL = 0

    # A Positive Slope, Lower Left<->Upper Right (South West<->North East)
    POS_SLOPE = 1
    
    # A Up<->Down (North<->South) configuration
    VERTICAL = 2
    
    # A Negative Slope, Upper Left<->Lower Right (North West<->South East)
    NEG_SLOPE = 3

class RiverSegment(object):
    """
    Describes a segment of a river, where each segment is a 1-thick slice of a
    river along it's width.
    """
    def __init__(self, pos, orient, flow, size):
        """
        Creates a segment of a river.

        Inputs:

        pos: a (x, y) tuple that specifies the semantic center of the river

        orient: a RiverOrient enum that specfies how the river is oriented

        flow: a RiverFlow enum that describes the flow of the water in this
        segment

        size: the size/width of the river
        """
        super(RiverSegment, self).__init__()
        self.pos = pos
        self.orient = orient
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
    DEFAULT_RIVER_SIZE = 3
    
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
                if (0 <= x < len(x_range)) and (0 <= y < len(y_range)):
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
            # Get our points
            x1, y1 = self[ lp_pos ].real_pos
            x2, y2 = self[ lp.next_pos ].real_pos

            # Get our x distance
            x_dist = x2 - x1

            # If our x_dist is 0, then we have a vertical line. Our slope range
            # needs to be be different
            if x_dist == 0:
                slope = None
                slope_range = range(0, y2 - y1, round(math.copysign(1, y2 - y1)) )

            # Otherwise, we can make a normal slope
            else:
                slope = (y2 - y1) / (x_dist)
                slope_range = range(0, x_dist, round(math.copysign(1, x_dist)) )

            # For each point between here and the next lattice point...
            for shift in slope_range:
                # Create an empty segment object. We'll edit this as we go.
                seg = RiverSegment(None, None, None, None)

                # If we lack a slope, just set the position up or down
                if slope is None:
                    seg.pos = (x1, y1 + shift)

                # Otherwise, calculate the y_shift and set the position
                else:
                    # Calculate our y_shift
                    y_shift = round(slope * shift)
                    seg.pos = (x1 + shift, y1 + y_shift)

                if not (0 <= seg.pos[0] < self.REAL_X_SIZE and 0 <= seg.pos[1] < self.REAL_Y_SIZE):
                    continue

                # Set the flow and the size.
                seg.flow = lp.flow
                seg.size = lp.size

                # If the slope is between -1 and 1,
                if slope is not None and -1 <= slope <= 1:
                    # The orientation is horizontal
                    seg.orient = RiverOrient.HORIZONTAL
                # Otherwise...
                else:
                    # The orientation is vertical
                    seg.orient = RiverOrient.VERTICAL

                segments.append(seg)

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
        #
        self.next_pos = None

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

        
def make_river(world_data, start, generators):
    """
    Generates a river object. 

    For generating a river, we add together the values produced by the provided
    generators. This is interpreted as a heightmap; the river is generated by
    using this heightmap as a watershed. That means that the provided
    generators need to provide some form of direction to the river or things
    could go badly - infinite loop badly.

    Inputs:

    world_data: The WorldData object we will be working on

    start: a (x, y) tuple that specifies the start/source/headwaters of the
    river

    generators: a List of Generator objects

    """
    X_SIZE, Y_SIZE = world_data.sizes

    # Initialize our values: we are at the start, in the map, with no flow
    cur_x, cur_y = start
    in_map = True
    old_flow = None

    river = []

    # While we haven't gone off the map...
    while in_map:

        flow = None
        low_val = math.inf

        # If we don't have a flow...
        if old_flow is None:
            # Then check every direction!
            flow_range = range(0, len(RiverFlow))
            old_flow = 0
        # Otherwise...
        else:
            # Just check the left, forward, and right
            flow_range = range(-1, 2)

        """
        Step 1: Determine which tile to flow into.
        """
        for turn in flow_range:
            # Calculate our new flow value
            adj_flow = (old_flow + turn) % len(RiverFlow)

            # unpack our adjustments for our current flow direction
            adj_x, adj_y = flow_shifts[ adj_flow ]

            # calculate the new X and Y
            new_x = cur_x + adj_x
            new_y = cur_y + adj_y

            # Sum up this value across all the provided generators
            value = 0
            for gen in generators:
                value += gen.get_value(new_x, new_y)

            # If this is currently the lowest value, then update our tracking
            if value < low_val:
                low_val = value
                flow = adj_flow

        """
        Step 2: Create a segment, place it on the stack.
        """
        segment = RiverSegment( 
            (cur_x, cur_y), RiverOrient.HORIZONTAL, RiverFlow(flow), 3
        )
        river.append(segment)

        """
        Step 3: Move to the new tile.
        """ 
        # unpack our adjustments for our new flow direction
        adj_x, adj_y = flow_shifts[ flow ]

        # Adjust the X and Y
        cur_x += adj_x
        cur_y += adj_y

        # Update the old flow
        old_flow = flow

        """
        Step 4: Check if you're still in bounds.
        """
        in_map = (0 <= cur_x < X_SIZE) and (0 <= cur_y < Y_SIZE)

    return river

def paint_river(world_data, tile_set, river):
    """
    Paints the provided river, end to end.
    """
    for segment in river:
        if segment.orient == RiverOrient.HORIZONTAL:
            paint_river_horizontal(world_data, tile_set, segment)

        if segment.orient == RiverOrient.VERTICAL:
            paint_river_vertical(world_data, tile_set, segment)


def paint_river_vertical(world_data, tile_set, segment):
    pos_x, pos_y = segment.pos
    x_size, _ = world_data.base.sizes

    water_designate = tile_set.get_designate(PrimaryKey.WATER)
    
    # For every tile...
    for i in range(segment.size):
        # Calculate the disposition - are we adding this on the left or right?
        # We alternate between painting on either side depending on whether
        # we're odd or even - and (conveniently), so does cosine!
        disposition =  math.cos( i * math.pi )

        # Calculate our distance from the "original" point
        new_x = pos_x + ((i + 1) // 2) * int(disposition)

        # If we're not in the limit, skip this tile
        if not (0 <= new_x < x_size):
            continue

        # Paint the tile
        world_data.base[new_x, pos_y] = water_designate

def paint_river_horizontal(world_data, tile_set, segment):
    pos_x, pos_y = segment.pos
    _, y_size = world_data.base.sizes

    water_designate = tile_set.get_designate(PrimaryKey.WATER)

    # For every tile...
    for i in range(segment.size):
        # Calculate the disposition - are we adding this on the top or bottom?
        # We alternate between painting on either side depending on whether
        # we're odd or even - and (conveniently), so does cosine!
        disposition =  math.cos( i * math.pi )

        # Calculate our distance from the "original" point
        new_y = pos_y + ((i + 1) // 2) * int(disposition)

        # If we're not in the limit, skip this tile
        if not (0 <= new_y < y_size):
            continue

        # Paint the tile
        world_data.base[pos_x, new_y] = water_designate
