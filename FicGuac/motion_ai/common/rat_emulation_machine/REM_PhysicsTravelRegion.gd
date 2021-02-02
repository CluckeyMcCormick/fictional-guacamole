tool
extends State

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable & Signal Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Signal issued when this machine reaches it's target. Sends back the Vector3
# position value that was just reached.
signal path_complete(position)

# Signal issued when this driver is stuck and our other error resolution methods
# didn't work.
signal error_goal_stuck(target_position)

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

# What is our target position - where are we trying to go?
var _target_position = null setget set_target_position

# So we have a list of target positions that we're trying to work through?
var _target_path = [] setget set_target_path

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func set_target_position(new_target_position, clear_path=false):
    # Set the target position
    _target_position = new_target_position
    
    # If we got told to clear the path, then clear it!
    if clear_path:
        _target_path = []
    
    # If we still have a path, inform the user that some weird stuff could
    # happen here.
    if not _target_path.empty():
        push_warning("REM Physics Travel Region had target position set, but still has path points! Integrating Body may exhibit odd pathing!")

func set_target_path(new_target_path, clear_target=true):
    # Set the target position
    _target_path = new_target_path
    
    # If we got told to clear the target position, then clear it!
    if clear_target:
        _target_position = null
    
    # If we still have a target position, inform the user that some weird stuff
    # could happen here.
    if _target_position != null:
        push_warning("REM Physics Travel Region had path points set, but still has a target position! Integrating Body may exhibit odd pathing!")

func clear_target_data():
    # Clear the target path
    _target_path = []
    # Clear the target position
    _target_position = null
