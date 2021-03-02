extends "res://motion_ai/common/tasking/actions/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene 

# We're trying to get within range of a target, the range being based off a
# given priority area. Which priority area are we attempting to move in to?
export(SensorySortCore.PRI_AREA) var range_area
# The entity that we're attempting to range-in on. Should be set (via code) by
# the parent task
var _target_entity
# We'll wrap the above in a weak reference, just in case something goes awry
var _entity_wrap
# We'll save the position of the target entity, because we'll need to re-path if
# it moved!
var _entity_position
# How many times have we gotten stuck and repathed as a result?
var _stuck_repath_count = 0
# Did the action succeed? We only track this because there may be some timing
# oddness (i.e. race conditions) and we want everything to be nice and safe.
var _action_success = false

# What's the maximum deviation in the target entity's position that we'll allow
# before triggering a position deviation?
const MAX_POSITION_DEVIATION = 0.05

# What's the maximum number of times we'll let ourselves get stuck and perform a
# repath before we just throw in the towel and fail the action?
const MAX_STUCK_REPATH = 3

# F(ailure) C(ode) enumerator - used to tell our parent task why the action
# failed
enum {
    FC_LOST_ENTITY, # We lost track of the entity we were pathing to 
    FC_NO_DETECT, # We completed our path but failed to detect the entity
    FC_EXCESS_STUCK, # We got stuck too many times
    FC_NO_PATH # We weren't able to generate a path to the entity
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered", self, "_on_sensory_sort_core_body_entered")
    
    # Connect the PhysicsTravelRegion functions
    PTR.connect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.connect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
    # Wrap the target entity in a weak reference 
    _entity_wrap = weakref(_target_entity)
    
    # We just got here - we've been stuck 0 times!
    _stuck_repath_count = 0
    
    # Path to our target entity
    path_to_target()

func _on_update(delta) -> void:
    # If our target entity is gone, that's a failure!
    if _entity_wrap.get_ref() == null:
        emit_signal("action_failure", FC_LOST_ENTITY)
    
    var entity_shift = _target_entity.global_transform.origin - _entity_position
    
    # If the target entity has shifted...
    if abs(entity_shift.length()) > MAX_POSITION_DEVIATION:
        # Then it's time to re-path!
        path_to_target()

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    # Disconnect the PhysicsTravelRegion functions
    PTR.disconnect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.disconnect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func path_to_target():
    # Get our PathingInterfaceCore
    var PIC = MR.pathing_interface_core_node
    
    # The path we got out of the PathingInterfaceCore
    var path

    # Save the target entity's position
    _entity_position = _target_entity.global_transform.origin
    
    # Clear any move data we had, since we're gonna be moving in a new
    # direction
    PTR.clear_target_data()
    
    # Generate a path to the target entity!
    path = PIC.path_between(target.global_transform.origin, _entity_position)
    
    # Now pass the path to our pathing region
    PTR.set_target_path(path, true)

    # If our path is empty...
    if not PTR.has_target_data():
        # Oh. Dang. That's a failure!
        emit_signal("action_failure", FC_NO_PATH)

# If a body enters our sensory range...
func _on_sensory_sort_core_body_entered(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area
    if priority_area == range_area && body == _target_entity:
        # We succeeded! Mark success and inform the world!
        _action_success = true
        emit_signal("action_success")

func _on_phys_trav_region_path_complete(position):
    # If we already succeeded, then this doesn't matter. Back out!
    if _action_success:
        return
    # Wait. Did we arrive and not actually see the entity we wanted to see? That
    # seems bad. In fact, that's a failure - FC_NO_DETECT
    emit_signal("action_failure", FC_NO_DETECT)

func _on_phys_trav_region_error_goal_stuck(target_position):
    # We're stuck? Huh. Let's increment our counter...
    _stuck_repath_count += 1
    
    # If we haven't repathed too much, then might as well repath again!
    if _stuck_repath_count <= MAX_STUCK_REPATH:
        path_to_target()
    # Otherwise, we've repathed too much. Throw in the towel - this is a
    # failure!
    else:
        emit_signal("action_failure", FC_EXCESS_STUCK)  
