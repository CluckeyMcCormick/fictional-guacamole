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
#  Basic Walk Cycle
#
# ~~~~~~~~~~~~~~~~~~

# Default all the body parts so we know exactly what's gonna happen
po_lib.full_default()

# Left Leg Forward, Right Leg back
walk_frame01 = am_lib.Pose([po_lib.left_leg_pos2, po_lib.right_leg_pos4])
# Left Leg Neutral, Right Leg Neutral
walk_frame02 = am_lib.Pose([po_lib.left_leg_pos3, po_lib.right_leg_pos3])
# Left Leg Neutral, Right Leg Neutral
walk_frame03 = am_lib.Pose([po_lib.left_leg_pos4, po_lib.right_leg_pos2])
# Left Leg Neutral, Right Leg Neutral
walk_frame04 = am_lib.Pose([po_lib.left_leg_pos3, po_lib.right_leg_pos3])

"""
Put together into an animation
"""
animo = am_lib.Animation([walk_frame01, walk_frame02, walk_frame03, walk_frame04])

# A N I M A T E
am_lib.animation_to_keyframes(animo)




