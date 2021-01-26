extends State

onready var LoadingScreen = get_node("../../LoadingLayer/LoadingScreen")

func _on_enter(var arg) -> void:
    LoadingScreen.visible = true
    LoadingScreen.initiate_scene_load(target.scene_res)
    
    # Listen out for the load completing or failing
    LoadingScreen.connect("loading_complete", self, "_on_LoadingScreen_loading_complete")
    LoadingScreen.connect("loading_failed", self, "_on_LoadingScreen_loading_failed")

func _on_exit(var arg) -> void:
    # Reset the loading screen
    LoadingScreen.reset()
    LoadingScreen.visible = false
    
    # We're done with these signals
    LoadingScreen.disconnect("loading_complete", self, "_on_LoadingScreen_loading_complete")
    LoadingScreen.disconnect("loading_failed", self, "_on_LoadingScreen_loading_failed")

func _on_LoadingScreen_loading_complete(scene_resource, path):
    # Tell user
    print("Successfully loaded ", path)
    # Instance the scene and put it in the tree
    target.scene_running = scene_resource.instance()
    target.add_child(target.scene_running)
    # We're going into the scene running state!
    change_state("SceneRunning")

func _on_LoadingScreen_loading_failed(path):
    # Tell user
    print("Load failed for path: ", path)
    # We're back at the menu now
    change_state("AtMenu")
