# Blender-specific imports
import bpy

# ~~~~~~~~~~~
# Constants!
# ~~~~~~~~~~

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

# Now then, we're gonna arrange each component so that everything is where it's
# supposed to be. First, let's just get  E V E R Y T H I N G.
foot_l = bpy.data.objects[FOOT_L_STR]
foot_r= bpy.data.objects[FOOT_R_STR]

leg_l = bpy.data.objects[LEG_L_STR]
leg_r = bpy.data.objects[LEG_R_STR]

arm_l = bpy.data.objects[ARM_L_STR]
arm_r = bpy.data.objects[ARM_R_STR]

hand_l = bpy.data.objects[HAND_L_STR]
hand_r = bpy.data.objects[HAND_R_STR]

head = bpy.data.objects[HEAD_STR]

body = bpy.data.objects[BODY_STR]

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

