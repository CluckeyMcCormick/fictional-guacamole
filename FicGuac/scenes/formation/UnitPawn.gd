extends RigidBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const MOVE_RATE = 1
var move_order = null #Vector3(2, 2, 2)

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _integrate_forces(body_state):
    
    if move_order == null:
        return
    
    # Calculate the distance from our current global position
    var dirs = move_order - self.global_transform.origin
    # Use that distance to calculate a direction on each axis - do we need to go
    # positively or negatively?
    if dirs.x != 0:
        dirs.x = dirs.x / abs(dirs.x)
    if dirs.z != 0:
        dirs.z = dirs.z / abs(dirs.z)
    # Currently, we don't mess with y
    dirs.y = 0
    
    self.set_linear_velocity( dirs * MOVE_RATE )
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
