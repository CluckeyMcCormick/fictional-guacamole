class_name MasterItem
extends RigidBody
tool

# What's the item's current state? Is it actively out it in the world, or is it
# being carried, or stored, or hidden away somewhere?
enum ItemState {INDEPENDENT, CARRIED, STOWED, HIDDEN}
# The configurable for controlling the item's state. The item's state has
# important implications for how it behaves in the wider game world.
export(ItemState) var item_state setget set_item_state

# --------------------------------------------------------
#
# Setters
#
# --------------------------------------------------------

func set_item_state(new_state):
    # Set the new state
    item_state = new_state
    # Assert the item state
    assert_item_state()

# --------------------------------------------------------
#
# Utility Functions
#
# --------------------------------------------------------

func assert_item_state():
    # Rather than updating the class variables individually, we'll set these "test"
    # variables according to the state. We'll then change the different class
    # variables appropriately. That'll save us on copy-paste code. 
    var detectable = true
    var collision_on = true
    var physics_move_on = true
    var state_rotation = Vector3.ZERO
    var is_visible = true

    print(item_state)
    print("\t", $RotationCore)

    match item_state:
        ItemState.INDEPENDENT:
            detectable = true
            collision_on = true
            physics_move_on = true
            state_rotation = $RotationCore.get_independent_rotation()
            is_visible = true
        
        ItemState.CARRIED:
            detectable = true
            collision_on = false
            physics_move_on = false
            state_rotation = $RotationCore.get_carried_rotation()
            is_visible = true
          
        ItemState.STOWED:
            detectable = true
            collision_on = false
            physics_move_on = false
            state_rotation = $RotationCore.get_stowed_rotation()
            is_visible = true

        ItemState.HIDDEN:
            detectable = true
            collision_on = false
            physics_move_on = false
            state_rotation = self.rotation_degrees # No rotational change
            is_visible = false
    
    # If we're detectable...
    if detectable:
        # Then we exist on the item layer
        self.collision_layer = 2048
    else:
        # Otherwise, we don't exist on any layer.
        self.collision_layer = 0
    
    # If we're colliding with stuff...
    if collision_on:
        # Collides with terrain and items
        self.collision_mask = 2049
    else:
        # Otherwise, collide with nothing
        self.collision_mask = 0
    
    # Set the Rigid Body state depending on whether physics is "on" or not
    if physics_move_on:
        self.mode = RigidBody.MODE_RIGID
    else:
        self.mode = RigidBody.MODE_STATIC
    
    # Assert rotation
    self.rotation_degrees = state_rotation
    
    # Visible!
    self.visible = is_visible
