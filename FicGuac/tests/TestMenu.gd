extends Node2D

var scene_paths = {
    "Pawn Standing Test" : "res://tests/PawnStandingTest.tscn",
    "Cubit Driver Test" : "res://tests/CubitDriverTest.tscn",
    "Slope Step Test" : "res://tests/SlopeStepTest.tscn",
    "Dynamic Navigation Mesh Test" : "res://tests/DynamicNavMeshTest.tscn"
}

# Called when the node enters the scene tree for the first time.
func _ready():
    # We need to update the Item List using our scene paths above
    for test_name in scene_paths.keys():
        $MenuScreen/VBoxContainer/ItemList.add_item(test_name)

    # Assert loading screen is invisible by default
    $LoadingScreen.visible = false

func _on_Button_pressed():
    # Get the selected item(s)
    var selected = $MenuScreen/VBoxContainer/ItemList.get_selected_items()
    
    # Back out if we don't have anything selected
    if selected.size() <= 0:
        return
    
    # selected_item is currently a PoolIntArray - we only want the first item 
    # selected, so let's just get the first value out of it
    selected = selected[0]
    
    # Now we have an index for an item in the ItemList, but we need to translate
    # that in to a string so we have a key for the dict.
    selected = $MenuScreen/VBoxContainer/ItemList.get_item_text(selected)
    
    # Now that we have a key, we can translate that into a resource path
    selected = scene_paths[selected]
    
    # Disable the launch button
    $MenuScreen/VBoxContainer/Button.disabled = true

    # Turn on our loading screen
    $LoadingScreen.visible = true
    
    # Start the load!
    $LoadingScreen.initiate_scene_load(selected)

func _on_LoadingScreen_loading_complete(scene_resource, path):
    # Tell user
    print("Successfully loaded ", path)
    # Instance the scene
    var instance = scene_resource.instance()
    # Add the scene to the root
    get_node("/root").add_child(instance)
    # KRUMP ORSELFS
    queue_free()

func _on_LoadingScreen_loading_failed(path):
    # Turn off our loading screen
    $LoadingScreen.visible = true
    # Re-enable the button
    $MenuScreen/VBoxContainer/Button.disabled = false
    # Tell user
    print("Load failed for path: ", path)
