tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

func _on_enter(var attack) -> void:
    # Set the state key
    MR.state_key = "Attack"
    
    # Connect the attack complete signal so we can detect when the attack
    # finishes
    #
    
    # Start the attack (however we do that)
    #
    pass

# Instead of updating via _on_update, we let the attack play out. It's up to the
# integrating body and the attack to do the right thing. All we care about is
# whenever the attack finishes, so we go back to the "TargetAcquired" state.
func _on_Attack_finished(var input):
    change_state("TargetAcquired")

func _on_exit(var input) -> void:
    # Disconnect the attack complete signal so we don't accidentally call it in
    # another state.
    #
    pass
