extends Sprite

var consts = preload("res://scenes/Turret/TurretConstants.gd").new()

# What's our current shell range?
var shell_range = -consts.SHELL_RANGE_MIN

# Called when the node enters the scene tree for the first time.
func _ready():
    $ShellPath.redraw_shell_path(shell_range)

func _on_range_change(new_value):
    shell_range = -new_value
    $ShellPath.redraw_shell_path(shell_range)