extends Spatial

# Preload our item moving task so we can instance it on demand
const MOVE_ITEMS_TASK_PRELOAD = preload("res://motion_ai/common/tasking/MoveItemDropMulti.tscn")

func _ready():
    for item in $ItemManager.get_children():
        $GUI/ItemList.add_item(item.name)

func _on_StartButton_pressed():
    # First, unpack the item that was selected by getting all the selected items
    var chosen_item = $GUI/ItemList.get_selected_items()
    # Back out if we don't have anything.
    if len(chosen_item) <= 0:
        print("No Item Chosen")
        return
    
    # We're configured to only allow one selection at a time, so get the first
    # entry index
    chosen_item = chosen_item[0]
    # Use that index to get the string name of the item
    chosen_item = $GUI/ItemList.get_item_text(chosen_item)
    # Finally, merge that string name with the ItemManager path to get the
    # node
    chosen_item = get_node("ItemManager/" + chosen_item)

    # Now, do the same for the destination
    var chosen_destination = $GUI/DestinationList.get_selected_items()
    # Back out if we don't have anything.
    if len(chosen_destination) <= 0:
        print("No Destination Chosen")
        return
    
    chosen_destination = chosen_destination[0]
    chosen_destination = $GUI/DestinationList.get_item_text(chosen_destination)
    chosen_destination = get_node(chosen_destination)
    
    # If either of the chosen articles doesn't exist...
    if chosen_item == null or chosen_destination == null:
        # Inform the user and back out
        print("Invalid Item or Destination!")
        return
    
    # Create the move task
    var move_task = MOVE_ITEMS_TASK_PRELOAD.instance()
    var arg_dict = {}
    
    # Create the arg_dict
    arg_dict[move_task.AK_ITEMS_LIST] = [chosen_item]
    arg_dict[move_task.AK_DROP_POSITION] = chosen_destination.global_transform.origin
    # Initialize!!!
    move_task.specific_initialize(arg_dict)
    
    # Tell the Pawn to move it!
    $TaskingCowardPawn.give_task(move_task)
