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
