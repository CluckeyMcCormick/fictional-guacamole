extends "res://motion_ai/common/tasking/actions/ActionTemplate.gd"

# The MR and PTR variables are declared in the ActionTemplate scene that exists
# above/is inherited by this scene 

# The target position that we're attempting to move to. Should be set (via code)
# by the parent task
var _target_position
# How many times have we gotten stuck and repathed as a result?
var _stuck_repath_count = 0

# What's the maximum number of times we'll let ourselves get stuck and perform a
# repath before we just throw in the towel and fail the action?
const MAX_STUCK_REPATH = 3

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
    # Connect the PhysicsTravelRegion functions
    PTR.connect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.connect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
    # We just got here - we've been stuck 0 times!
    _stuck_repath_count = 0
    
    # Path to our target entity
    path_to_target()

func _on_exit(var arg) -> void:
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
    
    # Clear any move data we had, since we're gonna be moving in a new
    # direction
    PTR.clear_target_data()
    
    # Generate a path to the target position!
    path = PIC.path_between(target.global_transform.origin, _target_position)
    
    # Now pass the path to our pathing region
    PTR.set_target_path(path, true)

    # If our path is empty...
    if not PTR.has_target_data():
        # Oh. Dang. That's a failure!
        emit_signal("action_failure", FC_NO_PATH)

func _on_phys_trav_region_path_complete(position):
    # We arrived. Hooray! That's a success!
    emit_signal("action_success")

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
