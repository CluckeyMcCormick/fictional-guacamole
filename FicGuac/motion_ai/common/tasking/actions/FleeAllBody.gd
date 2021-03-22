extends "res://motion_ai/common/tasking/actions/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene 

# We're trying to flee all the bodies of a certain category in a specific
# priority area.
# What's the priority area?
export(SensorySortCore.PRI_AREA) var priority_area
# What kind of body are we trying to flee?
export(SensorySortCore.GROUP_CAT) var group_category

# When a body of the appropriate category enters the specified priority area, do
# we dynamically update the flee vector?
export(bool) var dynamic_flee_vector = false

# When we do flee, how far do we flee?
var flee_distance

# Did the action succeed? We only track this because there may be some timing
# oddness (i.e. race conditions) and we want everything to be nice and safe.
var _action_success = false

# How many times have we gotten stuck and repathed as a result?
var _stuck_repath_count = 0

# What's the maximum number of times we'll let ourselves get stuck and perform a
# repath before we just throw in the towel and fail the action?
const MAX_STUCK_REPATH = 3

# When we can't flee-path in a given direction, we rotate the flee vector
# positively and negatively until we find a valid vector (or we fail). How much
# does the angle change per each test (in degrees)?
const SAMPLE_ANGLE_INCREMENT = 45

# F(ailure) C(ode) enumerator - used to tell our parent task why the action
# failed
enum {
    FC_EXCESS_STUCK, # We got stuck too many times
    FC_NO_PATH # We weren't able to generate a path to the target position
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node

    # Connect the PhysicsTravelRegion functions
    PTR.connect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.connect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.connect("body_exited", self, "_on_sensory_sort_core_body_entered")
    
    # We just got here - we've been stuck 0 times!
    _stuck_repath_count = 0
    
    # If there's no bodies of the specified group category left in the
    # configured priority area
    if not SSC.has_bodies(priority_area, group_category):
        _action_success = true
        emit_signal("action_success")
    else:
        # Path to our target entity
        assign_flee_vector()

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node

    # Disconnect the PhysicsTravelRegion functions
    PTR.disconnect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.disconnect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")

    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func assign_flee_vector():
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    # Get our LevelInterfaceCore
    var LIC = MR.level_interface_core_node
    # Create a blank vector for us to add onto
    var move_vec = Vector3.ZERO
    
    # We'll stick the path variable in here
    var path
    
    # For each body we're actively tracking...
    for body in SSC.get_bodies(priority_area, group_category):
        # Create a vector from the target pointing TO the flee-category body,
        # then add that into our total move vector.
        move_vec += body.global_transform.origin - target.global_transform.origin
    
    # So now we have a vector that basically points from the integrating body to
    # whatever it's trying to get away from. So, now we'll invert it - thus the
    # vector points from the integrating body AWAY from whatever we're fleeing.
    move_vec = -move_vec
    
    # Zero out the Y, since we're not bothering with that.
    move_vec.y = 0
    
    # Now, normalize it and then scale the normalization by our move distance
    # configurable
    move_vec = move_vec.normalized() * flee_distance
    
    # Add it on to the integrating body's current position to create a target
    var point = target.global_transform.origin + move_vec
    
    # Path to the point
    path = LIC.path_between(target.global_transform.origin, point)
    
    # Set the path to the random point
    PTR.set_target_path(path, true)

    # If our path is empty...
    if not PTR.has_target_data():
        # Then were going to have to test variations on the move vector by
        # rotating it to different angles.

        # We'll build a list of different angular values, storing them in here        
        var angles = []
        # The alternate vector, made by rotating the move vector
        var alt_vec = Vector3.ZERO
        
        # First build out the angles in the order in which we will test them
        for ang in range(SAMPLE_ANGLE_INCREMENT, 180, SAMPLE_ANGLE_INCREMENT):
            # One in the positive direction,
            angles.append(rad2deg( ang))
            # One in the angular direction
            angles.append(rad2deg(-ang))
        
        # Now, for each of those angles
        for ang in angles:
            # Create the alternate vector by rotating the move vector
            alt_vec = move_vec.rotated(Vector3.UP, ang)
            # Add it on to the integrating body's current position to create a
            # target
            point = target.global_transform.origin + alt_vec
            # Path to the point
            path = LIC.path_between(target.global_transform.origin, point)
            
            # If we actually have a path...
            if not path.empty():
                # SET IT!
                PTR.set_target_path(path, true)
                # Break!
                break
        
        # If we STILL don't have a path after ALL of that...
        if not PTR.has_target_data():
            # Oh. Dang. That's a failed action right there!
            emit_signal("action_failure", FC_NO_PATH)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_phys_trav_region_path_complete(position):
    # If we already succeeded, then this doesn't matter. Back out!
    if _action_success:
        return
    # Okay - if we're here then we haven't quite escaped whatever we're fleeing
    # from. Assign a new target position.
    assign_flee_vector()

func _on_phys_trav_region_error_goal_stuck(target_position):
    # If we already succeeded, then this doesn't matter. Back out!
    if _action_success:
        return
    
    # We're stuck? Huh. Let's increment our counter...
    _stuck_repath_count += 1
    
    # If we haven't repathed too much, then might as well repath again!
    if _stuck_repath_count <= MAX_STUCK_REPATH:
        assign_flee_vector()
    # Otherwise, we've repathed too much. Throw in the towel - this is a
    # failure!
    else:
        emit_signal("action_failure", FC_EXCESS_STUCK)  
        
# If a body enters our sensory range...
func _on_sensory_sort_core_body_entered(body, pri_area, group_category):
    # If we already succeeded, then this doesn't matter. Back out!
    if _action_success:
        return
    
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area argument
    match pri_area:
        priority_area:
            # If there's no threats left in the fight-or-flight area, we can go
            # back to the idle state.
            if not SSC.get_bodies(priority_area, group_category):
                _action_success = true
                emit_signal("action_success")
            elif dynamic_flee_vector:
                assign_flee_vector()
        _:
            pass
# If a body exits our sensory range...
func _on_sensory_sort_core_body_exited(body, pri_area, group_category):
    # If we already succeeded, then this doesn't matter. Back out!
    if _action_success:
        return
    
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area argument
    match pri_area:
        priority_area:
            # If there's no threats left in the fight-or-flight area, we can go
            # back to the idle state.
            if not SSC.get_bodies(priority_area, group_category):
                _action_success = true
                emit_signal("action_success")
            elif dynamic_flee_vector:
                assign_flee_vector()
        _:
            pass
