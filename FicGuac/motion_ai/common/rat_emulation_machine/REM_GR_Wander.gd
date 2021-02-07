tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# We need to communicate with the Physics Travel Region
onready var PTR = get_node("../../PhysicsTravelRegion")

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
    MR.goal_key = "Wander"
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered_fof", self, "_on_sensory_sort_core_body_entered")
    SSC.connect("body_exited_fof", self, "_on_sensory_sort_core_body_entered")
    
    # Connect the PhysicsTravelRegion functions
    PTR.connect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.connect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
    # Assign a random target point
    assign_random_target()

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered_fof", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited_fof", self, "_on_sensory_sort_core_body_entered")

    # Disconnect the PhysicsTravelRegion functions
    PTR.disconnect("path_complete", self, "_on_phys_trav_region_path_complete")
    PTR.disconnect("error_goal_stuck", self, "_on_phys_trav_region_error_goal_stuck")
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing (and Other) Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Assign a random target 
func assign_random_target():
    # Get our PathingInterfaceCore
    var PIC = MR.pathing_interface_core_node
    
    # Start with a vector of fixed length
    var point = Vector3(1, 0, 0)
    
    # We'll stick the path variable in here
    var path
    
    # Spin the vector to give us a random angle
    point = point.rotated(Vector3.UP, deg2rad(randi() % 360))

    # Now, normalize it and then scale the normalization by our move distance
    # configurable
    point = point.normalized() * MR.move_distance
    
    # Add it on to the integrating body's current position
    point += target.global_transform.origin
    
    # Path to the point
    path = PIC.path_between(target.global_transform.origin, point)
    
    # Set the path to the random point
    PTR.set_target_path(path, true)
    
    # If our path is empty...
    if not PTR.has_target_data():
        # Oh. Dang. Nothing to do but go back to Idle I guess...
        change_state("GoalRegion/Idle")

func _on_phys_trav_region_path_complete(position):
    # The integrating body completed it's path. Hooray! Go to idle.
    change_state("GoalRegion/Idle")

func _on_phys_trav_region_error_goal_stuck(target_position):
    # We're stuck? Huh. Guess we should just go to idle anyway.
    change_state("GoalRegion/Idle")

# If a body enters our sensory range...
func _on_sensory_sort_core_body_entered(body):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    # If we have bodies, then FLEE!
    if SSC.has_bodies_fof():
        change_state("Flee")

func _on_sensory_sort_core_body_exited(body):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    # If we have bodies, then FLEE!
    if SSC.has_bodies_fof():
        change_state("Flee")
