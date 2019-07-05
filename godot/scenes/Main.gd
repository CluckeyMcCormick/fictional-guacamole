extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const TURRET_VELO_RETENTION_PERCENTAGE = 0.15
var turret_velo = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    # Register the function
    $GUIBox.register_wheel_velocity(self, "_on_wheel_velocity_changed")

func _on_wheel_velocity_changed(new_velo):
    turret_velo = new_velo * TURRET_VELO_RETENTION_PERCENTAGE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # The amount we'll rotate in either direction, in radians
    var CLAMP_MIN = 0
    var CLAMP_MAX = PI
    # Our end rotation, in radians
    var rot = 0 # The player's rotation, in radians.

    # Calculate our rotation, in radians
    rot = turret_velo * delta
    
    # If we actually have a rotation...
    if rot != 0:
        # See if we go under/over our min/max rotation
        var clamp_rot = clamp( $Turret.rotation + rot, CLAMP_MIN, CLAMP_MAX )
        # If the difference between the current rotation isn't the same...
        if clamp_rot - $Turret.rotation != rot:
            # Then we can only assume that we got clamped! Use the lesser
            # rotational value.
            rot = clamp_rot - $Turret.rotation
        $Turret.rotate(rot)
    # Don't do any velocity decay - we'll just let whatever's setting our
    # velocity handle that