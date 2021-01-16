extends Spatial

# This script tests the Driver's ability to move and interface with a

# Here's where we'll store the nodes
var node_list = []

# What's the index of our current node?
var node_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    # Get all of our nodes together into a list
    node_list = [
        $Targets/Target01, $Targets/Target02, $Targets/Target03,
        $Targets/Target04, $Targets/Target05, $Targets/Target06,
        $Targets/Target07, $Targets/Target08, $Targets/Target09
    ]
    
    # Call our "on target reached" function. Just makes things easier.
    _on_KinematicDriverMachine_target_reached(Vector3.ZERO)
    
# Update the GUI so we know what's up
func _process(delta):
    # Set the test text
    $Items/TestLabel/Info.text = str(node_index)
    # Set the target label to the target vector
    $Items/TargetLabel/Info.text = str( $Cubit.destination )
    # Set the position label to the position vector
    $Items/PositionLabel/Info.text = str( $Cubit.global_transform.origin )
    # Set the distance to the target vector
    if $Cubit.destination:
        $Items/DistanceLabel/Info.text = str(
            $Cubit.global_transform.origin.distance_to( $Cubit.destination )
        )
    else:
        $Items/DistanceLabel/Info.text = "NAN"

# Whenever the cubit reaches a position/target/destination, it emits a singal
# that we catch with this function.
func _on_KinematicDriverMachine_target_reached(position):
    # We reached whatever our target position was. Time to assign a new
    # position. Need to assign a position randomly - so randomly assign our node
    # index
    node_index = randi() % len(node_list)
    
    # Set the destination for the Cubit
    $Cubit.destination = node_list[node_index].global_transform.origin

