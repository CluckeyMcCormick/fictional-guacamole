extends "res://motion_ai/common/tasking/TaskTemplate.gd"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func initialize(machine_root, physics_travel_region, target_body, flee_distance):
    # Initialize the template's variables
    _template_initialize(machine_root, physics_travel_region, target_body)
    
    # Pass down the flee_distance
    $FleeAllBody.flee_distance = flee_distance

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_FleeAllBody_action_failure(failure_code):
    emit_signal("task_failed")

func _on_FleeAllBody_action_success():
    emit_signal("task_succeeded")
