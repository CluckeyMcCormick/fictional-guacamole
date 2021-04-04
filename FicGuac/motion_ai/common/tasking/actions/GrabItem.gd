extends "res://motion_ai/common/tasking/actions/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene 

# The entity that we're attempting to grab. Should be set (via code) by the
# parent task
var _target_entity

# F(ailure) C(ode) enumerator - used to tell our parent task why the action
# failed
enum {
    FC_CANT_GRAB_ITEM, # We can't grab an item, for some reason
    FC_NULL_ENTITY, # The target entity we're trying to grab was null!
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Grabbing an item is easy! We'll just do that when we enter this state.
func _on_enter(var arg) -> void:
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # Wrap the target in a weak reference
    var target_wrap = weakref(_target_entity)
    
    # Clear any move data we had.
    PTR.clear_target_data()
    
    # If we don't have an item, we don't have anything to do. That's a failure!
    if not IMC.can_grab_item(_target_entity):
        emit_signal("action_failure", FC_CANT_GRAB_ITEM)
    elif target_wrap.get_ref() == null:
        emit_signal("action_failure", FC_NULL_ENTITY)
    # If we do have an item, then drop it. That's a success!
    else:
        IMC.grab_item(_target_entity)
        emit_signal("action_success")
