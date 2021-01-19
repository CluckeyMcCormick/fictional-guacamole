tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter() -> void:
    MR.readable_state = "Walk"

func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Did we get a collision result from our most recent move attempt?
    var collision = null

    # If we don't have a target position...
    if not MR.target_position:
        # Then let's see get the next point path (if we have a path!)
        if not MR.target_path.empty():
            MR.target_position = MR.target_path.pop_front()
        # Otherwise
        else:
            change_state("Idle")
            return

    # How far are we from our target position?
    var distance_to = MR.target_position - KC.get_adj_position()
    # We really only care about the X and Z, so we're gonna zero out the y
    # distance left - since we currently can't purposefully or explicitly move 
    # up or down.
    distance_to.y = 0
    
    # Normalizing reduces the Vector such that we can easily scale it - it's
    # basically just the direction now.
    var normal_dist = distance_to.normalized()
    
    # Now for something a bit more wacky - we don't want to overshoot our
    # target, so we'll fine-tune our values.
    # First, let's calculate how far we'll move on x and z in total.
    var projected_travel = normal_dist.length() * KC.move_speed * delta
    
    # If we're projected to move straight past the goal...
    if projected_travel > distance_to.length():
        # In that case, we only want to move an exact amount. Since our
        # movement is always multiplied by (move_speed * delta), we can
        # calculate the exact values we'll need for normal_dist by dividing
        # out that factor from the remaining distance.
        normal_dist.x = distance_to.x / (KC.move_speed * delta)
        normal_dist.z = distance_to.z / (KC.move_speed * delta)
        
    # Finally, set our final x & z values
    var x = normal_dist.x * KC.move_speed
    var z = normal_dist.z * KC.move_speed
    
    # Do the move!
    collision = target.move_and_collide(Vector3(x, 0, z) * delta)
    
    # Update our "current orientation"
    MR._curr_orient.x = x
    MR._curr_orient.z = z
    
    # If we collided with something, and we still have a ways to go...
    if collision and collision.remainder.length() != 0:
        # Get the remaining movement
        var next_movement = collision.remainder

        # Slide along the normal
        next_movement = next_movement.slide( collision.normal )
        # Normalize it
        next_movement = next_movement.normalized()
        # Scale it to the length of the previous remaining movement
        next_movement = next_movement * collision.remainder.length()
        # Now move and colide along that scaled angle
        target.move_and_collide(next_movement)
    
    # Otherwise, broadcast that we need to update the visuals of whoever is
    # listening
    MR.emit_signal("visual_update", "walk", MR._curr_orient)

func _after_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node

    # If we don't have a target position...
    if not MR.target_position:
        # Then let's see get the next point path (if we have a path!)
        if not MR.target_path.empty():
            MR.target_position = MR.target_path.pop_front()
        # Otherwise
        else:
            change_state("Idle")
            return

    # Calculate the remaining distance to our objective
    var remain_length = ( MR.target_position - KC.get_adj_position() ).length()

    # If we're close enough to that target position...
    if remain_length <= KC.goal_tolerance:
        # ...then we're done here! Save the target position
        var pos_save = MR.target_position
        # Clear the target
        MR.target_position = null
        
        # Now that we've done that we, need to check 
        if not MR.target_path.empty():
            MR.target_position = MR.target_path.pop_front()
        # Otherwise
        else:
            # Now emit the "path complete" signal using the position we saved.
            # It's important we do it this way, since anything receiving the
            # signal could change the variable out from under us.
            MR.emit_signal("path_complete", pos_save)
