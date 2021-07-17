extends Spatial

# Preload our item moving task so we can instance it on demand
const MOVE_ITEMS_TASK_PRELOAD = preload("res://motion_ai/common/tasking/MoveItemDropMulti.tscn")

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

func _ready():
    for key in scene_dictionary.keys():
        $GUI/ItemList.add_item(key)

func _on_StartButton_pressed():
    # An array containing all the items
    var item_array = []
    # The item archetpye we've chosen
    var chosen_item 
    # The new item we've spawned
    var new_item
    # The different locations where we will spawn items. Each spawn point will
    # get one item.
    var spawn_points = []
    # The different locations where we can haul items to. We'll scramble this
    # array and then pick a single item to serve as the destination.
    var end_points = []
    
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
    
    # Get our spawn points
    spawn_points = get_tree().get_nodes_in_group("suggest_spawn")
    
    # Get the cage spawns in there, too
    for node in get_tree().get_nodes_in_group("cage_spawn"):
        spawn_points.append(node)
    
    # Spawn the items, stick them in an array
    for location in spawn_points:
        new_item = chosen_item.instance()
        $ItemManager.add_child(new_item)
        new_item.global_transform.origin = location.global_transform.origin
        new_item.add_to_group("packing_goal")
        item_array.append(new_item)

    # Now get the possible end points
    end_points = get_tree().get_nodes_in_group("point_cardinal")

    # Now shuffle it so we go somewhere different for sure
    randomize()
    end_points.shuffle()

    # Create the move task
    var move_task = MOVE_ITEMS_TASK_PRELOAD.instance()
    var arg_dict = {}
    
    # Create the arg_dict
    arg_dict[move_task.AK_ITEMS_LIST] = item_array
    arg_dict[move_task.AK_DROP_POSITION] = end_points[0].global_transform.origin
    # Initialize!!!
    move_task.specific_initialize(arg_dict)

    # Now, assign the pawn to move ALL those items
    $TaskingCowardPawn.give_task(move_task)

func _on_TaskingCowardPawn_task_complete():
    # Enable the Start Button
    $GUI/StartButton.disabled = false
