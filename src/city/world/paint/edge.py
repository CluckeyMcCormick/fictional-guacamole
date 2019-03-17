"""
edge.py

Contains functions for determining the tile edges on the detail map.
"""

def edge_pass(world_data, orders, world_ts, detail_ts):
    """
    The world is a series of tiles, like this:
         |       |       |
        -+---+---+---+---+- The left hand side is a normal tile, bereft of any
         |       |   |   |  detail markings. The right hand side is a tile with
         |       | 2 | 3 |  detail markings. As you can see, each tile has four
         |       |   |   |  detail tiles that occupy the corners.
         |       |---+---+-
         |       |   |   |  The edge pass algorithm observes each detail tile's
         |       | 0 | 1 |  applicable neighbors: one above or below, one left
         |       |   |   |  or right, and one corner-wise. It then determines
        -+---+---+---+---+- which edge tile would be best for that detail tile.
         |       |       |    
    """

    x_size, y_size = world_data.get_sizes()
    first, limit = orders

    # The detail world assigns 4 sub-tiles to each primary tile, and is thusly
    # twice as big on each axis
    x_det_size = x_size * 2
    y_det_size = y_size * 2
    det_sizes = (x_det_size, y_det_size)

    # Using numpy, reshape the raw array so we can work on it in terms of x,y
    shaped_world = world_data.make_terrain_shaped()
    # Ditto for the detail array
    shaped_detail = world_data.make_detail_shaped()

    # The neighbor shifts on world_x and world_y, for each detail tile
    # We'll use these to quickly check the neighbor tiles for each detail tile
    shifts = [
        # n_horiz_a, n_vert_b, n_corner_c
        ( (-1, 0), (0, -1), (-1, -1) ), #(+0, +0) (0)
        ( ( 1, 0), (0, -1), ( 1, -1) ), #(+1, +0) (1)
        ( (-1, 0), (0,  1), (-1,  1) ), #(+0, +1) (2)
        ( ( 1, 0), (0,  1), ( 1,  1) )  #(+1, +1) (3)
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
    tile_strings = [
        # int_corner, horiz, vert, ext_corner
        ("LOWER_LEFT_INNER", "LEFT_EDGE_A", "BOTTOM_EDGE_A", "UPPER_RIGHT_OUTER"),  #(+0, +0)
        ("LOWER_RIGHT_INNER", "RIGHT_EDGE_A", "BOTTOM_EDGE_B", "UPPER_LEFT_OUTER"), #(+1, +0)
        ("UPPER_LEFT_INNER", "LEFT_EDGE_B", "TOP_EDGE_A", "LOWER_RIGHT_OUTER"),     #(+0, +1)
        ("UPPER_RIGHT_INNER", "RIGHT_EDGE_B", "TOP_EDGE_B", "LOWER_LEFT_OUTER")     #(+1, +1)
    ]

    for world_x in range(first, limit):
        for world_y in range(y_size):
            current_tile = world_ts.get_enum( shaped_world[world_x, world_y] )

            det_x = world_x * 2
            det_y = world_y * 2

            for i in range(4):

                # Get our neighbor tiles
                neighbor_list = []
                for pair in shifts[i]:
                    adj_x, adj_y = pair

                    # Value is None by default
                    value = None

                    # If we're in the appropriate boundaries...
                    if (0 <= world_x + adj_x < x_size) and (0 <= world_y + adj_y < y_size):
                        value = shaped_world[world_x + adj_x, world_y + adj_y]
                        value = world_ts.get_enum( value )
                    neighbor_list.append( value )

                # Pack those neighbor tiles into a tuple for easy access
                neighbor_tuple = (
                    neighbor_list[0], neighbor_list[1], neighbor_list[2]
                )

                edge_enum = edge_determine(current_tile, neighbor_tuple, tile_strings[i])

                adj_det_x = i % 2
                adj_det_y = i // 2

                value = detail_ts.get_designate( edge_enum )
                shaped_detail[det_x + adj_det_x, det_y + adj_det_y] = value

def enum_sort_key(enum):
    if enum is None:
        return math.inf
    else:
        return enum.value

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