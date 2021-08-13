extends "res://motion_ai/common/tasking/core/TaskTemplate.gd"

# ArgKey - the target we're attempting to attack. Should be a KinematicBody of
# some kind.
const AK_ATTACK_TARGET = "attack_target"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Task Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func specific_initialize(arg_dict):
    
    # Pass the target entity down to the states that need it.
    $MoveToEntityDistance._target_entity = arg_dict[AK_ATTACK_TARGET]
    $MeleeAttack.attack_target = arg_dict[AK_ATTACK_TARGET]

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_MoveToEntityDistance_action_failure(failure_code):
    # If we couldn't reach our target, then we failed!
    emit_signal("task_failed")

func _on_MoveToEntityDistance_action_success():
    # The target is now in range. If we have a wind-up...
    if $TimeWaitWindup.wait_time > 0:
        # start the wind-up
        change_state("TimeWaitWindup")
    # Otherwise...
    else:
        # Skip straight to the melee attack.
        change_state("MeleeAttack")
    
func _on_TimeWaitWindup_action_failure(failure_code):
    # Technically impossible. But just in case... fail the task!
    emit_signal("task_failed")
    
func _on_TimeWaitWindup_action_success():
    # Wind-up is done, do the attack
    change_state("MeleeAttack")

func _on_MeleeAttack_action_failure(failure_code):
    # If the attack failed then we're in a sort of fuzzy state, best to call
    # that a failure
    emit_signal("task_failed")

func _on_MeleeAttack_action_success():
    # Attack successful!  If we have a recovery...
    if $TimeWaitRecovery.wait_time > 0:
        # start the wind-up
        change_state("TimeWaitRecovery")
    # Otherwise...
    else:
        # Skip straight to the melee attack.
        change_state("MeleeAttack")
    
func _on_TimeWaitRecovery_action_failure(failure_code):
    # Technically impossible. But just in case... fail the task!
    emit_signal("task_failed")

func _on_TimeWaitRecovery_action_success():
    emit_signal("task_succeeded")
