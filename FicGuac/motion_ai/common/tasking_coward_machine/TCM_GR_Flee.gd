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

# Preload our fleeing task so we can instance it on demand
var FLEE_TASK_PRELOAD = preload("res://motion_ai/common/tasking/FleeImmediateThreat.tscn")

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
    
    # Set the goal key
    MR.goal_key = "Flee"
    
    # Since the Flee task doesn't succeed UNTIL the threat has left our specific
    # priority area, there's no need to connect up to the SensorySortCore. 

    # Connect the TaskManagerRegion functions
    TMR.connect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.connect("current_task_failed", self, "_on_tmr_current_task_failed")

    # Instance out a new flee task.
    var new_flee = FLEE_TASK_PRELOAD.instance()
    # Create the argument dict
    var argdict = {
        new_flee.AK_FLEE_DISTANCE: MR.wander_distance
    }
    # Initialize!
    new_flee.initialize(MR, PTR, MR.integrating_body_node, argdict)
    # Add the task to the task manager. This will clear out any existing tasks.
    TMR.set_new_task(new_flee)

func _on_exit(var arg) -> void:
    # Disconnect the TaskManagerRegion functions
    TMR.disconnect("current_task_succeeded", self, "_on_tmr_current_task_succeeded")
    TMR.disconnect("current_task_failed", self, "_on_tmr_current_task_failed")
 
    # Remove the current task - just in case!
    TMR.remove_current_task()
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Processing Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_tmr_current_task_succeeded(task):
    # We succeeded! Go back to the idle state - there are no threats here!
    change_state("Idle")

func _on_tmr_current_task_failed(task):
    # We failed? Oh well.... THAT'S SOMETHING THAT DOING THE EXACT SAME THING
    # AGAIN WOULD DEFINITELY FIX! Instance out a new flee task!
    var new_flee = FLEE_TASK_PRELOAD.instance()
    # Create the argument dict
    var argdict = {
        new_flee.AK_FLEE_DISTANCE: MR.wander_distance
    }
    # Initialize!
    new_flee.initialize(MR, PTR, MR.integrating_body_node, argdict)
    # Add the task to the task manager
    TMR.set_new_task(new_flee)


