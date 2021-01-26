extends State

onready var TestMenu = get_node("../../TestMenu")

func _on_enter(var arg) -> void:
    # Assert menu state
    TestMenu.disabled = false
    TestMenu.visible = true
    
    # Menu state doesn't have any scene loaded or loading.
    target.scene_res = null
    # If we happen to have a scene, free it.
    if target.scene_running != null:
        target.remove_child(target.scene_running)
        target.scene_running.queue_free()
    # Now blank the scene running anyway
    target.scene_running = null
    
    # Listen out for a the user picking a scene
    TestMenu.connect("scene_chosen", self, "_on_TestMenu_scene_chosen")

func _on_exit(var arg) -> void:
    # Assert the menu is disabled
    TestMenu.disabled = true
    # Might as well hide it while we're at it
    TestMenu.visible = false
    
    # We don't care if the user is picking a scene anymore
    TestMenu.disconnect("scene_chosen", self, "_on_TestMenu_scene_chosen")

func _on_TestMenu_scene_chosen(resource_path, scene_name):
    # Disable the menu so the user doesn't accidentally trigger another load
    TestMenu.disabled = true
    # Update the scene we're gonna load
    target.scene_res = resource_path

    # Change to the loading scene!
    change_state("Loading")
