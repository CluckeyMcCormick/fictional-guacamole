tool
extends StateRoot

# Signal issued when this machine reaches it's target. Sends back the Vector3
# position value that was just reached.
signal path_complete(position)

# Signal issued when this driver is stuck in a back-and-forth loop. We might be
# able to change this now that it's a part of the state machine...
signal error_microposition_loop(target_position)

# We need a Kinematic Core so that we know how fast to move, how low to float,
# which way is down and fast to be down, etc etc.
export(NodePath) var kinematic_core
# We resolve the node path into this variable.
var kinematic_core_node

# Every once in a while, when a body attempts to approach a goal point, it gets
# stuck. Not in a stuck-on-the-geometry kind of way, but a more odd way. It's
# like it keeps missing it's goal by mere millimeters, constantly overstepping.
# I think it's some combination of the navigation mesh and the physics engine
# not behaving to exact specification. We call this the "Microposition Loop"
# error. This is to differentiate it from, for example, a body attempting to
# climb a wall (badly) or a body being pushed backwards.

# To detect when that happens, we capture our distance from our target every
# time we move. This captured value is appended to the Array. We use this to
# ensure we're not rapidly alternating between two or three points, which is a
# key indicator of the above issue.
var _targ_dist_history = []

# The current orientation vector. It is purely for expressing which way the pawn
# is looking/moving. Mostly inteded to help set the appropriate animation and/or
# visual appearance.
var _curr_orient = Vector3.ZERO

# What is our target position - where are we trying to go?
var target_position = null

# So we have a list of target positions that we're trying to work through?
var target_path = []

# String for our current overall state. Used to track the current state for
# animation purposes, but also used for debugging.
var state_key = ""

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
    
    # Resolve the KinematicCore node
    kinematic_core_node = get_node(kinematic_core)
    
    # Also, the target has to be a KinematicBody
    assert(typeof(target) == typeof(KinematicBody), "FSM Owner must be a KinematicBody node!")
    # Also, we need a KinematicCore
    assert(kinematic_core_node != null, "A KinematicCore node is required!")
    
    # Change the default state to "Idle"
    change_state("Idle")
    
    # Force call the idle state's _on_enter since that doesn't seem to work too
    # well for us.
    $OnGround/Idle._on_enter()
