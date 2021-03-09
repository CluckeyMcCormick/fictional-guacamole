extends "res://motion_ai/common/tasking/TaskTemplate.gd"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~0

func initialize(machine_root, physics_travel_region, target_body, item, position):
    # Initialize the template's variables
    _template_initialize(machine_root, physics_travel_region, target_body)
    
    # Pass the item down to the states that need it.
    $MoveToEntityRangeArea._target_entity = item
    $GrabItem._target_entity = item
    
    # Pass the position down to the states that need it.
    $MoveToPosition._target_position = position

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_DropItemCautionary_action_failure(failure_code):
    # We didn't drop an item. That could only be because we didn't have an item
    # to drop. Oh well! We mostly did that just in case we had an item still.
    change_state("MoveToEntityRangeArea")

func _on_DropItemCautionary_action_success():
    # We did it. Hooray! Okay, now let's move into range of the item.
    change_state("MoveToEntityRangeArea")

func _on_MoveToEntityRangeArea_action_failure(failure_code):
    # Oh, we failed. Dang. Fail the task, I guess.
    emit_signal("task_failed")

func _on_MoveToEntityRangeArea_action_success():
    # We did it. Hooray! Let's grab the item.
    change_state("GrabItem")

func _on_GrabItem_action_failure(failure_code):
    # Oh, we failed. Dang. Fail the task, I guess.
    emit_signal("task_failed")

func _on_GrabItem_action_success():
    # Okay, now that we have the item, we need to move in to our specified
    # position.
    change_state("MoveToPosition")

func _on_MoveToPosition_action_failure(failure_code):
    # Oh, we failed. Dang. Fail the task, I guess.
    emit_signal("task_failed")

func _on_MoveToPosition_action_success():
    # We're finally where we want to be! Drop the item
    change_state("DropItemFinal")

func _on_DropItemFinal_action_failure(failure_code):
    # Oh, we failed. Dang. Fail the task, I guess.
    emit_signal("task_failed")

func _on_DropItemFinal_action_success():
    # We did it! We dropped the item. Task succeeded!
    emit_signal("task_succeeded")
