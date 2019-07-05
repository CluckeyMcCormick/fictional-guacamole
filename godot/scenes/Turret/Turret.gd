extends Sprite

# What's the shortest possible range?
const SHELL_RANGE_MIN = -600
# What's the maximum possible range?
const SHELL_RANGE_MAX = -5
# When the range goes up, how much does it go up by
const SHELL_RANGE_STEP = 5
# What's our current shell range?
var shell_range = SHELL_RANGE_MIN

# Called when the node enters the scene tree for the first time.
func _ready():
    $ShellPath.redraw_shell_path(shell_range)

func _process(delta):
    if Input.is_action_pressed("range_up"):
        shell_range += SHELL_RANGE_STEP
        shell_range = clamp(shell_range, SHELL_RANGE_MIN, SHELL_RANGE_MAX)
        $ShellPath.redraw_shell_path(shell_range)
        
    elif Input.is_action_pressed("range_down"):
        shell_range -= SHELL_RANGE_STEP
        shell_range = clamp(shell_range, SHELL_RANGE_MIN, SHELL_RANGE_MAX)
        $ShellPath.redraw_shell_path(shell_range)
