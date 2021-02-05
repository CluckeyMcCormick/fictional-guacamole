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

func set_target_path(new_target_path, clear_target=true):
    # Set the target position
    _target_path = new_target_path
    
    # If we got told to clear the target position, then clear it!
    if clear_target:
        _target_position = null
    
func clear_target_data():
    # Clear the target path
    _target_path = []
    # Clear the target position
    _target_position = null
