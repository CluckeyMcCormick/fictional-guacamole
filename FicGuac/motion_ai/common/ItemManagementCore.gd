extends Position3D

# When we grab an item, we rotate it.
# To what angles (in degrees) do we rotate 2D items?
const DEFAULT_ROTATION_2D = Vector3(-90, 45, 0)

# How much spacing do we put between each item, when stacking, if an item is 2D?
# For 3D items we use fields on the MasterItem class
const STACK_SPACE = Vector3(0, 0.05, 0)

# The stack of items we're holding on to.
var _item_stack = []

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
        
    # If we're not in the engine, get the node
    if not Engine.editor_hint:
        lic_node = get_node(level_interace_core)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ready():
    # If we have a level interface core...
    if level_interace_core:
        # Get it! This may not have been resolved yet, since this node may have
        # not been in the scene tree before now
        lic_node = get_node(level_interace_core)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Core functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Does this item management core have at least one item? While we could just
# reach down and do this check manually, I wanted a function to do this so we
# could be explicit about what we're doing without including a comment.
func has_an_item():
    return not _item_stack.empty()

# Can this item management core grab the item in question?
func can_grab_item(node : MasterItem):
    
    # If we don't have any items, then we can surely grab an item.
    if not has_an_item():
        return true
    # Otherwise, If we are at max capacity for our current item stack, return
    # false.
    elif node.max_carry_stack >= _item_stack[0].max_carry_stack:
        return false
    # Okay, so we're below max capacity and can grab another item. In that case,
    # we can grab the item so long as the name keys match up with each other.
    else:
        return node.name_key == _item_stack[0].name_key

func grab_item(node : MasterItem):
    # The current item we're working with
    var current_item
    
    # The new translation of the item. This can be a bit tricky, so we're gonna
    # calculate it in this variable
    var new_trans
    
    # If we have an item already, just bounce
    if not can_grab_item(node):
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
    
    # And stick it on the stack!
    _item_stack.append(current_item)
    
    # Now, we do have just a bit more work to do - if the current item is 3D...
    if current_item._is_3D:
        # Rotate this 3D item to the item's preferred 3D orientation
        current_item.rotation_degrees = current_item._visualized_rotation_3D
        
        # The new translation is the 3D visual offset - PLUS the stack spacing
        # variable (minus 1, so that the first item appears at the bottom of the
        # stack).
        new_trans = current_item._visualized_offset_3D
        new_trans += current_item._stack_space_3D * ( _item_stack.size() - 1 )
        
        # Local transform goes to the specified offset
        current_item.translation = new_trans
    # Otherwise...
    else:
        # Rotate this 2D item to the standard 2D orientation
        current_item.rotation_degrees = DEFAULT_ROTATION_2D
        
        # The new translation is the stack space, multiplied by the place in the
        # stack (minus one - so the bottom stack item aligns with this node)
        current_item.translation = STACK_SPACE * ( _item_stack.size() - 1 )

func drop_item():
    # This is the node that we'll attach the item (if we have an item to drop)
    var target_parent
    
    # The current item we're working with
    var current_item
    
    # The stack translation of the item - where this item was in realspace when
    # it was in the stack. This makes items appear to magically "physicalize"
    # off the stack.
    var stack_trans
    
    # If we don't have an item, just bounce
    if not has_an_item():
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
    
    # First, pop the top item node off the stack
    current_item = _item_stack.pop_back()
    
    # Next, remove the current item from our children. This item is now detached
    # from the scene tree and is "free floating". 
    self.remove_child(current_item)
    
    # Move the item out there
    target_parent.add_child(current_item)
    
    # We don't want the physics item to flash back to the origin, so assert that
    # the item's global position matches the global position of this item core.
    current_item.global_transform.origin = self.global_transform.origin
    
    # If the current item is a 3D item...
    if current_item._is_3D:
        # Rotate this 3D item to what it WAS rotated at
        current_item.rotation_degrees = current_item._visualized_rotation_3D
        
        # The stack translation is the 3D visual offset - PLUS the stack spacing
        # variable. We do not subtract 1 since we JUST popped this item off of
        # the stack.
        stack_trans = current_item._visualized_offset_3D
        stack_trans += current_item._stack_space_3D * _item_stack.size()
        
    # Otherwise...
    else:
        # Rotate this 2D item to what it WAS rotated at
        current_item.rotation_degrees = DEFAULT_ROTATION_2D
    
        # The stack translation is the stack spaceing variable, multiplied by
        # the place in the stack. We do not subtract one because we want the
        # position we just popped from the stack.
        stack_trans = STACK_SPACE * _item_stack.size()
    
    # Shift the item by the stack translation
    current_item.global_transform.origin += stack_trans

    # Finally, physicalize the node.
    current_item = current_item._to_physical_item()
