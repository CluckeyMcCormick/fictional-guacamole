extends "res://motion_ai/common/tasking/actions/core/ActionTemplate.gd"

# What's the string name associated with the timer we instantiate?
const WAIT_TIMER_NAME = "WAIT_TIMER"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene.

# For this action, we're just going to wait. Do nothing. For how long do we do
# nothing (in seconds)?
export(float) var wait_time

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Start the timer as soon as we enter
func _on_enter(var arg) -> void:
    add_timer(WAIT_TIMER_NAME, wait_time)

# Once the wait is done, the action suceeds!
func _on_timeout(name) -> void:
    # If the timer ends, then items time to start falling!
    match name:
        WAIT_TIMER_NAME:
            emit_signal("action_success")
