extends "res://motion_ai/common/tasking/actions/core/ActionTemplate.gd"

# When we enter this state, we play a lead-in animation. What do we play
# as a lead in? If this is blank, then we immediately perform the attack.
export(String) var lead_in_animation_key = ""
# Once we make the attack, we play a lead-out animation. What do we play as a
# lead out? If this is blank, we immediately mark the action as complete.
export(String) var lead_out_animation_key = ""
# Does the animation we're using have directionality to it?
export(bool) var use_direction = true

# When we do a direct attack, we need to verify that the target is in range. We
# do a direct cast to the target's global origin - how long is that cast?
export(float) var direct_verify_distance = 0.5

# The target that we're trying to attack. Should be set programmatically by
# code. Depending on the type of attack, this should either be a physics object
# or a simple point in space.
var attack_target

# We have to make our attack in the physics processing state, meaning we have to
# yield processing until we're in that state. We'll use these variables to track
# the if thats happening or not.
var _attack_waiting = false
var _yielded_attack = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # Connect the "demand complete" function so we know when our animation is
    # finished
    MR.connect("demand_complete", self, "_on_demand_complete")
    
    # If we have a lead-in animation, play that and back out
    if lead_in_animation_key != "":
        MR.emit_signal(
            "demand_animation", lead_in_animation_key, 
            attack_target, use_direction
        )
        return
    
    # Do the attack
    _yielded_attack = do_attack()

func _on_update(var _delta) -> void:
    # If we don't have an attack waiting, back out
    if not _attack_waiting:
        return
    
    # Otherwise, process the attack
    _yielded_attack.resume()

func _on_exit(var arg) -> void:
    # Disconnect the "demand complete" function
    MR.disconnect("demand_complete", self, "_on_demand_complete")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_demand_complete(completed_animation_key):
    # If the animation key we were just passed matches our lead out key, then
    # the attack is complete. If lead-in and lead-out are the same this will
    # skip the attack but prevent an infinite loop - in other words, DON'T
    # DOUBLE UP THE ANIMATION KEYS.
    if completed_animation_key == lead_out_animation_key:
        emit_signal("action_success")
        
    # Otherwise, if the animation key we were just passed matches our lead in
    # key...
    elif completed_animation_key == lead_in_animation_key:
        # Then do the attack.
        _yielded_attack = do_attack()
        
    # Otherwise, something managed to play ahead of us. Since we cannot confirm
    # what the machine's current state is, we must fail the action.
    else:
        emit_signal("action_failure")

func do_attack():
    # Yield until we can query. Make note that we are waiting on an attack.
    _attack_waiting = true
    yield()
    
    # Okay, we're back. 
    _attack_waiting = false
    
    # Okay, we need to project from our current position to our target position.
    # We'll use this projection vector variable to store the result.
    var projection_vector
    # First, subtract our position from our target's position
    projection_vector = attack_target.global_transform.origin - target.global_transform.origin
    # Now, normalize the vector
    projection_vector = projection_vector.normalized()
    # Scale it by the verify distance
    projection_vector *= direct_verify_distance
    # Add the target's current position to create a point in space
    projection_vector += target.global_transform.origin
    
    # We should now be in the _physics_process, so we can query the world using
    # raycasts. First, let's get the space state.
    var space_state = target.get_world().direct_space_state
    # QUERY, QUERY, QUERY!
    var result = space_state.intersect_ray(
        target.global_transform.origin, # Project from our origin...
        projection_vector, # ...to our projected vector-point
        [target], # Node exclusion list - exclude our body
        3072 # Collision MASK - what to collide with. This marks collision with
             # Agents and Items
    )
    
    # If we got a result...
    if result:
        var collide_instance = instance_from_id(result.collider_id)
        print("HIT!")
        
        # If this object has a method for taking damage...
        if collide_instance.has_method("take_damage"):
            collide_instance.take_damage(25)
        
    else:
        print("No hit!")
    
    # If we don't have a lead out animation, then we have nothing to do.
    # Call that a success. 
    if lead_out_animation_key == "":
        emit_signal("action_success")
    # Otherwise, play the lead out animation.
    else:
        MR.emit_signal(
            "demand_animation", lead_out_animation_key, 
            attack_target, use_direction
        )
