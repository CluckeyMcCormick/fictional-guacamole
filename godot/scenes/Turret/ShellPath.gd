extends Polygon2D

# What's the origin on our shell trail?
const SHELL_PATH_ORIGIN = Vector2(-3, -66)
# How thick is our shell path polygon?
const SHELL_PATH_WIDTH = 6

# Redraw our shell's path, given the new range
func redraw_shell_path(shell_range):
    var new_path = [
        SHELL_PATH_ORIGIN,
        SHELL_PATH_ORIGIN + Vector2(SHELL_PATH_WIDTH, 0),
        SHELL_PATH_ORIGIN + Vector2(SHELL_PATH_WIDTH, shell_range),
        SHELL_PATH_ORIGIN + Vector2(0, shell_range)
    ]
    print(new_path)
    self.set_polygon(new_path)
