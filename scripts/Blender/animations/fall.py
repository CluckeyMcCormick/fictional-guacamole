# Blender-specific imports
import bpy
import mathutils

# We need to do... MATH! *angry mob forms*
import math

# Import so we can re-import the constants script
import imp
import os
import sys

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

# We're also going to import our core posing script
import pawn_pose_core as po_lib # Pose Library

# And the library for making animations
import pawn_animate as am_lib # Animation Library

# Just in case it changed (Blender scripting doesn't re-import, or uses some
# sort of caching, I guess), we'll do a real quick reload of both.
imp.reload(PC)
imp.reload(po_lib)
imp.reload(am_lib)

# ~~~~~~~~~~~~~~~~~~
#
# Get the stuff
#
# ~~~~~~~~~~~~~~~~~~
arm_r = bpy.data.objects[PC.ARM_R_STR]
hand_r = bpy.data.objects[PC.HAND_R_STR]
leg_r = bpy.data.objects[PC.LEG_R_STR]

arm_l = bpy.data.objects[PC.ARM_L_STR]
hand_l = bpy.data.objects[PC.HAND_L_STR]
leg_l = bpy.data.objects[PC.LEG_L_STR]

head = bpy.data.objects[PC.HEAD_STR]
body = bpy.data.objects[PC.BODY_STR]

# ~~~~~~~~~~~~~~~~~~
#
#  Pose Functions
#
# ~~~~~~~~~~~~~~~~~~

def right_arm_uppish():
    arm_r.location = po_lib.RIGHT_ARM_DEFAULT_LOC
    hand_r.location = po_lib.RIGHT_HAND_DEFAULT_LOC
    
    arm_r.rotation_euler = (math.radians(-112.5), 0, math.radians(45))
    hand_r.rotation_euler = (0, 0, math.radians(-90))

def left_arm_uppish():
    arm_l.location = po_lib.LEFT_ARM_DEFAULT_LOC
    hand_l.location = po_lib.LEFT_HAND_DEFAULT_LOC
    
    arm_l.rotation_euler = (math.radians(112.5), 0, math.radians(-45))
    hand_l.rotation_euler = (0, 0, math.radians(90))

def right_leg_uppish():
    leg_r.location = po_lib.RIGHT_LEG_DEFAULT_LOC
    leg_r.rotation_euler = (0, math.radians(-22.5), math.radians(-22.5))

def left_leg_uppish():
    leg_l.location = po_lib.LEFT_LEG_DEFAULT_LOC
    leg_l.rotation_euler = (0, math.radians(-22.5), math.radians(22.5))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Weapon Sweep, Single Handed Weapon, Right Arm
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Default all the body parts so we know exactly what's gonna happen
po_lib.full_default()

# Falling
frame01 = am_lib.Pose([right_arm_uppish, left_arm_uppish, right_leg_uppish, left_leg_uppish])

"""
Put together into an animation
"""
animo = am_lib.Animation([frame01])

# A N I M A T E
am_lib.animation_to_keyframes(animo)

