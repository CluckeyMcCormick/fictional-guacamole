extends "res://motion_ai/common/tasking/core/TaskTemplate.gd"

# ArgKey - The distance we'll attempt to move in one direction before
# reevaluating. Float or int acceptable.
const AK_FLEE_DISTANCE = "flee_distance"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Task Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func specific_initialize(arg_dict):
    # Pass down the flee_distance
    $FleeAllBody.flee_distance = arg_dict[AK_FLEE_DISTANCE]

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_FleeAllBody_action_failure(failure_code):
    emit_signal("task_failed")

func _on_FleeAllBody_action_success():
    emit_signal("task_succeeded")
