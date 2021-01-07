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
FEET_LENGTH = 27
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
FEET_X_SHIFT = FEET_LENGTH / 4.5

### Leg Constants!
# The legs are cylinders.
# What's the diameter of each cylindrical leg? (Original 11mm)
# Note that, although the documentation SAYS diameter, I feel like this value
# has been acting more like a radius...
LEG_DIAMETER = 7
# How tall are the prisms/legs? (Original 20mm) Keep in mind these sit on top of
# the feet!
LEG_HEIGHT = 20
# Each cylinder needs a specified number of segements/faces. The more faces, the
# more round the cylinder. So 3 would be a weird triangle, 4 a square-prism, 8
# an octagonal prism, and so on. (Original 64)
LEG_SEGMENTS = 64

### Body Constants!
# The body is also a rectangular prism.
# What's the width (y-length) of this body? (Original 39mm)
BODY_WIDTH = 39
# What's the depth (x-length) of this body? (Original 16mm)
BODY_DEPTH = 16
# What's the height (z-length) of this body? (Original 50mm)
BODY_HEIGHT = 50

### Arm Constants!
# The arms are just like the legs, in that they are cylinders.
# What ism the diameter of an arm-cylinder? (Original 11mm)
# Note that, although the documentation SAYS diameter, I feel like this value
# has been acting more like a radius...
ARM_DIAMETER = 7
# How tall are the prisms/arms? (Original 20mm)
ARM_HEIGHT = 20
# When setting the arms down from the top of the body, we need to shift the arms
# down, so it looks like the pawn has shoulders. How much should we move the
# shoulders down by? (measured 5mm)
ARM_SHOULDER_OFFSET = 7 # To match diameter
# Each cylinder needs a specified number of segements/faces. The more faces, the
# more round the cylinder. So 3 would be a weird triangle, 4 a square-prism, 8
# an octagonal prism, and so on. (Original 64)
ARM_SEGMENTS = 64

### Hand Constants!
# The hands are little ico-spheres - like spheres, but with more obvious faces.
# What is the diameter of one of these little spheres? (Original 10mm)
HAND_DIAMETER = 7
# Ico-spheres are lumpy and polygonal by default. The more subdivisions you
# have, the more the faces are divided, and the smoother the hand-spheres
# become. 5 and above results in a more-or-less normal sphere. (Original 0)
HAND_SUBDIVISIONS = 0

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

# In order to avoid creating more sprites than we have to, we use a bonkers
# sprite layering strategy - a key part of that strategy is using the "pass
# index" of our various objects to effectively "remove" items from the final
# sprites.
# What's the index for every single body part on the Pawn's body?
PAWN_PASS_INDEX = 2
# What's the index for the weapons?
WEAPON_PASS_INDEX = 1

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

# Some scripts need to address all "body parts", so we group them here. That
# way, other classes/scripts can just work through the contents of this list
BODY_PART_STR_LIST = [
    FOOT_L_STR, FOOT_R_STR, LEG_L_STR, LEG_R_STR, ARM_L_STR, ARM_R_STR,
    HAND_L_STR, HAND_R_STR, BODY_STR, HEAD_STR
]

# These are the names for our accessories.
SHORT_SWORD_STR = "shortSword"
HAT_STR = "hat"

# Some scripts need to address all "weapons", but that group is regularly in
# flux. To address that issue, we group them here so that other classes can just
# work through the contents of this list
WEAPON_STR_LIST = [SHORT_SWORD_STR]

# These are the names for our supporting items - the lights, cameras, empty
# parents, etc.
EMPTY_RIG_STR = "Empty Camera-Light Rig"
LIGHTA_STR = "Light A"
LIGHTB_STR = "Light B"
DOWN_CAM_STR = "Top Down Camera"
FORWARD_CAM_STR = "Forward Camera"
ISO_CAM_STR = "Isometric Camera"

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

# We need to move the arm to the sides of the body - since we're at the middle
# the body, we only need to move by half. Then, move out by the diameter.
ARM_SHIFT_Y = (BODY_WIDTH / 2.0) + ARM_DIAMETER 

# We also need to shift the arms upward using a specific formula based on
# the previous height values, plus the height of the body. We then shift them
# downward by the height of the arm (this drops the top of the arm to be level
# with the body top) AND the shoulder offset configurable
ARM_SHIFT_Z = BODY_SHIFT_Z + BODY_HEIGHT - (ARM_HEIGHT + ARM_SHOULDER_OFFSET)

# The positions of the hands on Y are the same as the arms, since the hands
# are centered at the middle of the arms
HAND_SHIFT_Y = ARM_SHIFT_Y

# The hands, being connected to the arms, also move in a similar way. Just one
# extra tidbit - we shift downward by the size of the hands. Now, I'm not quite
# sure why I have to use the hand diameter * 1.5 to get it so that the peak/top
# of the icosphere isn't clipping with the arms. I feel like the "diameter"
# isn't exactly what the documentation claims.
HAND_SHIFT_Z = ARM_SHIFT_Z - (HAND_DIAMETER * 1.5)

# How much do we shift the head up by?
HEAD_SHIFT_Z = BODY_SHIFT_Z + BODY_HEIGHT

# Since we only measure the head as separate subcomponents, we haven't actually
# calculated the total height of the head. Let's do that now!
TOTAL_HEAD_HEIGHT = HEAD_TRI_HEIGHT + HEAD_RECT_HEIGHT

