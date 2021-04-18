extends "res://motion_ai/common/tasking/actions/core/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene.

# Do we drop all of the items at once, or drop them once-per-update cycle?
# Although once-per-cycle is slower, it may be more performance friendly.
export(bool) var all_items_at_once

# Have we already emitted a signal for this action? Used so that we don't double
# dip.
var _emitted = false

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Dropping an item is easy! We'll just do that when we enter this state.
func _on_enter(var arg) -> void:
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # We just got here - no way we've emitted anything yet!
    _emitted = false
    
    # Clear any move data we had. This makes it so that, when dropping an item,
    # we always stand still.
    PTR.clear_target_data()
    
    # If we don't have an item, then we don't have anything to drop. That's a
    # success in our book!
    if not IMC.has_an_item():
        # Mark that we have emitted stuff so we don't double emit
        _emitted = true
        # Okay, action succeeded! Emit!
        emit_signal("action_success")
    # Otherwise, if we're configured to drop everything at once...
    elif all_items_at_once:
        # Then drop everything
        while IMC.has_an_item():
            IMC.drop_item()
        # Mark that we have emitted stuff so we don't double emit
        _emitted = true
        # Okay, action succeeded! Emit!
        emit_signal("action_success")
        
func _on_update(delta) -> void:
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node

    # If we've already emitted, then there's nothing to do here. Break!
    if _emitted:
        return
    
    # Okay, so we haven't emitted yet. In that case, we definitely have at least
    # one item left. Drop it!
    IMC.drop_item()
    
    # If we don't have an item, then we did it. Hooray! Emit success.
    if not IMC.has_an_item():
        _emitted = true
        emit_signal("action_success")
