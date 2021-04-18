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

# Preload our random wandering task so we can instance it on demand
var WANDER_TASK_PRELOAD = preload("res://motion_ai/common/tasking/WanderRandom.tscn")

# This state is either the body standing still or wandering in a random
# direction. When we're not wandering, we're idling. We don't want the
# integrating body to stand still for too long, so we'll start a timer and then
# start another wandering task when we're done.
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
    
    # Connect the TaskManagerRegion functions
    TMR.connect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.connect("current_task_failed", self, "_on_tmr_current_task_failed")
    
    # Connect to the Machine Root's "Task Assigned" function
    MR.connect("move_task_assigned", self, "_on_move_task_assigned")
    
    # Instance out a new wander task.
    var new_wander = WANDER_TASK_PRELOAD.instance()
    # Initialize!
    new_wander.initialize(MR, PTR, MR.integrating_body_node, MR.wander_distance)
    # Add the task to the task manager
    TMR.set_new_task(new_wander)

func _on_timeout(name) -> void:
    # If the timer ends, then it's time to start wandering!
    match name:
        IDLE_TIMER_NAME:
            # Instance out a new wander task.
            var new_wander = WANDER_TASK_PRELOAD.instance()
            # Initialize!
            new_wander.initialize(MR, PTR, MR.integrating_body_node, MR.wander_distance)
            # Add the task to the task manager
            TMR.set_new_task(new_wander)

func _on_exit(var arg) -> void:
    # Get our SensorySortCore
    var SSC = MR.sensory_sort_core_node
    
    # Disconnect the SensorySortCore functions
    SSC.disconnect("body_entered", self, "_on_sensory_sort_core_body_entered")
    SSC.disconnect("body_exited", self, "_on_sensory_sort_core_body_entered")
  
    # Disconnect the TaskManagerRegion functions
    TMR.disconnect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.disconnect("current_task_failed", self, "_on_tmr_current_task_failed")
  
    # Disconnect to the Machine Root's "Task Assigned" function
    MR.disconnect("move_task_assigned", self, "_on_move_task_assigned")

    # Remove the current task - just in case!
    TMR.remove_current_task()
       
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
    # We succeeded! Hooray! Destroy the task!
    TMR.remove_current_task()
    # Stop any timers that could be happening
    self.del_timers()
    # Start a timer. Once this times out we'll put another random wandering task
    # into the task manager
    self.add_timer(IDLE_TIMER_NAME, MR.idle_wait_time)
    
# If the current task fails...
func _on_tmr_current_task_failed(task):
    # We failed? Oh well. Remove the current task.
    TMR.remove_current_task()
    
    # Stop any timers that could be happening
    self.del_timers()
    # Start a timer. Once this times out we'll put another random wandering task
    # into the task manager
    self.add_timer(IDLE_TIMER_NAME, MR.idle_wait_time)

func _on_move_task_assigned(items, final_pos):
    # Set the item
    get_node("../MoveTasked").items = items
    # Set the final position
    get_node("../MoveTasked").final_pos = final_pos
    # Change to the tasking state
    change_state("MoveTasked")
