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
# We're also going to import our posing script
import pawn_pose_core as pose_lib

# Just in case it changed (Blender scripting doesn't re-import, or uses some
# sort of caching, I guess), we'll do a real quick reload of both.
imp.reload(PC)
imp.reload(pose_lib)

# Get all of the body components
foot_l = bpy.data.objects[PC.FOOT_L_STR]
foot_r = bpy.data.objects[PC.FOOT_R_STR]
leg_l = bpy.data.objects[PC.LEG_L_STR]
leg_r = bpy.data.objects[PC.LEG_R_STR]
arm_l = bpy.data.objects[PC.ARM_L_STR]
arm_r = bpy.data.objects[PC.ARM_R_STR]
hand_l = bpy.data.objects[PC.HAND_L_STR]
hand_r = bpy.data.objects[PC.HAND_R_STR]
head = bpy.data.objects[PC.HEAD_STR]
body = bpy.data.objects[PC.BODY_STR]
# ...and the camera rig
camera_rig = bpy.data.objects[PC.EMPTY_RIG_STR]

# Clear all of our items of animation
# All of the body parts...
foot_l.animation_data_clear()
foot_r.animation_data_clear()
leg_l.animation_data_clear()
leg_r.animation_data_clear()
arm_l.animation_data_clear()
arm_r.animation_data_clear()
hand_l.animation_data_clear()
hand_r.animation_data_clear()
head.animation_data_clear()
body.animation_data_clear()
# ...and the camera rig
camera_rig.animation_data_clear()

