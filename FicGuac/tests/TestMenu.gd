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
        $Control/VBoxContainer/ItemList.add_item(test_name)

    # Assert loading screen is invisible by default
    $Control/LoadingScreen.visible = false

func _on_Button_pressed():
    # Get the selected item(s)
    var selected_item = $Control/VBoxContainer/ItemList.get_selected_items()
    
    # Back out if we don't have anything selected
    if selected_item.size() <= 0:
        return
    
    # selected_item is currently a PoolIntArray - we only want the first item 
    # selected, so let's just get the first value out of it
    selected_item = selected_item[0]
    
    # Now we have an index for an item in the ItemList, but we need to translate
    # that in to a string so we have a key for the dict.
    selected_item = $Control/VBoxContainer/ItemList.get_item_text(selected_item)
    
    # Now that we have a key, we can translate that into a resource path
    selected_item = scene_paths[selected_item]
    
    # Turn on our loading screen
    $Control/LoadingScreen.visible = true
    
    # Change that scene
    get_tree().change_scene(selected_item)
