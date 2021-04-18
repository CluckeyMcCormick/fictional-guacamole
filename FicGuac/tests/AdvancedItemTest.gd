extends Spatial

# We actively spawn objects in for this test - what is the proper name and scene
# instance for each?
var scene_dictionary = {
    "Corpses" : preload("res://items/corpses/PawnCorpse.tscn"),
    "Apples" : preload("res://items/food/Apple.tscn"),
    "Breads" : preload("res://items/food/Bread.tscn"),
    "Cheeses" : preload("res://items/food/Cheese.tscn"),
    "Barrel" : preload("res://items/furniture/Barrel.tscn"),
    "Box" : preload("res://items/furniture/Box.tscn"),
    "Swords" : preload("res://items/weapons/ShortSword.tscn"),
}

# How many items doe we spawn in a test round?
const ITEMS_PER_ROUND = 5

func _ready():
    for key in scene_dictionary.keys():
        print(key)
        $GUI/ItemList.add_item(key)

func _on_StartButton_pressed():
    var item_array = []
    var chosen_item 
    var new_item
    
    # First, DELETE ALL OF THE ITEM MANAGER'S CHILDREN BWAHAHAHAHAHAHAHA
    for node in $ItemManager.get_children():
        $ItemManager.remove_child(node)
        node.queue_free()
    
    # Now, unpack the item that was selected by getting all the selected items
    chosen_item = $GUI/ItemList.get_selected_items()
    # We're configured to only allow one selection at a time, so get the first
    # entry index
    chosen_item = chosen_item[0]
    # Now we've got an index for an entry in the the item list, so get the
    # string at this index
    chosen_item = $GUI/ItemList.get_item_text(chosen_item)
    # Finally, get the appropriate scene instance using that key
    chosen_item = scene_dictionary[chosen_item]
    
    # Disable the Start Button
    $GUI/StartButton.disabled = true
    
    # Spawn the items, stick them in an array
    for i in range(ITEMS_PER_ROUND):
        new_item = chosen_item.instance()
        $ItemManager.add_child(new_item)
        new_item.global_transform.origin = $West.global_transform.origin
        new_item.add_to_group("packing_goal")
        item_array.append(new_item)

    # Now, assign the pawn to move ALL those items
    $TaskingCowardPawn.move_items(
        item_array,
        $East.global_transform.origin
    )

func _on_TaskingCowardPawn_task_complete():
    # Enable the Start Button
    $GUI/StartButton.disabled = false
