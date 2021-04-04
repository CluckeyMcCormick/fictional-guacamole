extends "res://motion_ai/common/tasking/actions/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene 

# F(ailure) C(ode) enumerator - used to tell our parent task why the action
# failed
enum {
    FC_NO_ITEM # We can't drop an item because we don't have an item to drop
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Dropping an item is easy! We'll just do that when we enter this state.
func _on_enter(var arg) -> void:
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # Clear any move data we had.
    PTR.clear_target_data()
    
    # If we don't have an item, we don't have anything to do. That's a failure!
    if not IMC.has_an_item():
        emit_signal("action_failure", FC_NO_ITEM)
    # If we do have an item, then drop it. That's a success!
    else:
        IMC.drop_item()
        emit_signal("action_success")
