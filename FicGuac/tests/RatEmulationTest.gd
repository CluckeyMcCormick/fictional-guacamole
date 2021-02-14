extends Spatial

func _ready():
    assign_new_target($Blocky)
    assign_new_target($Rocky)
    assign_new_target($Jockey)
    assign_new_target($Dave)

func assign_new_target(patrol_ai):
    # Get the crumbs
    var crumbs = get_tree().get_nodes_in_group("crumbs")
    # Pick a random crumb
    var chosen_crumb = crumbs[randi() % len(crumbs)]
    # Path to it!
    patrol_ai.move_to_point(chosen_crumb.global_transform.origin)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_Blocky_error_goal_stuck(target_position):
    assign_new_target($Blocky)

func _on_Rocky_error_goal_stuck(target_position):
    assign_new_target($Rocky)

func _on_Jockey_error_goal_stuck(target_position):
    assign_new_target($Jockey)

func _on_Dave_error_goal_stuck(target_position):
    assign_new_target($Dave)

func _on_Blocky_path_complete(position):
    assign_new_target($Blocky)

func _on_Rocky_path_complete(position):
    assign_new_target($Rocky)

func _on_Jockey_path_complete(position):
    assign_new_target($Jockey)

func _on_Dave_path_complete(position):
    assign_new_target($Dave)

func _on_Blocky_could_not_path(original_target):
    $Blocky/BlockyTimer.start()

func _on_Rocky_could_not_path(original_target):
    $Rocky/RockyTimer.start()

func _on_Jockey_could_not_path(original_target):
    $Jockey/JockeyTimer.start()

func _on_Dave_could_not_path(original_target):
    $Dave/DaveTimer.start()

func _on_BlockyTimer_timeout():
    assign_new_target($Blocky)

func _on_RockyTimer_timeout():
    assign_new_target($Rocky)

func _on_JockeyTimer_timeout():
    assign_new_target($Jockey)

func _on_DaveTimer_timeout():
    assign_new_target($Dave)
