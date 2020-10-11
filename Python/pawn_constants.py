
# IMPORTS! WEEP IN TERROR AS WE USE  M A T H 
import math

# The body is divided into six different types of relatively simple polygonal
# components, for a total of 10 components overall. Each individual component
# has it's own mesh, and each type of component is governed by several specific
# component constants. They are also governed by several relational constants in
# addition to being influenced by the constants of other components.

# The components are:
# 2 Feet, 2 Legs, 1 Body, 2 Arms, 2 Hands, 1 Head

#~~~~~~~~~~~~~~~~~~~~~
#
# ORIGINAL CONSTANTS!
#
#~~~~~~~~~~~~~~~~~~~~~

# Of course, our handy reference is about 110 millimeters tall (11 cm) - how
# many millimeters are there in a world unit? (This is mostly for reference)
MM_PER_WORLD_UNIT = 70

### Feet Constants!
# The feet are sort of like tissue boxes or sardine cans
# How long are the feet, in millimeters? (Original 39mm)
FEET_LENGTH = 39
# How wide are the feet, in millimeters? (Original 18mm)
FEET_WIDTH = 18
# How tall are the feet, in pixels? (Original 8mm)
FEET_HEIGHT = 8
# How far apart are the feet from each other? The distance from the origin of
# the feet (the middle!) to the x-axis is this value / 2. Keep in mind that the
# "position" of the feet are measured from the center of the foot. Ergo, it
# should exceed FEET_WIDTH - and probably then some. (Original ~23mm, measure 5)  
FEET_DISTANCE = 23
# To help us position the feet, we shift them back and forth on the x-axis - how
# much do we move the feet by (in millimeters)? 
FEET_X_SHIFT = FEET_LENGTH / 4.0

### Leg Constants!
# The legs are rectangular prisms with square ends, but they're rotated by a
# configurable amount.
# What's the measurement on one side of said square? In other words, how wide is
# each leg? (Original 11mm)
LEG_WIDTH = 11
# How tall are the prisms/legs? (Original 20mm) Keep in mind these sit on top of
# the feet!
LEG_HEIGHT = 20
# To what DEGREE are the legs rotated? We do this so that the legs look a bit 
# different from the feet and the body - that way they don't form a continous
# plane, which would look a bit odd.
LEG_ROTATION = 45

### Body Constants!
# The body is also a rectangular prism.
# What's the width (y-length) of this body? (Original 39mm)
BODY_WIDTH = 39
# What's the depth (x-length) of this body? (Original 16mm)
BODY_DEPTH = 16
# What's the height (z-length) of this body? (Original 50mm)
BODY_HEIGHT = 50

### Arm Constants!
# The arms are just like the legs, in that they are rectangular-square prisms
# and are rotated.
# How wide is one side of the arm-prism? (Original 11mm)
ARM_WIDTH = 11
# How tall are the prisms/arms? (Original 20mm)
ARM_HEIGHT = 20
# When setting the arms down from the top of the body, we need to shift the arms
# down, so it looks like the pawn has shoulders. How much should we move the
# shoulders down by? (measured 5mm)
ARM_SHOULDER_OFFSET = 5
# To what DEGREE are the arms rotated? Like the legs, we're trying to avoid the
# appearance of a flat, continous plane.
ARM_ROTATION = 45

### Hand Constants!
# The hands are little cubes attached at the end of the arms. They are rotated
# so that they are sort of like little diamonds - basically so that one of the
# points contacts the arm and that is the joint.
# Since the side of the hand is made up of a little cube, what's the measurement
# on one side of that cube? (Original 10mm)
HAND_SIDE = 10

### Head Constants!
# The head is a much more complex shape than    *----*
# the rest of the body. The face is sort of     |    |
# a shield shape, as seen on the right. This    *    *
# shape is extruded in order to create some      \  /
# sorta prism shape.                              **
# 
# Since the head is a prism/extruded shape, we need to give it a thickness - but
# how thick should it be? (Original 25mm)
HEAD_THICKNESS = 25
# How wide/fat is the pawn's head?
HEAD_WIDTH = 25
# Okay, so the head can be cut up into two parts - the lower part which is a
# sloping triangle coming to a point, and the upper part of which is
# rectangular. How tall is the triangular component?
HEAD_TRI_HEIGHT = 5
# How tall is the rectangular component that sits atop the triangular component?
HEAD_RECT_HEIGHT = 25

#~~~~~~~~~~~~~~~~~~~~~
#
# NAME CONSTANTS!
#
#~~~~~~~~~~~~~~~~~~~~~

# Each separate body part needs an identifiable name - that's a Blender
# requirement. So, what's the name for each of our parts?
FOOT_L_STR = "footLeft"
FOOT_R_STR = "footRight"
LEG_L_STR = "legLeft"
LEG_R_STR = "legRight"
ARM_L_STR = "armLeft"
ARM_R_STR = "armRight"
HAND_L_STR = "handLeft"
HAND_R_STR = "handRight"
BODY_STR = "body"
HEAD_STR = "head"

#~~~~~~~~~~~~~~~~~~~~~
#
# DERIVED CONSTANTS!
#
#~~~~~~~~~~~~~~~~~~~~~

# The shifting of the feet are our given constant, halved
FOOT_SHIFT_Y = FEET_DISTANCE / 2.0 

# The positions of the legs on Y are the same as the feet, since the hands are
# centered at the middle of the arms
LEG_SHIFT_Y = FOOT_SHIFT_Y

# The legs sit on top of the feet
LEG_SHIFT_Z = FEET_HEIGHT

# The body sits atop the legs, which sit atop the feet
BODY_SHIFT_Z = FEET_HEIGHT + LEG_HEIGHT

# The position of the arms is more complex than other body components.
# First, we need to move the arm to the sides of the body. Next, we need to move
# the arms out by the arm's width, so that the arms do not clip into the body.
# However, since we rotate the arms at a 45 degree angle (so that the contact is
# along the ridge of the arm), the true distance/width to use is the hypotenuse.
# Also, since we're moving the arms to either side, we need to halve.
ARM_SHIFT_Y = (BODY_WIDTH + math.hypot(ARM_WIDTH, ARM_WIDTH)) / 2.0

# We also need to shift the arms upward using a specific formula based on
# the previous height values, plus the height of the body. We then shift them
# downward by the height of the arm (this drops the top of the arm to be level
# with the body top) AND the shoulder offset configurable
ARM_SHIFT_Z = BODY_SHIFT_Z + BODY_HEIGHT - (ARM_HEIGHT + ARM_SHOULDER_OFFSET)

# The positions of the hands on Y are the same as the arms, since the hands
# are centered at the middle of the arms
HAND_SHIFT_Y = ARM_SHIFT_Y

# The hands, being connected to the arms, also move in a similar way. Just one
# extra tidbit - we shift downward by the size of the hands.
HAND_SHIFT_Z = ARM_SHIFT_Z - HAND_SIDE

# How much do we shift the head up by?
HEAD_SHIFT_Z = BODY_SHIFT_Z + BODY_HEIGHT

# Since we only measure the head as separate subcomponents, we haven't actually
# calculated the total height of the head. Let's do that now!
TOTAL_HEAD_HEIGHT = HEAD_TRI_HEIGHT + HEAD_RECT_HEIGHT

