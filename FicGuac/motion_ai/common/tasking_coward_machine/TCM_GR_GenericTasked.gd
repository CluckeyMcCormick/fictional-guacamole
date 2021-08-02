tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# We need to communicate with the Physics Travel Region
onready var PTR = get_node("../../PhysicsTravelRegion")

# We also need to communicate with the Task Manager Region
onready var TMR = get_node("../../TaskManagerRegion")

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
    
    # We don't set the attitude hint here; we'll just inherit it from wherever
    # we came from.
    
    # Connect the SensorySortCore functions
    SSC.connect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.connect("body_exited", self, "_on_sensory_sort_core_body_entered")
    
    # Connect the TaskManagerRegion functions
    TMR.connect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.connect("current_task_failed", self, "_on_tmr_current_task_failed")
    
    # Our argument is a task that has already been specifically initialized; it
    # now just needs to be task initialized. DO SO!
    arg.template_initialize(MR, PTR, MR.integrating_body_node)
    # Add the task to the task manager
    TMR.set_new_task(arg)

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")
  
    # Disconnect the TaskManagerRegion functions
    TMR.disconnect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.disconnect("current_task_failed", self, "_on_tmr_current_task_failed")

    # Remove the current task - just in case!
    TMR.remove_current_task()

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
        SSC.PRI_AREA.FOF:
            # If we're not fleeing then we're all done here. Back out!
            if not MR.flee_behavior:
                return
            # If there's a threat in the fight-or-flight area, FLEE!
            if SSC.has_bodies(SSC.PRI_AREA.FOF, SSC.GROUP_CAT.THREAT):
                change_state("Flee")
        _:
            pass
# If a body exits our sensory range...
func _on_sensory_sort_core_body_exited(body, priority_area, group_category):
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Switch based on the priority area
    match priority_area:
        SSC.PRI_AREA.FOF:
            # If we're not fleeing then we're all done here. Back out!
            if not MR.flee_behavior:
                return
            # If there's a threat in the fight-or-flight area, FLEE!
            if SSC.has_bodies(SSC.PRI_AREA.FOF, SSC.GROUP_CAT.THREAT):
                change_state("Flee")
        _:
            pass

# If the current task succeeds...
func _on_tmr_current_task_succeeded(task):
    print("Task SUCCEEDED!")
    # We succeeded! Hooray! Back to idle.
    change_state("Idle")
    
# If the current task fails...
func _on_tmr_current_task_failed(task):
    print("Task FAILED!")
    # We failed? Oh well. Back to idle.
    change_state("Idle")

