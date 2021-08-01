extends "res://motion_ai/common/tasking/actions/core/ActionTemplate.gd"

# When we make the animation demand, what's the animation key we provide? 
export(String) var animation_key = ""
# Does the animation we're using have directionality to it?
export(bool) var use_direction = true

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # Connect the "demand complete" function so we know when our animation is
    # finished
    MR.connect("demand_complete", self, "_on_demand_complete")
    
    # Now, DEMAND THAT THE ANIMATION BE PLAYED!!!
    MR.emit_signal("demand_animation", animation_key, null, use_direction)

func _on_exit(var arg) -> void:
    # Disconnect the "demand complete" function
    MR.disconnect("demand_complete", self, "_on_demand_complete")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_demand_complete(completed_animation_key):
    # If the animation key we were just passed matches ours, then that's a
    # success.
    if completed_animation_key == animation_key:
        emit_signal("action_success")
    # Otherwise, something managed to play ahead of us. Since we cannot confirm
    # what the machine's current state is, we must fail the action.
    else:
        emit_signal("action_failure")
