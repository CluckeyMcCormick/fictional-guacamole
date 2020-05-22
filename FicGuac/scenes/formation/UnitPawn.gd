extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# What's our tolerance for meeting our goal
const GOAL_TOLERANCE = .1
# What's our tolerance for straying/overshooting on our path to the goal
const PATHING_TOLERANCE = .05

# How fast do we move? (units/second)
const MOVE_RATE = 1
var move_order = null #Vector3(2, 2, 2)

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _physics_process(body_state):   
    var dirs = Vector3.ZERO
    
    if not self.is_on_floor():
        dirs.y = -4.9
    
    if move_order and self.global_transform.origin.distance_to(move_order) < GOAL_TOLERANCE:
        move_order = null
    
    if move_order != null:
        # Calculate the distance from our current global position
        dirs = move_order - self.global_transform.origin
        # Use that distance to calculate a direction on each axis - do we need to go
        # positively or negatively?
        if dirs.x != 0 and abs(dirs.x) > PATHING_TOLERANCE:
            dirs.x = dirs.x / abs(dirs.x)
        if dirs.z != 0 and abs(dirs.z) > PATHING_TOLERANCE:
            dirs.z = dirs.z / abs(dirs.z)
 
    # If we're trying to move somewhere...
    if dirs != Vector3.ZERO:
        # Then move (with some snap)
        self.move_and_slide_with_snap(dirs * MOVE_RATE, Vector3(0, 1, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
