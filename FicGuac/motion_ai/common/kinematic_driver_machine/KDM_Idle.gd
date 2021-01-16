tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node

    # If we have a target position, then switch to our "idle" mode
    if KC.target_position:
        change_state("Walk")
    
    # Otherwise, broadcast that we need to update the visuals of whoever is
    # listening
    MR.emit_signal("visual_update", "idle", KC._curr_orient)
