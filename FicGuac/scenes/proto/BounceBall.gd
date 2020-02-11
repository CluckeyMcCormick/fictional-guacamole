extends RigidBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
    $ImpulseTimer.start()

func _on_ImpulseTimer_timeout():
    # Calculate a random direction for the impulse to come from
    randomize()
    var rand_phi = randf() * (2 * PI)
    # Apply an impulse (in that random direction) to the center
    apply_impulse(Vector2.ZERO, Vector2(250, 0).rotated(rand_phi))
    # Restart the timer
    $ImpulseTimer.start()
