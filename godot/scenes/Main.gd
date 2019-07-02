extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # The amount we'll rotate in either direction, in radians
    var MAGNITUDE = PI / 2
    var CLAMP_MIN = 0
    var CLAMP_MAX = PI
    # Our end rotation, in radians
    var rot = 0 # The player's movement vector.
    
    if Input.is_action_pressed("tr_rotate_clockwise"):
        rot += MAGNITUDE
    if Input.is_action_pressed("tr_rotate_counterwise"):
        rot -= MAGNITUDE
    rot *= delta
    
    if rot != 0:
        # See if we go under/over our min/max rotation
        var clamp_rot = clamp( $Turret.rotation + rot, CLAMP_MIN, CLAMP_MAX )
        # If the difference between the current rotation isn't the same...
        if clamp_rot - $Turret.rotation != rot:
            # Then we can only assume that we got clamped! Use the lesser
            # rotational value.
            rot = clamp_rot - $Turret.rotation
        $Turret.rotate(rot)
