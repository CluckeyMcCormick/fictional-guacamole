tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# We need to communicate with the Physics Travel Region
onready var PTR = get_node("../../PhysicsTravelRegion")

const SAMPLE_ANGLE_INCREMENT = 45

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # If our machine root hasn't been configured (it happens unfortunately
    # often), then force the configuration
    if not MR._machine_configured:
        MR._force_configure()

    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Set the goal key
    MR.goal_key = "Flee"
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.connect("body_exited", self, "_on_sensory_sort_core_body_entered")
    
    # Connect the PhysicsTravelRegion functions
    PTR.connect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.connect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
    # Assign a random target point
    assign_target_position()

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")

    # Disconnect the PhysicsTravelRegion functions
    PTR.disconnect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.disconnect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Assign a random target 
func assign_target_position():
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    # Get our PathingInterfaceCore
    var PIC = MR.pathing_interface_core_node
    # Get our current target body
    var target = MR.target_body_node
    # Create a blank vector for us to add onto
    var move_vec = Vector3.ZERO
    
    # We'll stick the path variable in here
    var path
    
    # For each body we're actively tracking...
    for body in SSC.get_bodies(SSC.PRI_AREA.FOF, SSC.GC_THREAT):
        move_vec += body.global_transform.origin - target.global_transform.origin
    
    # So now we have a vector that basically points from the integrating body to
    # whatever it's trying to get away from. So, now we'll invert it so it
    # points AWAY!
    move_vec = -move_vec
    
    # Zero out the Y, since we're not bothering with that.
    move_vec.y = 0
    
    # Now, normalize it and then scale the normalization by our move distance
    # configurable
    move_vec = move_vec.normalized() * MR.flee_distance
    
    # Add it on to the integrating body's current position to create a target
    var point = target.global_transform.origin + move_vec
    
    # Path to the point
    path = PIC.path_between(target.global_transform.origin, point)
    
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
            angles.append(rad2deg( ang))
            angles.append(rad2deg(-ang))
        
        # Now, for each of those angles
        for ang in angles:
            # Create the alternate vector by rotating the move vector
            alt_vec = move_vec.rotated(Vector3.UP, PI / 2)
            # Add it on to the integrating body's current position to create a
            # target
            point = target.global_transform.origin + move_vec
            # Path to the point
            path = PIC.path_between(target.global_transform.origin, point)
            
            # If we actually have a path...
            if not path.empty():
                # SET IT!
                PTR.set_target_path(path, true)
                # Break!
                break
        
        # If we STILL don't have a path after ALL of that...
        if not PTR.has_target_data():
            # Oh. Dang. Nothing to do but go back to Idle I guess...
            change_state("GoalRegion/Idle")

func _on_phys_trav_region_path_complete(position):
    # Okay - if we're here then we haven't quite escaped whatever we're fleeing
    # from. Assign a new target position.
    assign_target_position()

func _on_phys_trav_region_error_goal_stuck(target_position):
    # Even if we're stuck, we must still be fleeing, so assign a new target
    # position
    assign_target_position()

# If a body enters our sensory range...
func _on_sensory_sort_core_body_entered(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area
    match priority_area:
        SSC.PRI_AREA.FOF:
            # If there's no threats left in the fight-or-flight area, we can go
            # back to the idle state.
            if not SSC.has_bodies(SSC.PRI_AREA.FOF, SSC.GC_THREAT):
                change_state("GoalRegion/Idle")
        _:
            pass

func _on_sensory_sort_core_body_exited(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area
    match priority_area:
        SSC.PRI_AREA.FOF:
            # If there's no threats left in the fight-or-flight area, we can go
            # back to the idle state.
            if not SSC.has_bodies(SSC.PRI_AREA.FOF, SSC.GC_THREAT):
                change_state("GoalRegion/Idle")
        _:
            pass
