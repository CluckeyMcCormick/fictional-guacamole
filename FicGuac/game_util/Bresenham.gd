extends Node

"""
FUNC LINE - Function Line
"""
func func_line(xy0 : Vector2, xy1 : Vector2, func_ref : FuncRef, arg_array : Array = []):
    """
    Performs the provided func over a line that runs from xy0 to xy1.
    The func will be called over each point like so:
        func(xy : Vector2)
    Inputs:
        xy0 & xy1: Vectors, representing the start and end of the line
                   (respectively)
        func: The function to be called on each (x, y) vector that the line
              covers
    """
    var x0 = xy0.x
    var y0 = xy0.y
    var x1 = xy1.x
    var y1 = xy1.y

    if abs(y1 - y0) < abs(x1 - x0):
        if x0 > x1:
            _func_line_low(xy1, xy0, func_ref, arg_array)
        else:
            _func_line_low(xy0, xy1, func_ref, arg_array)
    else:
        if y0 > y1:
            _func_line_high(xy1, xy0, func_ref, arg_array)
        else:
            _func_line_high(xy0, xy1, func_ref, arg_array)

"""
FUNC Circle - Function Circle
"""
func func_circle(mid_xy : Vector2, radius : int, func_ref : FuncRef, fill : bool=false, arg_array : Array = []):
    """
    Performs the provided func over a circle with a center of mid_xy with the
    provided radius.
    The func will be called over each point like so:
        func(xy : Vector2, arg_array)
    Inputs:
        xy0 & xy1: Vectors, representing the start and end of the line
                   (respectively)
        func: The function to be called on each (x, y) vector that the line
              covers
        fill: If true, calls func on every (x, y) in the circle. Otherwise,
              just calls (x, y) on the edge of the circle.
        arg_array : An array of arguments that will passed directly to the
                    function calls.
    """
    var x0 = mid_xy.x
    var y0 = mid_xy.y

    var f = 1 - radius
    var ddf_x = 1
    var ddf_y = -2 * radius
    var x = 0
    var y = radius

    print("Circle Function from x [", x0 - radius, "] to {", x0 + radius, "}")

    # If fill, then draw a line between opposite points 
    if fill:
        func_line( Vector2(x0, y0 + radius), Vector2(x0, y0 - radius), func_ref, arg_array)
        func_line( Vector2(x0 + radius, y0), Vector2(x0 - radius, y0), func_ref, arg_array)
    # Otherwise, simply fill the specified points
    else:
        func_ref.call_func( Vector2(x0, y0 + radius), arg_array )
        func_ref.call_func( Vector2(x0, y0 - radius), arg_array )
        func_ref.call_func( Vector2(x0 + radius, y0), arg_array )
        func_ref.call_func( Vector2(x0 - radius, y0), arg_array )
 
    while x < y:
        if f >= 0: 
            y -= 1
            ddf_y += 2
            f += ddf_y
        x += 1
        ddf_x += 2
        f += ddf_x
        # If fill, then draw a line between opposite points 
        if fill:
            func_line( Vector2(x0 + x, y0 + y), Vector2(x0 - x, y0 + y), func_ref, arg_array )
            func_line( Vector2(x0 + x, y0 - y), Vector2(x0 - x, y0 - y), func_ref, arg_array )
            func_line( Vector2(x0 + y, y0 + x), Vector2(x0 - y, y0 + x), func_ref, arg_array )
            func_line( Vector2(x0 + y, y0 - x), Vector2(x0 - y, y0 - x), func_ref, arg_array )

        # Otherwise, simply fill the specified points
        else:
            func_ref.call_func(Vector2(x0 + x, y0 + y), arg_array)
            func_ref.call_func(Vector2(x0 - x, y0 + y), arg_array)
            func_ref.call_func(Vector2(x0 + x, y0 - y), arg_array)
            func_ref.call_func(Vector2(x0 - x, y0 - y), arg_array)
            func_ref.call_func(Vector2(x0 + y, y0 + x), arg_array)
            func_ref.call_func(Vector2(x0 - y, y0 + x), arg_array)
            func_ref.call_func(Vector2(x0 + y, y0 - x), arg_array)
            func_ref.call_func(Vector2(x0 - y, y0 - x), arg_array)

# Helper for func_line function
# Algorithm for when our line changes primarily over the x axis
func _func_line_low(xy0 : Vector2, xy1 : Vector2, func_ref : FuncRef, arg_array : Array = []):
    var x0 = xy0.x
    var y0 = xy0.y
    var x1 = xy1.x
    var y1 = xy1.y

    var dx = x1 - x0
    var dy = y1 - y0

    var yi = 1
    if dy < 0:
        yi = -1
        dy = -dy

    var D = 2 * dy - dx
    var y = y0

    for x in range(x0, x1 + 1): # Inclusive
        # Call the provided function, giving the args & kwargs
        func_ref.call_func( Vector2(x, y), arg_array )
        if D > 0:
            y = y + yi
            D = D - 2 * dx

        D = D + 2 * dy

# Helper for func_line function
# Algorithm for when our line changes primarily over the y axis
func _func_line_high(xy0 : Vector2, xy1 : Vector2, func_ref : FuncRef, arg_array : Array = []):
    var x0 = xy0.x
    var y0 = xy0.y
    var x1 = xy1.x
    var y1 = xy1.y

    var dx = x1 - x0
    var dy = y1 - y0
    
    var xi = 1
    if dx < 0:
        xi = -1
        dx = -dx

    var D = 2 * dx - dy
    var x = x0

    for y in range(y0, y1 + 1): # Inclusive
        # Call the provided function, giving the args & kwargs
        func_ref.call_func( Vector2(x, y), arg_array )
        if D > 0:
           x = x + xi
           D = D - 2 * dy

        D = D + 2 * dx