extends "res://motion_ai/common/tasking/core/TaskTemplate.gd"

# ArgKey - the list/Array of items we're trying to pick up
const AK_ITEMS_LIST = "items_list"
# ArgKey - the Vector3 position we'll attempt to move to before dropping the
# item(s) we're holding.
const AK_DROP_POSITION = "drop_position"

# How many times can we fail to grab something before we just give up?
const FAIL_GRAB_LIMIT = 3
# The list of item nodes we're going to try and grab. This list is actively used
# and modified as a method of progression tracking, so please don't mess with it
var _item_node_list = []
# Dictionary corresponding fail-to-grab event counts to the specific item.
var _fail_dict = {}
# Whether the task succeeds or not depends on whether or not we could grab all
# the items that got handed down to us.
var item_failed = false

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Task Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func specific_initialize(arg_dict):
    # Pass the item list down to the states that need it.
    _item_node_list = arg_dict[AK_ITEMS_LIST]
    
    # Pass the position down to the states that need it.
    $MoveToPosition._target_position = arg_dict[AK_DROP_POSITION]

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Preens the item list of any invalid/null item
func preen_item_list():
    # We'll use this to build a new list
    var working_list = []
    
    # Iterate through each item of our list
    for item in _item_node_list:
        # If the item no longer exists, exclude it.
        if weakref(item).get_ref() == null:
            item_failed = true
            continue
        # If the item has over-failed, exclude it. 
        if item in _fail_dict and _fail_dict[item] >= FAIL_GRAB_LIMIT:
            item_failed = true
            continue
        # Okay, looks like we can add this to our working list
        working_list.append(item)
    
    # Save the item list
    _item_node_list = working_list

# Sets the next item on our actions.
func set_next_item():
    # Get the position of our integrating body.
    var body_pos = target.global_transform.origin
    # We'll use these to track the closest items
    var closest_item = null
    var closest_distance = INF
    
    # Clear the target entity
    $MoveToEntityPriorityArea._target_entity = null
    $GrabItem._target_entity = null
    
    # If we don't have an item to get...
    if _item_node_list.empty():
        # Back out, I suppose.
        return
    
    # Otherwise, we need to find the item in the list that's closest to the
    # integrating body. We'll assume the list has already been preened (see the
    # preen_item_list() function)
    for item in _item_node_list:
        # Calculate the distance from the current item to our target body
        var curr_distance = (body_pos - item.global_transform.origin).length()
        # If the distance is closer-than-our-closest, set the current values to
        # the closest.
        if curr_distance < closest_distance:
            closest_item = item
            closest_distance = curr_distance
    
    # Now that we've got an item, pass that down to the Move/Grab actions
    $MoveToEntityPriorityArea._target_entity = closest_item
    $GrabItem._target_entity = closest_item
    
    # Erase the closest item from the item node list. Unless something goes
    # awry, this should stop duplicate move actions.
    _item_node_list.erase(closest_item)

# This function is meant to be called during item collection - i.e. when we need
# to decide what to do. This function handles preparing the states and
# transition to the appropriate state.
func collect_item_next_handler():
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # See if we have items, and if we can grab items. 
    var has_items = IMC.has_an_item()
    var can_grab_any = IMC.can_grab_item()
    
    # If we have items, and we can't grab another...
    if has_items and not can_grab_any:
        # Then we need to move to the drop-off spot.
        change_state("MoveToPosition")
        return
        
    # Otherwise, we either don't have items, or we can grab items. Same thing
    # from our perspective. First, let's preen the list.
    preen_item_list()
    # Set the next item
    set_next_item()
    
    # Right, so we've preened the list and set the item. Now, let's think about
    # what we can do: if the preen and set gave us an item...
    if $MoveToEntityPriorityArea._target_entity != null:
        # Then that means we have more work to do. If we're currently IN the
        # Move-To-Entity state, then we need to do a simulated reset on that
        # state
        if get_active_substate() == $MoveToEntityPriorityArea:
            $MoveToEntityPriorityArea.simulated_reset()
        # Otherwise, we need to change to that move state
        else:
            change_state("MoveToEntityPriorityArea")
    
    # Otherwise...
    else:
        # If the preen and set gave us nothing, then the list is actually done.
        # We've got everything. And, in that case, we just need to move and drop
        # items - if we have them!
        if has_items:
            change_state("MoveToPosition")
        # Otherwise, it seems like we succeeded...
        else:
            # Okay - if we couldn't pick up at least one item, we'll call that a
            # soft fail.
            if item_failed:
                emit_signal("task_failed")
            # Otherwise, we got everything we wanted. Yay! Hard success!
            else:
                emit_signal("task_succeeded")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### ~~~~~~~~~~~~~~~~ Setup States

# I don't think the "Drop All" function can technically fail. However, we keep
# it here as a precaution.
func _on_PreDropAllItem_action_failure(failure_code):
    # We failed? Doesn't matter, defer to the handler function
    collect_item_next_handler()

func _on_PreDropAllItem_action_success():
    # We did it. Hooray! Defer to the handler function.
    collect_item_next_handler()

### ~~~~~~~~~~~~~~~~ Collection States

func _on_MoveToEntityPriorityArea_action_failure(failure_code):
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # Okay, so we weren't able to move to the item. Hmmm. Could be for any
    # number of reasons. For now, we don't really care why exactly. Let's just
    # mark that this item had an issue.
    if not $MoveToEntityPriorityArea._target_entity in _fail_dict:
        _fail_dict[$MoveToEntityPriorityArea._target_entity] = 1
    else:
        _fail_dict[$MoveToEntityPriorityArea._target_entity] += 1
    
    # Add that target entity back in to the rotation - if it's invalid it will
    # get preened out.
    _item_node_list.append($MoveToEntityPriorityArea._target_entity)
    
    # Defer to the handler function
    collect_item_next_handler()
    
func _on_MoveToEntityPriorityArea_action_success():
    # We're in range of the item. Hooray! Move to the GrabItem state!
    change_state("GrabItem")

func _on_GrabItem_action_failure(failure_code):
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # Okay, so we weren't able to grab the item. Odd. As before, we don't really
    # care why exactly. We'll just mark that we had an issue.
    if not $GrabItem._target_entity in _fail_dict:
        _fail_dict[$GrabItem._target_entity] = 1
    else:
        _fail_dict[$GrabItem._target_entity] += 1
    
    # Add that target entity back in to the rotation - if it's invalid it will
    # get preened out.
    _item_node_list.append($GrabItem._target_entity)
    
    # Defer to the handler function
    collect_item_next_handler()

func _on_GrabItem_action_success():
    # We've got an item, eh? Defer to the handler function, then.
    collect_item_next_handler()

### ~~~~~~~~~~~~~~~~ Item Drop States

func _on_MoveToPosition_action_failure(failure_code):
    # If we couldn't reach the drop point, call that a task failure
    emit_signal("task_failed")

func _on_MoveToPosition_action_success():
    # Yay! We reached where we wanted to be. Move to the drop item state
    change_state("DropAllItem")

# I don't think the "Drop All" function can technically fail. However, we keep
# it here as a precaution.
func _on_DropAllItem_action_failure(failure_code):
    # Defer to the handler function
    collect_item_next_handler()

func _on_DropAllItem_action_success():
    # Defer to the handler function
    collect_item_next_handler()
