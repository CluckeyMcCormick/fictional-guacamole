tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# We need to communicate with the Physics Travel Region
onready var PTR = get_node("../../PhysicsTravelRegion")

# This state is literally just the Pawn waiting around. We don't want the
# integrating body to stand still for too long, so we'll start a timer and then
# go back to the wandering state when we're done.
const IDLE_TIMER_NAME = "IdleTimeout"

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
    MR.goal_key = "Idle"
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.connect("body_exited", self, "_on_sensory_sort_core_body_entered")
    
    # Start a timer. Once this times out we'll move to the wander state
    self.add_timer(IDLE_TIMER_NAME, MR.idle_wait_time)
    
    # Clear any move data we had, since we're supposed to be idling
    PTR.clear_target_data()

func _on_timeout(name) -> void:
    # If the timer ends, then it's time to start wandering!
    match name:
        IDLE_TIMER_NAME:
            change_state("Wander")

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")
    
    # Stop any timers that could be happening
    self.del_timers()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Capture Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# If a body enters our sensory range...
func _on_sensory_sort_core_body_entered(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    # Get our ItemManagementCore
    var IMC = MR.item_management_core_node
    
    # Switch based on the priority area
    match priority_area:
        SSC.PRI_AREA_GENERAL:
            pass
        SSC.PRI_AREA_FOF:
            # If there's a threat in the fight-or-flight area, FLEE!
            if SSC.has_bodies(SSC.PRI_AREA_FOF, SSC.GC_THREAT):
                change_state("Flee")
        SSC.PRI_AREA_INTERACT:
            print("IDLE INTERACT! CAT: ", group_category)
            print("\t GC BE OF ", SSC.GC_GOAL)
            # If this body is a GOAL...
            if group_category == SSC.GC_GOAL:
                # THEN GRAB IT!!!!
                IMC.grab_item(body)
                print("GRABBED!")
        
        SSC.PRI_AREA_DANGER:
            pass
        _:
            pass

func _on_sensory_sort_core_body_exited(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area
    match priority_area:
        SSC.PRI_AREA_GENERAL:
            pass
        SSC.PRI_AREA_FOF:
            # If there's a threat in the fight-or-flight area, FLEE!
            if SSC.has_bodies(SSC.PRI_AREA_FOF, SSC.GC_THREAT):
                change_state("Flee")
        SSC.PRI_AREA_INTERACT:
            pass
        SSC.PRI_AREA_DANGER:
            pass
        _:
            pass
