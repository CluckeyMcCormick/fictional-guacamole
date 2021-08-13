class_name MasterItem
extends RigidBody

# Items in this game have two states:
#   - physical, where they move about and collide as you would expect real
#     objects to do
#   - visual, where they don't collide with anything and also don't have physics
# The enumeration will help us keep these different modes straight.
enum {ITEM_PHYSICAL, ITEM_VISUAL}

# The item's current state is tracked by this var. We start in the physical
# mode. You can read this variable, but please don't touch it. Please!!!
var _item_state = ITEM_PHYSICAL

# The item's unique name key. Used to both display the item and identify items
# of a consistent type. Please, for the love of god, do not change this at run
# time. I guess you could but I'm asking very nicely that you DO NOT!
export(String) var name_key

# The max count of these items that may be stacked up for carrying purposes
export(int, 1, 1024) var max_carry_stack = 1

# Is the visual component of this item 3D - i.e. does it consist of a mesh or
# some other such object? This enables special behaviors for how we handle this
# visual instance.
export(bool) var _is_3D = false
# The initial positional offset (when in visual item mode) of this item IF this
# item is 3D. This allows for appropriate shifting for items - for example, so
# that a box doesn't clip into an NPC's head
export(Vector3) var _visualized_offset_3D = Vector3.ZERO
# The space between individual items of this instance when they are stacked IF
# this item is 3D.
export(Vector3) var _stack_space_3D = Vector3.ZERO
# The initial rotation (when in visual item mode) of this item IF this item is
# 3D. Important for items that may have odd sizes. Angles are in degrees.
export(Vector3) var _visualized_rotation_3D = Vector3(0, 45, 0)

# When an item switches to the visual only mode, it loses any-and-all collision.
# The collision layers and masks are saved in here until we become physical,
# when they reassert themselves.
var _layer_cache
var _mask_cache

# --------------------------------------------------------
#
# Utility Functions
#
# --------------------------------------------------------

func _to_visual_item():  
    # If we're already a visual item, return our self
    if _item_state == ITEM_VISUAL:
        return self
    
    # Become a static (no physics) body
    self.mode = RigidBody.MODE_STATIC
    
    # Capture the collision layer and the collision mask
    _layer_cache = self.collision_layer
    _mask_cache = self.collision_mask
    
    # Clear the collision layer and mask
    self.collision_layer = 0
    self.collision_mask = 0
    
    # We have entered VISUAL MODE
    _item_state = ITEM_VISUAL
    
    return self

func _to_physical_item():

    # If we're already a physical item, return our self
    if _item_state == ITEM_PHYSICAL:
        return self

    # Reassert the collision layer and mask
    self.collision_layer = _layer_cache
    self.collision_mask = _mask_cache
    
    # Become a rigid (physics) body
    self.mode = RigidBody.MODE_RIGID
    
    # Chances are, while we were set to visual mode, we were sleeping. Need to
    # assert that this is no longer true
    self.sleeping = false

    # We have entered PHYSICAL MODE
    _item_state = ITEM_PHYSICAL

    return self

func take_damage(amount):
    print("Took Damage: ", amount)
