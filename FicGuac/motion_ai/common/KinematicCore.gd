tool
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# If we're not using a raycast to determine if we're on the ground, then we'll
# test by simulating a downward move. Everytime we do that, we'll usually get a
# collision value back - even if we're actually on what we'd consider the floor!
# So, to rectify that, we're only going to move downwards if the distance moved
# MEETS OR EXCEEDS this value.  
const MINIMUM_FALL_HEIGHT = .002

# Sometimes - due to the speed of the integrating body (too fast), or perhaps
# because of the occassional lumpy weirdness of the Navigation Meshes, or even
# the interplay of falling, floating, and moving - the integrated body will get
# stuck constantly moving under/over it's target. It somehow shoots past it's
# target, then move backwards to overshoot it again.  It's like it keeps missing 
# it's goal by mere millimeters, constantly overstepping. We call this the
# "Microposition Loop" error. This is to differentiate it from, for example, a
# body attempting to climb a wall (badly) or a body being pushed backwards.

# To track and detect the "Microposition Loop" Error, we keep a "history" of our
# distance-to-target.

# How many entries do we keep in the history? If the size exceeds this value,
# then the oldest entries are removed. 
const TARG_DIST_HISTORY_SIZE = 24 # 24 is enough to capture 99% of errors

# How many duplicate entries do we need to detect for us to send out a stuck
# signal? Keep in mind that is tested AFTER the value is added to the array.
# Ergo, the check will always return at least 1, and the value should be greater.
const TARG_DIST_ERROR_THRESHOLD = 3

# To resolve the Microposition Loop error, we slowly increment the goal
# tolerance. How many times do we do that before just concluding that we're
# stuck and sending out an error? This value is inclusive, i.e. error will be
# emitted when tolerance iterations exceed this value.
const MAX_TOLERANCE_ITERATIONS = 5

# Because movement in Godot has a precision of ~6 decimal places, our error
# detection could be hit or miss if we were looking for EXACT matches. Instead,
# we'll round the history entries (and our checks) to this decimal position,
# using the stepify() function.
const ERROR_DETECTION_PRECISION = .01

# Each driver needs a node to move around - what node will this drive move?
export(NodePath) var drive_body setget set_drive_body
# We resolve the node path into this variable.
var drive_body_node

# Whenever we need to get the drive body's position, we'll call this function
# from on the drive_body. We will do so using a FuncRef. If the function is
# invalid/doesn't exist, we'll default to just using the Drive Body's global
# origin.
export(String) var position_function setget set_position_function
# The actual FuncRef object/value associated with the above.
var posfunc_ref

# How fast does our drive node move, horizontally? Units/second
export(float) var move_speed = 10
# How fast does the drive node fall, when it does fall?
export(float) var fall_speed = 9.8
# What's our tolerance for meeting our goal?
export(float) var goal_tolerance = 0.1
# Every time we increment the goal tolerance (as part of our error handling),
# how much do we increment by?
export(float) var tolerance_error_step = .05
# How much do we float by?
export(float) var float_height = 0
# Sometimes, we'll encounter a slope. There has to be a demarcating line where a
# slope acts more like a wall than a true slope, so that whatever we're driving
# doesn't climb a stairway to heaven. What's the maximum angle for a slope we
# can climb, measured in degrees?
export(float) var max_slope_degrees = 45
# When we walk off an edge, we do start falling right away, but we'll put off
# hard transitioning into a "fall" state for this many seconds. This will help
# make things smoother.
export(float) var fall_state_delay_time = .1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the drive body. Mostly here so we can validate the configuration in the
# editor
func set_drive_body(new_drive_body):
    drive_body = new_drive_body
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing drive body node path during runtime is not\n"
        warning += "recommended."
        push_warning(warning)
        
# Set the position function. Mostly here so we can validate the configuration in
# the editor
func set_position_function(new_position_function):
    position_function = new_position_function
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing the position function name during runtime is \n"
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the KinematicDriver is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the body - but only if we have a body to get!
    var body : Node = null
    if drive_body != "":
        body = get_node(drive_body)
    
    # Test 1: Check if we have a node
    if body == null:
        wrnstr += "No drive body specified, or path is invalid!\n"       
    
    # Test 2: Check if we have a
    if not body is KinematicBody:
        wrnstr += "Drive body must be a KinematicBody!\n"
    
    # Test 3a: Check if we have a position function
    if position_function == "":
        wrnstr += "A Position Function is not required, but recommended for correct pathing!\n"
        
    # Test 3b: Ensure the position function exists
    elif body != null:
        if not funcref(body, position_function).is_valid():
            wrnstr += "The function\"" + position_function + "\" appears invalid.\n"
            wrnstr += "A Vector3-returning function/method for \""
            wrnstr += body.name + "\" must be provided!\n"
        
    # Test 3c: Do we even have a body?
    else:
        wrnstr += "Unable to appraise Position Function!\n"
    
    # Test 4: Does the brain dictionary exist in the correct form?
    if body and body.get("brain_dict") != null and typeof(body.brain_dict) != typeof({}):
        wrnstr += "Drive body requires a dictionary called 'brain_dict'!\n"
    
    return wrnstr

# Gets the path-adjusted position - because sometimes, the origin doesn't match
# up with what our position on the path TECHNICALLY is. Has it's own function
# because we need to use different methods depending on whether
# position_function_name is currently correctly configured.
func get_adj_position():
    if posfunc_ref.is_valid():
        return posfunc_ref.call_func()
    else:
        return drive_body_node.global_transform.origin

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # If we're in the editor, then back out. We're not ready for anything just
    # yet!
    if Engine.editor_hint:
        return
    
    # Get the drive target node
    drive_body_node = get_node(drive_body)
    # Create a funcref for our position function
    posfunc_ref = funcref(drive_body_node, position_function)
    
    # Assert that we have a drive body
    assert(drive_body_node != null, "Drive Body must be set as a node in the scene!")
