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

# Preload our item moving task so we can instance it on demand
var MOVE_ITEM_TASK_PRELOAD = preload("res://motion_ai/common/tasking/MoveItemDrop.tscn")

# The item we're trying to pick up
var item
# The position we're trying to move to
var final_pos

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
    
    # Connect the TaskManagerRegion functions
    TMR.connect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.connect("current_task_failed", self, "_on_tmr_current_task_failed")
    
    # Instance out a new wander task.
    var new_move_item = MOVE_ITEM_TASK_PRELOAD.instance()
    # Initialize!
    new_move_item.initialize(MR, PTR, MR.integrating_body_node, item, final_pos)
    # Add the task to the task manager
    TMR.set_new_task(new_move_item)

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")
  
    # Disconnect the TaskManagerRegion functions
    TMR.disconnect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.disconnect("current_task_failed", self, "_on_tmr_current_task_failed")
  
    # Clear the target item
    item = null
    
    # Clear the final position
    final_pos = null

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
            # If there's a threat in the fight-or-flight area, FLEE!
            if SSC.has_bodies(SSC.PRI_AREA.FOF, SSC.GROUP_CAT.THREAT):
                change_state("Flee")
        _:
            pass

# If the current task succeeds...
func _on_tmr_current_task_succeeded(task):
    print("Move task SUCCEEDED!")
    # We succeeded! Hooray! Back to idle.
    change_state("Idle")
    
# If the current task fails...
func _on_tmr_current_task_failed(task):
    print("Move task FAILED!")
    # We failed? Oh well. Back to idle.
    change_state("Idle")

