tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

func _on_enter(var input) -> void:
    # Set the state key
    MR.state_key = "TargetAcquired"

func _on_update(var delta):
    
    # Query our attack... item to see if a target is in range. If it isn't,
    # change to the Scanning state.
    # change_state("Scanning")

    # Otherwise, if we can attack, THEN ATTACK!
    # change_state("Attack")

    pass
