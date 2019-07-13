extends Control

# Load our constants
var consts = preload("res://scenes/Turret/TurretConstants.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
    $RangeBar.min_value = consts.SHELL_RANGE_MIN
    $RangeBar.max_value = consts.SHELL_RANGE_MAX
    $RangeBar.step = consts.SHELL_RANGE_STEP

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Get the value
    var new_val = $RangeBar.value
    
    # Modify the values, as appropriate
    if Input.is_action_pressed("range_up") or $Up.pressed:
        new_val += consts.SHELL_RANGE_STEP 
    if Input.is_action_pressed("range_down") or $Down.pressed:
        new_val -= consts.SHELL_RANGE_STEP

    # Now that we've got a new value, change the rangebar's value.
    $RangeBar.value = new_val
