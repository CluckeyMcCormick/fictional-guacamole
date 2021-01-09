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
def right_arm_single_prestab():
    po_lib.right_arm_default()
    po_lib.right_hand_default()

def right_arm_sword_poststab():
    arm_r.location = po_lib.RIGHT_ARM_DEFAULT_LOC + mathutils.Vector((
        0.0, 
        0.0,#PC.ARM_DIAMETER / float(PC.MM_PER_WORLD_UNIT),
        0.0
    ))
    arm_r.rotation_euler = (0, math.radians(-90), 0)
    
    hand_r.location = po_lib.RIGHT_HAND_DEFAULT_LOC + mathutils.Vector((
        PC.HAND_DIAMETER / float(PC.MM_PER_WORLD_UNIT), 
        0.0,
        -PC.HAND_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    )) 
    hand_r.rotation_euler = (0, math.radians(90), 0)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Weapon Sweep, Single Handed Weapon, Right Arm
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Default all the body parts so we know exactly what's gonna happen
po_lib.full_default()

right_arm_sword_poststab()
# Prestab
frame01 = am_lib.Pose([right_arm_single_prestab])
# Poststab
frame02 = am_lib.Pose([right_arm_sword_poststab])

# Interpolation space - multiple options so we can play around
inpo_oneframe = am_lib.InterpolatePose(1)
inpo_twoframe = am_lib.InterpolatePose(2)
inpo_threeframe = am_lib.InterpolatePose(3)

"""
Put together into an animation
"""
animo = am_lib.Animation([frame01, inpo_oneframe, frame02])

# A N I M A T E
am_lib.animation_to_keyframes(animo)

