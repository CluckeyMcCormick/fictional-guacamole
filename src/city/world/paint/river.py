
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

class LatticePoint(object):
    """
    A point in our river lattice. Gives the river a vector to follow to the
    next point.
    """
    def __init__(self, size, flow, next_lat_pos):
        super(LatticePoint, self).__init__()
        self.size = size
        self.flow = flow
        self.next_lat_pos = next_lat_pos

def generate_rivers(world_data, sources, generator):

    # Have a river point every X steps
    RIVER_POINT_STEP = 5
    # The standard deviation of a river point on both axes
    RIVER_POINT_DEVIATION = 1.5

    # The size of the world map
    X_SIZE, Y_SIZE = world_data.sizes

    """
    ~
    ~ Step 1: Prepare a lattice of river points
    ~
    """
    # First, determine the size for each axis of the lattice.
    # We add +2 because we want out-of-bounds points around the margin
    x_range = range((X_SIZE // RIVER_POINT_STEP) + 2)
    y_range = range((Y_SIZE // RIVER_POINT_STEP) + 2)

    # Build the river lattice, using our x_range and y_range
    river_lattice = [[ None for _ in x_range] for _ in y_range]

    """
    ~
    ~ Step 2: Walk through the river lattice, shifting the points randomly
    ~
    """
    # For each element in the lattice...
    for lat_x in range(len(river_lattice)):
        for lat_y in range(len(river_lattice[lat_x])):

            # Generate the basic river point. This formula means our points
            # will be from -RIVER_POINT_STEP to SIZE + RIVER_POINT_STEP
            x = lat_x * RIVER_POINT_STEP - RIVER_POINT_STEP
            y = lat_y * RIVER_POINT_STEP - RIVER_POINT_STEP

            # If this point is in bounds, shift it around.
            if (0 <= x < X_SIZE) and (0 <= y < Y_SIZE):
                x = round(random.gauss(x, RIVER_POINT_DEVIATION))
                y = round(random.gauss(y, RIVER_POINT_DEVIATION))  

            # Create the lattice point
            river_lattice[lat_x][lat_y] = (x, y)

    """
    ~
    ~ Step 3: Create a point for the rivers to flow towards/exit from.
    ~
    """
    exit_choices = [
        (-1, None),     # Left hand exit, random y
        (X_SIZE, None), # Right hand exit, random y
        (None, -1),     # Bottom exit, random x
        (None, Y_SIZE)  # Top exit, random x
    ]

    exit_x, exit_y = random.choice( exit_choices )

    # If we have None for x, we need to generate a random value
    if exit_x is None:
        exit_x = random.randint(-1, X_SIZE)

    # If we have None for y, we need to generate a random value
    if exit_y is None:
        exit_y = random.randint(-1, Y_SIZE)

    exit_x, exit_y = (-1, -1)

    """
    ~
    ~ Step 4: Now that the lattice is prepared and the random point is selected,
    ~         generate a river from each source.
    ~
    """
    # For noting which lattice points have been occupied by a river
    occupied_points = {}
    for src_x, src_y in sources:
        print("NEXT_SRC", src_x, src_y)
        # Calculate the appropriate lattice point to start from
        lat_x = round(src_x / RIVER_POINT_STEP)
        lat_y = round(src_y / RIVER_POINT_STEP)

        # Modify the river lattice (at that point) to match the source
        river_lattice[lat_x][lat_y] = (src_x, src_y)

        # We can assume True since we're starting at a source and that MUST be
        # in the map.
        in_map = True

        old_flow = None

        # While we haven't gone out of bounds...
        while in_map:

            low_val = math.inf

            # Create a lattice point for this... lattice point
            curr_lp = LatticePoint(3, None, None)

            # Add this lattice point to the set of visited points
            occupied_points[lat_x, lat_y] = curr_lp

            # Get the current xy point
            curr_xy = river_lattice[lat_x][lat_y]

            # Get the current distance to the exit
            curr_dist = game_util.tuple_distance(curr_xy, (exit_x, exit_y))

            # If we don't have a flow...
            if old_flow is None:
                # Then check every direction!
                flow_range = range(0, len(RiverFlow))
                old_flow = 0
            # Otherwise...
            else:
                # Just check the left, forward, and right
                flow_range = range(-2, 2 + 1)
        
            # Evaluate the surrounding lattice points, choose the one with the
            # lowest score
            for turn in flow_range:
                # Calculate our new flow value
                adj_flow = (old_flow + turn) % len(RiverFlow)

                # Unpack our adjustments for our current flow direction
                adj_x, adj_y = flow_shifts[ adj_flow ]

                # Get the xy tuple for the new lattice
                new_xy = river_lattice[lat_x + adj_x][lat_y + adj_y]

                # Sum up this value across all the provided generators
                value = generator.get_value(new_xy[0], new_xy[1])

                new_dist = game_util.tuple_distance(new_xy, (exit_x, exit_y))

                # If this point is farther from our goal than the current point...
                if new_dist > curr_dist:
                    # Add a stupidly big number so this doesn't get picked
                    value += 100 + new_dist - curr_dist

                # If this is currently the lowest value, then update our tracking
                if value < low_val:
                    low_val = value
                    curr_lp.flow = adj_flow
                    curr_lp.next_lat_pos = (lat_x + adj_x, lat_y + adj_y)

            # Update the old flow
            old_flow = curr_lp.flow

            # If the next point is occupied, then walk down the chain and
            # increase the river's size
            if curr_lp.next_lat_pos in occupied_points:
                print("OCCUPIED COLLISION")
                next_pos = curr_lp.next_lat_pos
                cur_pos = None

                # Walk down the river, increasing it's size
                while next_pos in occupied_points:
                    cur_pos = next_pos
                    occupied_points[cur_pos].size += 3
                    next_pos = occupied_points[cur_pos].next_lat_pos

                print("FINISHED COLLISION")
                # And finish the loop - that's it for this source.
                in_map = False

            # Otherwise...
            else:
                # Update our current lattice x and y
                lat_x, lat_y = curr_lp.next_lat_pos

                # Get the current / new xy point
                curr_xy = river_lattice[lat_x][lat_y]

                # Check if you're still in bounds.
                in_map = (0 <= curr_xy[0] < X_SIZE) and (0 <= curr_xy[1] < Y_SIZE)
    """
    ~
    ~ Step 5: Now that we have a heap of LatticePoints, generate these into
    ~         a heap of RiverSegment objects.
    ~
    """
    segments = []

    for lp_pos, lp in occupied_points.items():
        # Get our points
        x1, y1 = river_lattice[ lp_pos[0] ][ lp_pos[1] ]
        x2, y2 = river_lattice[ lp.next_lat_pos[0] ][ lp.next_lat_pos[1] ]

        # Get our x distance
        x_dist = x2 - x1

        # If our x_dist is 0, then we have a vertical line. Our slope range
        # needs to be be different
        if x_dist == 0:
            slope = None
            slope_range = range(0, round(y2 - y1), round(math.copysign(1, y2 - y1)) )

        # Otherwise, we can make a normal slope
        else:
            slope = (y2 - y1) / (x_dist)
            slope_range = range(0, round(x_dist), round(math.copysign(1, x_dist)) )

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

            if not (0 <= seg.pos[0] < X_SIZE and 0 <= seg.pos[1] < Y_SIZE):
                print("\tABBERANT SEG POS!")
                print("\tslope", slope, slope_range)
                print("\tseg pos", seg.pos)
                print("\tlp pos", lp_pos)
                print("\txy1", x1, y1)
                print("\txy2", x2, y2)
                print()

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
