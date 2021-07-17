tool
extends Node

# Preload our item moving task so we can instance it on demand
const MOVE_ITEMS_TASK_PRELOAD = preload("res://motion_ai/common/tasking/MoveItemDropMulti.tscn")

# Every AI machine has an integrating body - the body that will be moved to and
# from with this machine.
export(NodePath) var integrating_body
# We resolve the node path into this variable.
var integrating_body_node

# We need a Kinematic Core so that we know how fast to move, how low to float,
# which way is down and fast to be down, etc etc.
export(NodePath) var kinematic_core
# We resolve the node path into this variable.
var kinematic_core_node

# We also need a Sensory Sort Core so that we can react to the world around us
# (i.e. physics bodies).
export(NodePath) var sensory_sort_core
# We resolve the node path into this variable.
var sensory_sort_core_node

# We also need a Level Interface Core so we can interface with different
# elements of the current level
export(NodePath) var level_interface_core
# We resolve the node path into this variable.
var level_interface_core_node

# This Item Management Core will help us handle our items.
export(NodePath) var item_management_core
# We resolve the node path into this variable.
var item_management_core_node

# This Character Stats Core will help us handle our items.
export(NodePath) var character_stats_core
# We resolve the node path into this variable.
var character_stats_core_node

# How long do we idle for before we transition to the wandering state?
export(float, 0.0, 6.0) var idle_wait_time = 1.0

# When this machine is wandering, how far does it wander? 
export(int, 1, 10) var wander_distance = 5

# When the machine is fleeing, how far does it flee (before recorrecting it's
# position)?
export(float, .1, 10) var flee_distance = 1.0

# The current orientation vector. It is purely for expressing which way the pawn
# is looking/moving. Mostly inteded to help set the appropriate animation and/or
# visual appearance.
var _curr_orient = Vector3.ZERO

# String for our current physics travel state. Used for animation purposes, but
# also used for debugging.
var physics_travel_key = ""

# String for our current goal state. Used for debugging, but also occassionally
# utilized for animation purposes.
var goal_key = ""

# Okay, so the machine can get stuck in a chicken-and-egg situation with regards
# to configuration. The children states require access to several
# variables/nodes that SHOULD be setup in the _ready function of this script.
# However, our underlying state_root script calls the appropriate _on_enter
# functions for our default nodes. These then reference the aformentioned
# variables, RUINING EVERYTHING. To get around this, our configuration is
# performed in a different function, and whether we have configured or not is
# tracked by this variable.
var _machine_configured = false

# This is a signal unique to the TaskingCowardMachine, since it was designed to
# accept input directly via code. The signal indicates the machine has been
# given a specific task to perform. Should only really be used (received) by one
# of the region's sub-machines.
signal task_assigned(task)

# This signal fires when a task fails or succeeds. This is also unique to the
# TaskingCowardMachine, since a fully fledged instance a machine should handle
# task completion internally.  
signal task_complete_echo()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# We can make this _ready function without worrying about the underlying state
# code. That will get called after this function.
func _ready():
    # Back out if we're in the engine - this scene has to be a tool, so we're
    # gonna need to sidestep some dumb errors.
    if Engine.editor_hint:
        return
    
    # If the machine isn't configured, then configure it!
    if not _machine_configured:
        _force_configure()   

func _force_configure():
    
    # Get all the nodes
    integrating_body_node = get_node(integrating_body)
    kinematic_core_node = get_node(kinematic_core)
    sensory_sort_core_node = get_node(sensory_sort_core)
    level_interface_core_node = get_node(level_interface_core)
    item_management_core_node = get_node(item_management_core)
    character_stats_core_node = get_node(character_stats_core)

    # The target has to be a KinematicBody
    assert(typeof(integrating_body_node) == typeof(KinematicBody), "Integrating Body must be a KinematicBody node!")
    # Also, we need a KinematicCore
    assert(kinematic_core_node != null, "A KinematicCore node is required!")
    # AAAAAND a we need a SensorySortCore
    assert(sensory_sort_core_node != null, "A SensorySortCore node is required!")
    # Can't forget the Level Interface Core!
    assert(level_interface_core_node != null, "A LevelInterfaceCore node is required!")
    # The Item Management Core ALSO needs to be here
    assert(item_management_core_node != null, "An ItemManagementCore node is required!")
    # We would be ABSOLUTELY NOWHERE without the Character Stats Core!
    assert(character_stats_core_node != null, "A CharacterStatsCore node is required!")
    
    # Machine is configured!
    _machine_configured = true

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Order the machine to move an item to a specified position
func move_items(items, final_pos):
    var move_task = MOVE_ITEMS_TASK_PRELOAD.instance()
    var arg_dict = {}
    
    # Create the arg_dict
    arg_dict[move_task.AK_ITEMS_LIST] = items
    arg_dict[move_task.AK_DROP_POSITION] = final_pos
    # Initialize!!!
    move_task.specific_initialize(arg_dict)
    
    emit_signal("task_assigned", move_task)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_TaskManagerRegion_current_task_failed(task):
    emit_signal("task_complete_echo")

func _on_TaskManagerRegion_current_task_succeeded(task):
    emit_signal("task_complete_echo")

