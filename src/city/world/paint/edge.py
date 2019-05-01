"""
edge.py

Contains functions for determining the tile edges on the detail map.
"""

import math

from ..assets.terrain_detail import EdgeKey, DetailKey

from game_util.enum import CardinalEnum

def edge_pass(world_data, orders, world_ts, detail_ts):
    """
    The world is a series of tiles, like this:
         |         |         |
        -+----+----+----+----+- The left hand side is a normal tile, bereft of 
         |         |    |    |  any detail markings. The right hand side is a
         |         | NW | NE |  tile with detail markings. As you can see, each
         |         |    |    |  tile has four detail tiles that occupy the
         |         |----+----+- corners.
         |         |    |    |  
         |         | SW | SE |  The edge pass algorithm observes each detail 
         |         |    |    |  tile's applicable neighbors: one above or 
        -+----+----+----+----+- below, one left or right, and one corner-wise.
         |         |         |  It then determines which edge tile would be best 
                                for that detail tile.
    """

    x_size, y_size = world_data.sizes
    first, limit = orders

    # The detail world assigns 4 sub-tiles to each primary tile, and is thusly
    # twice as big on each axis
    x_det_size = x_size * 2
    y_det_size = y_size * 2
    det_sizes = (x_det_size, y_det_size)

    # The list of quads we will investigate, in the order we will
    # investigate them
    quad_list = [
        CardinalEnum.NORTH_EAST, CardinalEnum.NORTH_WEST,
        CardinalEnum.SOUTH_WEST, CardinalEnum.SOUTH_EAST
    ]

    """
    Each edge tile has an enum constant, with a name of the form PRIMARY_EDGE,
    where PRIMARY is the primary tile type ( GRASS, STONE, DIRT ) and EDGE is
    the type of tile. 
    
    These strings are the EDGE component of those enum constants. There are four
    possible types of edge tile we'll need to place: an interior corner, a
    horizontal edge, a vertical edge, and an exterior corner. Each set of
    strings lines up with those edge types.
    """
    tile_strings = {
        # int_corner, horiz, vert, ext_corner
        CardinalEnum.SOUTH_WEST : (
            "LOWER_LEFT_INNER", "LEFT_EDGE_A", "BOTTOM_EDGE_A", "UPPER_RIGHT_OUTER"
        ),
        CardinalEnum.SOUTH_EAST : (
            "LOWER_RIGHT_INNER", "RIGHT_EDGE_A", "BOTTOM_EDGE_B", "UPPER_LEFT_OUTER"
        ),
        CardinalEnum.NORTH_WEST : (
            "UPPER_LEFT_INNER", "LEFT_EDGE_B", "TOP_EDGE_A", "LOWER_RIGHT_OUTER"
        ),
        CardinalEnum.NORTH_EAST : (
            "UPPER_RIGHT_INNER", "RIGHT_EDGE_B", "TOP_EDGE_B", "LOWER_LEFT_OUTER"
        )
    }

    # The shifts for each quad to match with it's detail tile.
    detail_shifts = {
        CardinalEnum.SOUTH_WEST : (0, 0),
        CardinalEnum.SOUTH_EAST : (1, 0),
        CardinalEnum.NORTH_WEST : (0, 1),
        CardinalEnum.NORTH_EAST : (1, 1)
    }

    # For each base tile in our range...
    for world_x in range(first, limit):
        for world_y in range(y_size):
            # Get the enumeration using the designate
            current_tile = world_ts.get_enum( world_data.base[world_x, world_y] )

            # Calculate the detail map position
            det_x = world_x * 2
            det_y = world_y * 2

            # For each of this tile's quadrants
            for q in quad_list:
                q_x, q_y = q.shift

                # Holds the enums from each of the neighboring tiles. The order
                # will be horizontal, vertical, then diagonal. We'll convert it
                # to a tuple later for easy unpacking.
                neighbor_list = []

                # Get a value for each of our three neighbor tiles.
                # One horizontal, one vertical, one diagonal.
                for pair in [ (q_x, 0), (0, q_y), q.shift ]:
                    # Unpack the shift
                    adj_x, adj_y = pair

                    # Value is None by default
                    value = None

                    # Calculate our ADJusted position
                    adj_coord = (world_x + adj_x, world_y + adj_y)

                    # If we're in the appropriate boundaries...
                    if world_data.base.in_bounds(adj_coord):
                        # Get the designate value for the tile
                        temp = world_data.base[adj_coord]
                        # Get the enum from that designate
                        temp = world_ts.get_enum( temp )

                        # If this enum has an edge...
                        if temp.has_edge:
                            # Then get the proxy.
                            value = temp.proxy
                        # Otherwise, we're not interested in this tile. We'll
                        # have this tile stay as the default.

                    # Add this value to the list
                    neighbor_list.append( value )

                # Determine the edge type to put here
                edge_enum = edge_determine(current_tile, tuple(neighbor_list), tile_strings[q])

                # Unpack our detail shifts
                adj_det_x, adj_det_y = detail_shifts[q]

                # Get the designate for the enum so we can "paint" it.
                value = detail_ts.get_designate( edge_enum )
                # Paint the detail layer with our designate
                world_data.detail[det_x + adj_det_x, det_y + adj_det_y] = value

def enum_sort_key(enum):
    if enum is None:
        return math.inf
    else:
        return enum.precedence

def edge_determine(current_tile, neighbors, tiles):
    n_horiz_a, n_vert_b, n_corner_c = neighbors
    int_corner, horiz, vert, ext_corner = tiles

    # Step 1 : Determine what our "Dominant" tile type is
    # Sorts the list literal then grabs the first item which will have the
    # highest value enum
    dom_list = [current_tile, n_horiz_a, n_vert_b, n_corner_c]
    dom_list.sort(key=enum_sort_key)
    dominant = dom_list[0]

    # Step 2 : Error catching
    # If the dominant tile is our current one OR the dominant tile was a NONE
    # tile, back out
    if dominant == current_tile or dominant is None:
        return DetailKey.NONE

    # Step 3 : If cascade
    # Check if we want to make an interior corner
    target_tile = DetailKey.NONE

    if n_horiz_a == n_vert_b == dominant:
        target_tile = int_corner

    elif n_horiz_a == dominant:
        target_tile = horiz

    elif n_vert_b == dominant:
        target_tile = vert

    elif n_corner_c == dominant:
        target_tile = ext_corner

    # Return the chosen tile - combine the dominant tile with our edge tile
    return EdgeKey[dominant.name + '_' + target_tile]