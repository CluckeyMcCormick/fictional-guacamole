extends Spatial

func _ready():
    for item in $ItemManager.get_children():
        $GUI/ItemList.add_item(item.name)

func _on_StartButton_pressed():
    # First, unpack the item that was selected by getting all the selected items
    var chosen_item = $GUI/ItemList.get_selected_items()
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
    chosen_destination = chosen_destination[0]
    chosen_destination = $GUI/DestinationList.get_item_text(chosen_destination)
    chosen_destination = get_node(chosen_destination)
    
    # If either of the chosen articles doesn't exist...
    if chosen_item == null or chosen_destination == null:
        # Inform the user and back out
        print("Invalid Item or Destination!")
        return
    
    # Otherwise, tell the Pawn to move it!
    $TaskingCowardPawn.move_item(
        chosen_item,
        chosen_destination.global_transform.origin
    )

