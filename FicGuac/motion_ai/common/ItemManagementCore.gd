extends Position3D

# When we grab an item, and it's not 3D, we rotate it. To what angles (in
# degrees) do we rotate it?
const DEFAULT_ROTATION_NO3D = Vector3(-90, 45, 0)

# The current item we're holding on to.
var current_item = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Core functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func grab_item(node : MasterItem):
    var visual_node
    
    # If we're not dealing with an item, then back out.
    if not node is MasterItem:
        return
        
    # Turn it into a visual item
    visual_node = node._to_visual_item()
    
    # If we got null passed back to us...
    if visual_node == null:
        # Then something's up with the Item node. Could be that it's currently
        # being dismantled (maybe). Either way, it means we can't grab it, so
        # back out.
        return
        
    # Otherwise, we've got a legit node on our hands. Hooray! Set it as the
    # current item.
    current_item = visual_node
    # COOL! Now, add the node as our child
    add_child(current_item)
    # Okay, last thing - set this item manager as the owner of the node we just
    # took in. The owner is apparently separate from the concept of a parent,
    # though closely related.
    current_item.set_owner(self)
    
    # Now, we do have just a hint more work to do - if the current item is NOT
    # 3D, then we're gonna rotate it a bit
    if not current_item.is_3D():
        current_item.rotation_degrees = DEFAULT_ROTATION_NO3D

func drop_item():
    # Very dumb assumption - since the core probably sits as an integrating body
    # in a scene, then our parent's parent is PROBABLY where the item should go.
    # It's TOO genius to NOT WORK!
    var target_node = get_parent().get_parent()
    
    # First, physicallize the node. This will separate it from ourselves.
    # Turn it into a visual item
    var physical_node = current_item._to_visual_item()
    # Move the item out there
    target_node.add_child(physical_node)
    # Assert ownership
    target_node.set_owner(physical_node)
    
    # Clear our tracker - it's out of our hands now!
    current_item = null
