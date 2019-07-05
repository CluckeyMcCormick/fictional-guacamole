extends Control

# Need to emit a signal whenever our velocity changes
signal wheel_velocity_changed;

# Our rate of velocity decay, per second. Essentially, the wheel will lose
# ANG_VELO_DECAY % velocity every second
const ANG_VELO_DECAY = 0.95

# The maximum absolute angular velocity, measured in radians / sec
const MAX_ABS_ANG_VELO =  (7 * PI) / 2

# Mouse movement is measured in pixels, and our angular velocity in rads/sec
# This constant converts 1 pixel move to however many rads/sec specified
const MOUSE_MOVE_RADS = (1 * PI) / 2

# We'll use this enum to determine our current quadrant, relative to the wheel
enum { NORTH_EAST, NORTH_WEST, SOUTH_WEST, SOUTH_EAST, NONE}

# Grab our "TRAVLAY" label. We'll hide the text depending on whether the
# fictional traverse laying process is engaged or not
onready var travlay_label = $Label_TRAVLAY
# Grab the wheel that we'll actually be turning
onready var trav_wheel = $TraverseWheel

# Is our "Traverse Laying Process" engaged (are we aiming the turret)?
# Need to store two values - one for the "action" input, and one for the
# "button" input.
var travlay_engaged = [false, false]
# In our "engaged" array, which element is the "Action" value?
const TRAV_ACTION_INDEX = 0
# In our "engaged" array, which element is the "Button" value?
const TRAV_BUTTON_INDEX = 1
# Since our engaged value is not a simple boolean, we'll use a
# function to determine it's state
func is_engaged():
    return travlay_engaged[TRAV_ACTION_INDEX] or travlay_engaged[TRAV_BUTTON_INDEX]

# Our current angular velocity for the traverse wheel
# Ideally measured in radians / sec
var ang_velo = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
    # Ensure our values are at their defaults
    travlay_label.hide()
    travlay_engaged[TRAV_ACTION_INDEX] = false
    travlay_engaged[TRAV_BUTTON_INDEX] = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    
    # First, check our input. If the appropriate action is pressed, then we
    # need to make the appropriate truth index TRUE
    if Input.is_action_pressed("traverse_engage"):
        travlay_engaged[TRAV_ACTION_INDEX] = true
    else:
        travlay_engaged[TRAV_ACTION_INDEX] = false
    
    # Next, we need to check and see if our traverse process is engaged.
    if is_engaged():
        # If so, we need to show the traverse label
        travlay_label.show()
    else:
        # Otherwise, the label needs to be hidden
        travlay_label.hide()     
    
    # If we have sufficient angular velocity...
    if ang_velo > 0.001 or ang_velo < -0.001:
        # Set our rotation using the angular velocity
        trav_wheel.set_rotation( trav_wheel.get_rotation() + (ang_velo * delta) )
        
        # Calculate our new angular velocity, now with decay
        ang_velo -= ang_velo * (ANG_VELO_DECAY * delta)
        
        # Clamp our angular velocity value
        ang_velo = clamp( ang_velo, -MAX_ABS_ANG_VELO, MAX_ABS_ANG_VELO)
        
        # Emit the new velocity
        emit_signal("wheel_velocity_changed", ang_velo)
    # Otherwise, if our velocity isn't sufficient but also isn't 0...
    elif ang_velo != 0:
        # Then make it 0
        ang_velo = 0
        # Emit the new velocity
        emit_signal("wheel_velocity_changed", ang_velo)
    else:
        ang_velo = 0

func _input(event):
    
    # If lay process isn't engaged or the event isn't a mouse motion, then back out
    if not is_engaged() or not event is InputEventMouseMotion:
        return
         
    # Step 1: Determine which quadrant the mouse started in, relative to the
    # wheel.
    # Calculate our mouse's start point, relative to the wheel. This allows us
    # to more easily test the x and y axis to determine the quadrant
    var wheel_start = (self.get_local_mouse_position() - event.relative) - trav_wheel.rect_pivot_offset
    var quadrant = NONE
    
    # Test our relative start x - if it's < 0, we're in the western quads
    if wheel_start.x < 0:
        # If y is < 0, then we're in the north
        if wheel_start.y < 0:
            quadrant = NORTH_WEST
        # Otherwise, we must be in the south!
        else:
            quadrant = SOUTH_WEST
    # Otherwise, we're in the eastern quads
    else:
        # If y is < 0, then we're in the north
        if wheel_start.y < 0:
            quadrant = NORTH_EAST
        # Otherwise, we must be in the south!
        else:
            quadrant = SOUTH_EAST
    
    # Step 2: Process the movement into a velocity value, depending on the quad
    var new_velo = 0
    
    # We need to change how we calculate the velocity from our x and y change
    # depending on which quadrant we started in
    match quadrant:
        NORTH_EAST:
            # Negative Y is CCW, Positive is CW
            # Ergo, respect the sign
            new_velo += event.relative.y * MOUSE_MOVE_RADS
            
            # Negative X is CCW, Positive is CW
            # Ergo, respect the sign
            new_velo += event.relative.x * MOUSE_MOVE_RADS
        NORTH_WEST:
            # Negative Y is CW, Positive is CCW
            # Ergo, flip the sign
            new_velo += -(event.relative.y * MOUSE_MOVE_RADS)
            
            # Negative X is CCW, Positive is CW
            # Ergo, respect the sign
            new_velo += event.relative.x * MOUSE_MOVE_RADS
        SOUTH_WEST:
            # Negative Y is CW, Positive is CCW
            # Ergo, flip the sign
            new_velo += -(event.relative.y * MOUSE_MOVE_RADS)
            
            # Negative X is CW, Positive is CCW
            # Ergo, flip the sign
            new_velo += -(event.relative.x * MOUSE_MOVE_RADS)
        SOUTH_EAST:
            # Negative Y is CCW, Positive is CW
            # Ergo, respect the sign
            new_velo += event.relative.y * MOUSE_MOVE_RADS
            
            # Negative X is CW, Positive is CCW
            # Ergo, flip the sign
            new_velo += -(event.relative.x * MOUSE_MOVE_RADS)
    
    # Step 3: Assign the velocity, emit a velocity_changed signal
    ang_velo = new_velo
    ang_velo = clamp( ang_velo, -MAX_ABS_ANG_VELO, MAX_ABS_ANG_VELO)
    # Emit the new velocity
    emit_signal("wheel_velocity_changed", ang_velo)
    
# What do we do when the wheel is pressed?
func _on_TraverseWheel_button_down():
    travlay_engaged[TRAV_BUTTON_INDEX] = true

# What do we do when the wheel is released?
func _on_TraverseWheel_button_up():
    travlay_engaged[TRAV_BUTTON_INDEX] = false