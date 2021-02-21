extends Position3D

# The current item we're holding on to.
var current_item = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Core functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func grab_item(node : MasterItem):
    # If we're not dealing with an item, then back out.
    if not node is MasterItem:
        return
    
    # Otherwise, we're doing this! Set item state to carried.
    node.item_state = node.ItemState.CARRIED
    
    # It's our current item
    current_item = node
    
    # First, detach the node from it's parent. That's what this weird circular
    # code segment is supposed to do
    current_item.get_parent().remove_child(current_item)
    # COOL! Now, add the node as our child
    add_child(current_item)
    # Okay, last thing - set this item manager as the owner of the node we just
    # took in. The owner is apparently separate from the concept of a parent,
    # though closely related.
    current_item.set_owner(self)

func drop_item(node : MasterItem):
    # Very dumb assumption - since the core probably sits as an integrating body
    # in a scene, then our parent's parent is PROBABLY where the item should go.
    # It's TOO genius to NOT WORK!
    var target_node = get_parent().get_parent()
    
    # First, detach the node from ourselves
    self.remove_child(current_item)
    # Move the item out there
    target_node.add_child(current_item)
    # Assert ownership
    target_node.set_owner(current_item)
    
    # Set it to the independent state
    current_item.item_state = current_item.ItemState.INDEPENDENT
    
    # Clear our tracker - it's out of our hands now!
    current_item = null
