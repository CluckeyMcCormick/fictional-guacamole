extends KinematicBody

# Since the cubit's position is measured from the origin - which is the center
# of of the cube. However, our waypoints sit on the floor. So we need to adjust
# those incoming points vertically. 0.5 is the height of the cubit, and .001396
# was the OBSERVED remainder.
const FLOOR_DISTANCE = .001396 + 0.5

# This is the destination, which we update when set_destination is called
var destination setget set_destination

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _process(delta):
    var orient = $KinematicDriverMachine._curr_orient

    $Cube.rotation_degrees.y = rad2deg(Vector2(-orient.x, orient.z).angle()) + 90

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Core coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the destination of this Cubit. The position must be on the floor. For most
# purposes (like path following), this is naturally where the point will be.
func set_destination(floor_position : Vector3):
    $KinematicDriverMachine.target_position = floor_position
    destination = floor_position

func get_floor_adjusted_position():
    # Get our current position
    var curr_pos = self.global_transform.origin
    
    # The adjusted position is at the base of the cube
    return curr_pos - Vector3(0, FLOOR_DISTANCE, 0)
