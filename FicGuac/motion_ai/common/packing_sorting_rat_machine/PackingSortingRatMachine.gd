tool
extends StateRoot

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

# We also need a Pathing Interface Core so that we can navigate to positions on
# our own AND determine where we are
export(NodePath) var pathing_interface_core
# We resolve the node path into this variable.
var pathing_interface_core_node

# This Item Management Core will help us handle our items.
export(NodePath) var item_management_core
# We resolve the node path into this variable.
var item_management_core_node

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

# Okay, so the Rat Emulation Machine can get stuck in a chicken-and-egg
# situation with regards to configuration. The children states require access to
# several variables/nodes that SHOULD be setup in the _ready function of this
# script. However, our underlying state_root script calls the appropriate
# _on_enter functions for our default nodes. These then reference the
# aformentioned variables, RUINING EVERYTHING. To get around this, our
# configuration is performed in a different function, and whether we have
# configured or not is tracked by this variable.
var _machine_configured = false

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
    if Engine.editor_hint and target == null:
        return
    
    if not _machine_configured:
        _force_configure()

func _force_configure():
    # Resolve the KinematicCore node
    kinematic_core_node = get_node(kinematic_core)
    # Resolve the SensorySortCore node
    sensory_sort_core_node = get_node(sensory_sort_core)
    # Resolve the PathingInterfaceCore node
    pathing_interface_core_node = get_node(pathing_interface_core)
    # Resolve the ItemManagementCore node
    item_management_core_node = get_node(item_management_core)
    
    # Also, the target has to be a KinematicBody
    assert(typeof(target) == typeof(KinematicBody), "FSM Owner must be a KinematicBody node!")
    # Also, we need a KinematicCore
    assert(kinematic_core_node != null, "A KinematicCore node is required!")
    # AAAAAND a we need a SensorySortCore
    assert(sensory_sort_core_node != null, "A SensorySortCore node is required!")
    # Can't forget the Pathing Interface Core!
    assert(pathing_interface_core_node != null, "A PathingInterfaceCore node is required!")
    # The Item Management Core ALSO needs to be here
    assert(item_management_core_node != null, "An ItemManagementCore node is required!")
    
    # The machine is configured. Hooray!
    _machine_configured = true
