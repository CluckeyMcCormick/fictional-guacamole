tool
extends StateRoot

# Signal issued when this machine reaches it's target. Sends back the Vector3
# position value that was just reached.
signal path_complete(position)

# Signal issued when this driver is stuck and our other error resolution methods
# didn't work.
signal error_goal_stuck(target_position)

# We need a Kinematic Core so that we know how fast to move, how low to float,
# which way is down and fast to be down, etc etc.
export(NodePath) var kinematic_core
# We resolve the node path into this variable.
var kinematic_core_node

# We also need a Level Interface Core so we can interface with different
# elements of the current level
export(NodePath) var level_interface_core
# We resolve the node path into this variable.
var level_interface_core_node

# Sometimes - due to the speed of the integrating body (too fast), or perhaps
# because of the occassional lumpy weirdness of the Navigation Meshes, or even
# the interplay of falling, floating, and moving - the integrated body will get
# stuck constantly moving under/over it's target. It somehow shoots past it's
# target, then move backwards to overshoot it again.  It's like it keeps missing 
# it's goal by mere millimeters, constantly overstepping. We call this the
# "Microposition Loop" error. This is to differentiate it from, for example, a
# body attempting to climb a wall (badly) or a body being pushed backwards.

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

# The projected movement is how far we THINK we'll go in a strictly defined
# period of time. This helps us prefrome move-to-intercept actions on any
# implementing body much easier.
var _projected_movement = Vector3.ZERO

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
    # Resolve the LevelInterfaceCore node
    level_interface_core_node = get_node(level_interface_core)
    
    # Also, the target has to be a KinematicBody
    assert(typeof(target) == typeof(KinematicBody), "FSM Owner must be a KinematicBody node!")
    # Also, we need a KinematicCore
    assert(kinematic_core_node != null, "A KinematicCore node is required!")
    # Can't forget the Level Interface Core!
    assert(level_interface_core_node != null, "A LevelInterfaceCore node is required!")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The machine generates a path towards the given position and begins following
# it.
func move_to_point(to_point : Vector3):
    self.target_position = null
    self.target_path = level_interface_core_node.path_between(
        target.global_transform.origin, # FROM the target's position
        to_point # TO the to_point
    )

func clear_pathing():
    self.target_path = []
    self.target_position = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_update(_delta) -> void:
    # Default the projected movement to nothing. The child states will modify
    # this one. It'll be the same for one cycle, then it will be reset. Neat!!!
    _projected_movement = Vector3.ZERO
