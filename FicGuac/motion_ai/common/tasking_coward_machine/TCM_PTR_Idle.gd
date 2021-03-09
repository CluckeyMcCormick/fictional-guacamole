tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../../..")

# We keep several variables pertinent to kinematic movement in the PhysicsRegion
# state, so grab that real quick
onready var PTR = get_node("../..")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # If our machine root hasn't been configured (it happens unfortunately
    # often), then force the configuration
    if not MR._machine_configured:
        MR._force_configure()
    
    # Set the physics travel key
    MR.physics_travel_key = "Idle"

func _on_update(delta) -> void:
    # If we have a target position, then switch to our "Walk" mode
    if PTR._target_position or PTR._target_path:
        change_state("Walk")
    
