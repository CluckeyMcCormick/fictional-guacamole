extends "res://motion_ai/common/tasking/core/TaskTemplate.gd"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~0

func initialize(machine_root, physics_travel_region, target_body, wander_distance):
    # Initialize the template's variables
    _template_initialize(machine_root, physics_travel_region, target_body)
    
    # Start with a vector of fixed length
    var point = Vector3(1, 0, 0)
    
    # Spin the vector to give us a random angle
    point = point.rotated(Vector3.UP, deg2rad(randi() % 360))

    # Now, normalize it and then scale the normalization by our move distance
    # configurable
    point = point.normalized() * wander_distance
    
    # Add it on to the integrating body's current position
    point += target.global_transform.origin
    
    # Pass the position down to the states that need it.
    $MoveToPosition._target_position = point

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_MoveToPosition_action_failure(failure_code):
    # We only had one action, so that's a fail I guess.
    emit_signal("task_failed")
    
func _on_MoveToPosition_action_success():
    # Our singular action suceeded, so the task suceeds
    emit_signal("task_succeeded")

