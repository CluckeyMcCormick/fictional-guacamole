# Blender-specific imports
import bpy
import mathutils

# Import so we can re-import the constants script
import imp
import os
import sys

# This is the path to where the other Python scripts are stored. You will need
# to update this if it doesn't match your exact project path.
SCRIPTS_PATH = "godot/fictional-guacamole/Python" # Change me!

# In order to ensure our code is portable/good, expand the path using abspath().
SCRIPTS_PATH = os.path.abspath(SCRIPTS_PATH)
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
# Move the origins
#
# ~~~~~~~~~~~~~~~~~~
# The origin of the feet needs to be where the legs meet the feet - the ankles,
# in other words.
NEW_FOOT_ORIGIN = mathutils.Vector((
    -PC.FEET_X_SHIFT / PC.MM_PER_WORLD_UNIT, 
    0.0, 
    (PC.FEET_HEIGHT / PC.MM_PER_WORLD_UNIT) / 2.0,
)) 
# Change the origin of each foot and then move it back.
foot_l.data.transform(mathutils.Matrix.Translation(-NEW_FOOT_ORIGIN))
foot_l.matrix_world.translation += NEW_FOOT_ORIGIN
foot_r.data.transform(mathutils.Matrix.Translation(-NEW_FOOT_ORIGIN))
foot_r.matrix_world.translation += NEW_FOOT_ORIGIN

# The origin of the legs needs to be where they meet the body. That's still 0,0
# for x and y, but needs to be at the top of the leg.
NEW_LEG_ORIGIN = mathutils.Vector((
    0.0, 
    0.0, 
    (PC.LEG_HEIGHT / PC.MM_PER_WORLD_UNIT) / 2.0,
)) 
# Change the origin of each leg and then move it back.
leg_l.data.transform(mathutils.Matrix.Translation(-NEW_LEG_ORIGIN))
leg_l.matrix_world.translation += NEW_LEG_ORIGIN
leg_r.data.transform(mathutils.Matrix.Translation(-NEW_LEG_ORIGIN))
leg_r.matrix_world.translation += NEW_LEG_ORIGIN

# The origin of the hands should be where they meet the arms. Like the legs,
# that's 0,0 on x,y but needs to be at the top of the hand.
NEW_HAND_ORIGIN = mathutils.Vector((
    0.0, 
    0.0, 
    # As suspected, the diameter appears to be acting like a radius. Ergo, don't
    # halve the value
    PC.HAND_DIAMETER / PC.MM_PER_WORLD_UNIT,
)) 
# Change the origin of each leg and then move it back.
hand_l.data.transform(mathutils.Matrix.Translation(-NEW_HAND_ORIGIN))
hand_l.matrix_world.translation += NEW_HAND_ORIGIN
hand_r.data.transform(mathutils.Matrix.Translation(-NEW_HAND_ORIGIN))
hand_r.matrix_world.translation += NEW_HAND_ORIGIN

# The arms also need to be at the top. We could do the origin at where the top
# point where the cylinder is tangent to the body, but that would require two
# new origins (one for each arm) and would be harder to animate.
NEW_ARM_ORIGIN = mathutils.Vector((
    0.0, 
    0.0, 
    # As suspected, the diameter appears to be acting like a radius. Ergo, don't
    # halve the value
    (PC.ARM_HEIGHT / PC.MM_PER_WORLD_UNIT) / 2.0,
)) 
# Change the origin of each leg and then move it back.
arm_l.data.transform(mathutils.Matrix.Translation(-NEW_ARM_ORIGIN))
arm_l.matrix_world.translation += NEW_ARM_ORIGIN
arm_r.data.transform(mathutils.Matrix.Translation(-NEW_ARM_ORIGIN))
arm_r.matrix_world.translation += NEW_ARM_ORIGIN

# Don't need to adjust the head or the body since those are already where we
# want them

# ~~~~~~~~~~~
#
# Parenting
#
# ~~~~~~~~~~~

# Now, ASSIGN THE PARENTS
foot_l.parent = leg_l
foot_r.parent = leg_r

leg_l.parent = body
leg_r.parent = body

hand_l.parent = arm_l
hand_r.parent = arm_r

arm_l.parent = body
arm_r.parent = body

head.parent = body

# Okay, so chances are everything got all kinds of messed up when we parented
# that stuff just now. BUT THROUGH THE POWER OF MATRICIES AND MATH BEYOND MY
# COMPREHENSION, we can set everything back to what it's supposed to be.
foot_l.matrix_parent_inverse = leg_l.matrix_world.inverted()
foot_r.matrix_parent_inverse = leg_r.matrix_world.inverted()

leg_l.matrix_parent_inverse = body.matrix_world.inverted()
leg_r.matrix_parent_inverse = body.matrix_world.inverted()

hand_l.matrix_parent_inverse = arm_l.matrix_world.inverted()
hand_r.matrix_parent_inverse = arm_r.matrix_world.inverted()

arm_l.matrix_parent_inverse = body.matrix_world.inverted()
arm_r.matrix_parent_inverse = body.matrix_world.inverted()

head.matrix_parent_inverse = body.matrix_world.inverted()


