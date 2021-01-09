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
head = bpy.data.objects[PC.HEAD_STR]
body = bpy.data.objects[PC.BODY_STR]

# ~~~~~~~~~~~~~~~~~~
#
#  Pose Functions
#
# ~~~~~~~~~~~~~~~~~~
def right_arm_single_preswing():
    arm_r.location = po_lib.RIGHT_ARM_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        (PC.ARM_DIAMETER * 2.0) / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_r.rotation_euler = (math.radians(-90), 0, math.radians(125))

def right_arm_single_midswing():
    # Same position as "Arm Outstretched".
    arm_r.location = po_lib.RIGHT_ARM_DEFAULT_LOC + mathutils.Vector((
        (PC.BODY_DEPTH / 2.0) / float(PC.MM_PER_WORLD_UNIT), 
        (PC.ARM_DIAMETER * 2.0) / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_r.rotation_euler = (math.radians(-90), 0, math.radians(90))

def right_arm_single_postswing():
    arm_r.location = po_lib.RIGHT_ARM_DEFAULT_LOC + mathutils.Vector((
        0.0, 
        PC.ARM_DIAMETER / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_r.rotation_euler = (math.radians(-90), 0, 0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Weapon Sweep, Single Handed Weapon, Right Arm
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Default all the body parts so we know exactly what's gonna happen
po_lib.full_default()

# Preswing
frame01 = am_lib.Pose([right_arm_single_preswing])
# Midswing
frame02 = am_lib.Pose([right_arm_single_midswing])
# Postswing
frame03 = am_lib.Pose([right_arm_single_postswing])

# Interpolation space
inpo_oneframe = am_lib.InterpolatePose(1)
inpo_twoframe = am_lib.InterpolatePose(2)

"""
Put together into an animation
"""
animo = am_lib.Animation([frame01, inpo_twoframe, frame02, inpo_twoframe, frame03])

# A N I M A T E
am_lib.animation_to_keyframes(animo)

