
"""
FUNC LINE - Function Line
"""
def func_line(xy0, xy1, func, args=[], kwargs={}):
    """
    Performs the provided func over a line that runs from xy0 to xy1.

    The func will be called over each point like so:
        func(x, y, *args, **kwargs)

    Inputs:
        xy0 & xy1: tuples, representing the start and end of the line
                   (respectively)

        func: The function to be called on each (x, y) tuple that the line
              covers

        args: A list object that will be passed to func as arguments

        kwargs: a dict object that will be passed to func as keyword arguments
    """
    x0, y0 = xy0
    x1, y1 = xy1

    if abs(y1 - y0) < abs(x1 - x0):
        if x0 > x1:
            _func_line_low(xy1, xy0, func, args, kwargs)
        else:
            _func_line_low(xy0, xy1, func, args, kwargs)
    else:
        if y0 > y1:
            _func_line_high(xy1, xy0, func, args, kwargs)
        else:
            _func_line_high(xy0, xy1, func, args, kwargs)

"""
FUNC Circle - Function Circle
"""
def func_circle(mid_xy, radius, func, args=[], kwargs={}, fill=False):
    """
    Performs the provided func over a circle with a center of mid_xy with the
    provided radius.

    The func will be called over each point like so:
        func(x, y, *args, **kwargs)

    Inputs:
        xy0 & xy1: tuples, representing the start and end of the line
                   (respectively)

        func: The function to be called on each (x, y) tuple that the line
              covers

        args: A list object that will be passed to func as arguments

        kwargs: A dict object that will be passed to func as keyword arguments

        fill: If true, calls func on every (x, y) in the circle. Otherwise,
              just calls (x, y) on the edge of the circle.
    """
    x0, y0 = mid_xy

    f = 1 - radius
    ddf_x = 1
    ddf_y = -2 * radius
    x = 0
    y = radius

    # If fill, then draw a line between opposite points 
    if fill:
        func_line( (x0, y0 + radius), (x0, y0 - radius), func, args, kwargs )
        func_line( (x0 + radius, y0), (x0 - radius, y0), func, args, kwargs )
    # Otherwise, simply fill the specified points
    else:
        func(x0, y0 + radius, *args, **kwargs)
        func(x0, y0 - radius, *args, **kwargs)
        func(x0 + radius, y0, *args, **kwargs)
        func(x0 - radius, y0, *args, **kwargs)
 
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
            func_line( (x0 + x, y0 + y), (x0 - x, y0 + y), func, args, kwargs )
            func_line( (x0 + x, y0 - y), (x0 - x, y0 - y), func, args, kwargs )
            func_line( (x0 + y, y0 + x), (x0 - y, y0 + x), func, args, kwargs )
            func_line( (x0 + y, y0 - x), (x0 - y, y0 - x), func, args, kwargs )

        # Otherwise, simply fill the specified points
        else:
            func(x0 + x, y0 + y, *args, **kwargs)
            func(x0 - x, y0 + y, *args, **kwargs)
            func(x0 + x, y0 - y, *args, **kwargs)
            func(x0 - x, y0 - y, *args, **kwargs)
            func(x0 + y, y0 + x, *args, **kwargs)
            func(x0 - y, y0 + x, *args, **kwargs)
            func(x0 + y, y0 - x, *args, **kwargs)
            func(x0 - y, y0 - x, *args, **kwargs)

# Helper for func_line function
# Algorithm for when our line changes primarily over the x axis
def _func_line_low(xy0, xy1, func, args, kwargs):
    x0, y0 = xy0
    x1, y1 = xy1

    dx = x1 - x0
    dy = y1 - y0

    yi = 1
    if dy < 0:
        yi = -1
        dy = -dy

    D = 2 * dy - dx
    y = y0

    for x in range(x0, x1):
        # Call the provided function, giving the args & kwargs
        func(x, y, *args, **kwargs)
        if D > 0:
            y = y + yi
            D = D - 2 * dx

        D = D + 2 * dy

# Helper for func_line function
# Algorithm for when our line changes primarily over the y axis
def _func_line_high(xy0, xy1, func, args, kwargs):
    x0, y0 = xy0
    x1, y1 = xy1
  
    dx = x1 - x0
    dy = y1 - y0
    
    xi = 1
    if dx < 0:
        xi = -1
        dx = -dx

    D = 2 * dx - dy
    x = x0

    for y in range(y0, y1):
        # Call the provided function, giving the args & kwargs
        func(x, y, *args, **kwargs)
        if D > 0:
           x = x + xi
           D = D - 2 * dy

        D = D + 2 * dx
