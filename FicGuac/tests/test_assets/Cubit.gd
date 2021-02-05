extends KinematicBody

# Signal issued when this machine reaches it's target. Sends back the Vector3
# position value that was just reached.
signal path_complete(position)

# Signal issued when this driver is stuck and our other error resolution methods
# didn't work.
signal error_goal_stuck(target_position)

# What will the Pawn use to check it's current position and generate paths?
export(NodePath) var navigation
# We resolve the node path into this variable.
var navigation_node

# This is the Cubit's current destination
var destination

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ready():
    # Get the drive target node
    navigation_node = get_node(navigation)
    # Pass our navigation input down to the Pathing Interface Core. Calling
    # get_path() on the resolved node will get the absolute path for the scene,
    # so that we can ensure the PathingInterfaceCore is configured correctly
    $PathingInterfaceCore.navigation_node = navigation_node.get_path()

func _process(delta):
    var orient = $KinematicDriverMachine._curr_orient

    $Cube.rotation_degrees.y = rad2deg(Vector2(-orient.x, orient.z).angle()) + 90

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver Machine coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Order the Cubit to move to a specific point.
func move_to_point(to_point: Vector3):
    $KinematicDriverMachine.move_to_point(to_point)
    destination = to_point

func _on_KinematicDriverMachine_path_complete(position):
    emit_signal("path_complete", position)

func _on_KinematicDriverMachine_error_goal_stuck(target_position):
    emit_signal("error_goal_stuck", target_position)
