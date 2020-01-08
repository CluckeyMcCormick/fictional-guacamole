extends RigidBody2D

# The container for bodies we are currently tracking as our "flock"
var flock_members = {}

# The container for bodies we are currently tracking as our "dangers"
var obstacle_members = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

# An area has entered our detection area
# This might be an attack guide of some sort

# An area has exited our detection area
# This might be an attack guide of some sort

# A physical body has entered our flock detection zone
# This is either another boid, an obstacle, or a projectile
func _on_Flock_Area_body_entered(body):
    pass # Replace with function body.

# A physical body has exited our detection zone
# As above, this is either another boid, an obstacle, or a projectile
func _on_Flock_Area_body_exited(body):
    pass # Replace with function body.
