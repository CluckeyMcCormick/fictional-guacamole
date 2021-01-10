extends Control

var scene_paths = {
    "Pawn Standing Test" : "res://tests/PawnStandingTest.tscn",
    "Cubit Driver Test" : "res://tests/CubitDriverTest.tscn",
    "Slope Step Test" : "res://tests/SlopeStepTest.tscn",
    "Viewport Shader Test" : "res://tests/ViewportShaderTest.tscn",
    "Dynamic Navigation Mesh Test" : "res://tests/DynamicNavMeshTest.tscn",
    "Weapon Attack Test" : "res://tests/WeaponAttackTest.tscn"
}

# Signal emitted whenever this menu chooses a scene. Provides the resource path
# and the formatted human-readable name
signal scene_chosen(resource_path, scene_name)

# Is this scene currently enabled? We try to en/disable the scene so we don't
# accidentally switch scenes
var disabled = true setget set_disabled

func _ready():
    # We need to update the Item List using our scene paths above
    for test_name in scene_paths.keys():
        $VBoxContainer/ItemList.add_item(test_name)

func _on_Button_pressed():
    # Get the selected item(s)
    var selected = $VBoxContainer/ItemList.get_selected_items()
    
    # Back out if we don't have anything selected
    if selected.size() <= 0:
        return
    
    # selected_item is currently a PoolIntArray - we only want the first item 
    # selected, so let's just get the first value out of it
    selected = selected[0]
    
    # Now we have an index for an item in the ItemList, but we need to translate
    # that in to a string so we have a key for the dict.
    selected = $VBoxContainer/ItemList.get_item_text(selected)
    
    # Now that we have a key, we can translate that into a resource path. Nab
    # that and emit it.
    emit_signal("scene_chosen", scene_paths[selected], selected)

# Set the disabled status for this scene.
func set_disabled(new_bool):
    disabled = new_bool
    if disabled:
        $VBoxContainer/Button.disabled = true
    else:
        $VBoxContainer/Button.disabled = false
