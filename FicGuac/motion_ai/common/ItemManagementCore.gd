extends Position3D

# When we grab an item, we rotate it.
# To what angles (in degrees) do we rotate 2D items?
const DEFAULT_ROTATION_2D = Vector3(-90, 45, 0)

# The current item we're holding on to.
var current_item = null

# Whenever we drop an item, we need to attach it to another parent in the scene.
# The Level Interface Core has a field for a dedicated item-parent. If we don't
# have this core, or the node doesn't point at anything, we'll attach to
# something more... stupid.
export(NodePath) var level_interace_core setget set_level_interface_core
# We resolve the node path into this variable.
var lic_node = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the level interface core. Unlike most cores, we actually resolve the node
# path whenever it gets set.
func set_level_interface_core(new_level_interace_core):
    level_interace_core = new_level_interace_core
        
    # If we're not in the engine, update our configuration warning
    if not Engine.editor_hint:
        lic_node = get_node(level_interace_core)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Core functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func grab_item(node : MasterItem):
    # If we have an item already, just bounce
    if current_item != null:
        return
    
    # If we're not dealing with an item, then back out.
    if not node is MasterItem:
        return
    
    # Turn it into a visual item
    current_item = node._to_visual_item()
        
    # Remove the node fron it's own parent
    current_item.get_parent().remove_child(current_item)
    
    # COOL! Now, add the node as our child
    add_child(current_item)
    
    # Now, we do have just a bit more work to do - if the current item is 3D...
    if current_item._is_3D:
        # Rotate this 3D item to the item's preferred 3D orientation
        current_item.rotation_degrees = current_item._visualized_rotation_3D
        # Local transform goes to the specified offset
        current_item.translation = current_item._visualized_offset_3D
    # Otherwise...
    else:
        # Rotate this 2D item to the standard 2D orientation
        current_item.rotation_degrees = DEFAULT_ROTATION_2D
        # Local transform goes to zero
        current_item.translation = Vector3.ZERO

func drop_item():
    # This is the node that we'll attach the item (if we have an item to drop)
    var target_parent
    
    # If we don't have an item, just bounce
    if current_item == null:
        return
    
    # If we have a Level Interface core with an item node...
    if lic_node != null && lic_node.item_node != null:
        # Let's use that for our target parent
        target_parent = lic_node.item_node
        
    # Otherwise, let's do something stupid...
    else:
        # Very dumb assumption - since the core probably sits as an integrating
        # body in a scene, then our parent's parent is PROBABLY where the item
        # should go. It's TOO genius to NOT WORK!
        target_parent = get_parent().get_parent()
      
    # First, physicalize the node.
    var phys_node = current_item._to_physical_item()

    # Next, remove the current item from our children. This item is now detached
    # from the scene tree and is "free floating". 
    self.remove_child(current_item)
    
    # We don't want the physics item to flash back to the origin, so assert that
    # the item's global position matches the global position of this item core.
    phys_node.global_transform.origin = self.global_transform.origin
    
    # If the current item is a 3D item...
    if phys_node._is_3D:
        # We need to add in that 3D offset, since we're just at the item core's
        # origin
        phys_node.global_transform.origin += phys_node._visualized_offset_3D
        # Rotate this 3D item to what it WAS rotated at
        phys_node.rotation_degrees = phys_node._visualized_rotation_3D
    # Otherwise...
    else:
        # Rotate this 2D item to what it WAS rotated at
        phys_node.rotation_degrees = DEFAULT_ROTATION_2D
    
    # Move the item out there
    target_parent.add_child(phys_node)
    
    # Clear our tracker - it's out of our hands now!
    current_item = null
