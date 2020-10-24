# Blender-specific imports
import bpy
import mathutils

# Import so we can re-import the constants script
import imp
import os
import sys
import math

# This is the path to where the other Python scripts are stored. You will need
# to update this if it doesn't match your exact project path.
SCRIPTS_PATH = "~/godot/fictional-guacamole/scripts/Blender" # Change me!

# In order to ensure our code is portable/good, expand the path using
# expanduser().
SCRIPTS_PATH = os.path.expanduser(SCRIPTS_PATH)
# Apparently, there's a chance that the path we got above isn't a string or
# bytes, so we'll pass it through fspath just to be sure.
SCRIPTS_PATH = os.fspath(SCRIPTS_PATH)

if not SCRIPTS_PATH in sys.path:
    sys.path.append(SCRIPTS_PATH)

# Now that we've added our path to the Python-path, we can import our constants.
import pawn_constants as PC
# Just in case it changed (Blender scripting doesn't re-import, or uses some
# sort of caching, I guess), we'll do a real quick reload.
imp.reload(PC)

# ~~~~~~~~~~~~~~~~~~
#
# Get the stuff
#
# ~~~~~~~~~~~~~~~~~~
# Now then, we're gonna arrange each component so that everything is where it's
# supposed to be. First, let's just get  E V E R Y T H I N G.
foot_l = bpy.data.objects[PC.FOOT_L_STR]
foot_r= bpy.data.objects[PC.FOOT_R_STR]

leg_l = bpy.data.objects[PC.LEG_L_STR]
leg_r = bpy.data.objects[PC.LEG_R_STR]

arm_l = bpy.data.objects[PC.ARM_L_STR]
arm_r = bpy.data.objects[PC.ARM_R_STR]

hand_l = bpy.data.objects[PC.HAND_L_STR]
hand_r = bpy.data.objects[PC.HAND_R_STR]

head = bpy.data.objects[PC.HEAD_STR]

body = bpy.data.objects[PC.BODY_STR]

# ~~~~~~~~~~~~~~~~~~
#
# Constant Positions
#
# ~~~~~~~~~~~~~~~~~~
LEFT_ARM_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    PC.ARM_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.ARM_SHIFT_Z + PC.ARM_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

RIGHT_ARM_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    -PC.ARM_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.ARM_SHIFT_Z + PC.ARM_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

LEFT_LEG_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    PC.LEG_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.LEG_SHIFT_Z + PC.LEG_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

RIGHT_LEG_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    -PC.LEG_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.LEG_SHIFT_Z + PC.LEG_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

BODY_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    0.0,
    PC.BODY_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
))

# Default rotation. Pretty uncontroversial.
DEFAULT_ROT = (0, 0, 0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Default Position Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
def left_arm_default():
    arm_l.location = LEFT_ARM_DEFAULT_LOC
    arm_l.rotation_euler = DEFAULT_ROT

def right_arm_default():
    arm_r.location = RIGHT_ARM_DEFAULT_LOC
    arm_r.rotation_euler = DEFAULT_ROT

def left_leg_default():
    leg_l.location = LEFT_LEG_DEFAULT_LOC
    leg_l.rotation_euler = DEFAULT_ROT

def right_leg_default():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC
    leg_r.rotation_euler = DEFAULT_ROT

def body_default():
    body.location = BODY_DEFAULT_LOC
    body.rotation_euler = DEFAULT_ROT

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Arm Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~

# Point the left arm forward
def left_arm_forward():
    arm_l.location = LEFT_ARM_DEFAULT_LOC
    arm_l.rotation_euler = (0, math.radians(-90), 0)

# Point the right arm forward
def right_arm_forward():
    arm_r.location = RIGHT_ARM_DEFAULT_LOC
    arm_r.rotation_euler = (0, math.radians(-90), 0)

# Point the left arm forward and in (front/attached) to the body
def left_arm_outstretched():
    arm_l.location = LEFT_ARM_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        -(PC.ARM_DIAMETER * 2.0) / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_l.rotation_euler = (0, math.radians(-90), 0)

# Point the right arm forward and in (front/attached) to the body
def right_arm_outstretched():
    arm_r.location = RIGHT_ARM_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        (PC.ARM_DIAMETER * 2.0) / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_r.rotation_euler = (0, math.radians(-90), 0)

# Point the left arm upward
def left_arm_upward():
    arm_l.location = LEFT_ARM_DEFAULT_LOC
    arm_l.rotation_euler = (0, math.radians(-180), 0)


# Point the right arm upward
def right_arm_upward():
    arm_r.location = RIGHT_ARM_DEFAULT_LOC
    arm_r.rotation_euler = (0, math.radians(-180), 0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Leg Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each leg has 5 walking positions that we number like so:
#
# 1 |-- * --| 5  Note that Position 3 is the default position.
#     / | \
#    \  -  /
#    2  3  4
#
# Any leg positions that use these swing points will be numbered as such. We
# also have other leg positions that aren't numbered since they are outside the
# walk cycle.
def left_leg_pos5():
    leg_l.location = LEFT_LEG_DEFAULT_LOC + mathutils.Vector((
        -(PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        PC.LEG_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    ))
    leg_l.rotation_euler = (0, math.radians(90), 0)

def right_leg_pos5():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC + mathutils.Vector((
        -(PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        PC.LEG_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    ))
    leg_r.rotation_euler = (0, math.radians(90), 0)

def left_leg_pos4():
    leg_l.location = LEFT_LEG_DEFAULT_LOC + mathutils.Vector((
        -(PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        0.0
    ))
    leg_l.rotation_euler = (0, math.radians(45), 0)

def right_leg_pos4():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC + mathutils.Vector((
        -(PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        0.0
    ))
    leg_r.rotation_euler = (0, math.radians(45), 0)

def left_leg_pos3():
    left_leg_default()

def right_leg_pos3():
    right_leg_default()

def left_leg_pos2():
    leg_l.location = LEFT_LEG_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        0.0
    ))
    leg_l.rotation_euler = (0, math.radians(-45), 0)

def right_leg_pos2():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        0.0
    ))
    leg_r.rotation_euler = (0, math.radians(-45), 0)

def left_leg_pos1():
    leg_l.location = LEFT_LEG_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        PC.LEG_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    ))
    leg_l.rotation_euler = (0, math.radians(-90), 0)

def right_leg_pos1():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        PC.LEG_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    ))
    leg_r.rotation_euler = (0, math.radians(-90), 0)

# Turns the left leg so that it goes outward, below the arm
def left_leg_outward():
    leg_l.location = LEFT_LEG_DEFAULT_LOC
    leg_l.rotation_euler = (0, 0, math.radians(90))

# Turns the right leg so that it goes outward, below the arm
def right_leg_outward():
    leg_r.location = RIGHT_LEG_DEFAULT_LOC
    leg_r.rotation_euler = (0, 0, math.radians(-90))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Body Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
def body_on_floor():
    body.location = mathutils.Vector((
        -(PC.BODY_HEIGHT * .4) / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        (PC.BODY_DEPTH / 2) / float(PC.MM_PER_WORLD_UNIT)
    ))
    body.rotation_euler = (0, math.radians(-90), 0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Code Go Here - Sample Provided
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#left_arm_outstretched()
#right_arm_outstretched()
#left_leg_pos1()
#right_leg_pos1()
#body_on_floor()

