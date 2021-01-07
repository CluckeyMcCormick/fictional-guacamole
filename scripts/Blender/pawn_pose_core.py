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
# Now then, we're gonna create position functions for all the body parts - so
# let's grab E V E R Y T H I N G.
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

LEFT_HAND_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    PC.HAND_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    PC.HAND_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
))

RIGHT_ARM_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    -PC.ARM_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.ARM_SHIFT_Z + PC.ARM_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

RIGHT_HAND_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    -PC.HAND_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    PC.HAND_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
))

LEFT_LEG_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    PC.LEG_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.LEG_SHIFT_Z + PC.LEG_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

LEFT_FOOT_DEFAULT_LOC = mathutils.Vector((
    PC.FEET_X_SHIFT / float(PC.MM_PER_WORLD_UNIT),
    PC.FOOT_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    0.0
))

RIGHT_LEG_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    -PC.LEG_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    (PC.LEG_SHIFT_Z + PC.LEG_HEIGHT) / float(PC.MM_PER_WORLD_UNIT)
))

RIGHT_FOOT_DEFAULT_LOC = mathutils.Vector((
    PC.FEET_X_SHIFT / float(PC.MM_PER_WORLD_UNIT),
    -PC.FOOT_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT),
    0.0
))

BODY_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    0.0,
    PC.BODY_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
))

HEAD_DEFAULT_LOC = mathutils.Vector((
    0.0, 
    0.0,
    PC.HEAD_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
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

def head_default():
    head.location = HEAD_DEFAULT_LOC
    head.rotation_euler = DEFAULT_ROT
    
#
# Extremity Defaults - not generally recommended for usage, since it's generally
# better to move the parent component (i.e. move legs and not feet)
#
def left_hand_default():
    hand_l.location = LEFT_HAND_DEFAULT_LOC
    hand_l.rotation_euler = DEFAULT_ROT

def right_hand_default():
    hand_r.location = RIGHT_HAND_DEFAULT_LOC
    hand_r.rotation_euler = DEFAULT_ROT

def left_foot_default():
    foot_l.location = LEFT_FOOT_DEFAULT_LOC
    foot_l.rotation_euler = DEFAULT_ROT

def right_foot_default():
    foot_r.location = RIGHT_FOOT_DEFAULT_LOC
    foot_r.rotation_euler = DEFAULT_ROT

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

# ~~~~~~~~~~~~~~~~~~~
#
# Interface Utilities
#
# ~~~~~~~~~~~~~~~~~~~

LEG_POSITION_01_STR = 'legpos01'
LEG_POSITION_02_STR = 'legpos02'
LEG_POSITION_03_STR = 'legpos03'
LEG_POSITION_04_STR = 'legpos04'
LEG_POSITION_05_STR = 'legpos05'
LEG_OUTWARD_STR = 'leg_outward'

ARM_DEFAULT_STR = 'armpos_default'
ARM_OUTSTRETCHED_STR = 'armpos_outstretched'
ARM_FORWARD_STR = 'armpos_forward'
ARM_UPWARD_STR = 'armpos_upward'

left_arm_function_dict = {
    ARM_DEFAULT_STR: left_arm_default,
    ARM_OUTSTRETCHED_STR: left_arm_outstretched,
    ARM_FORWARD_STR: left_arm_forward,
    ARM_UPWARD_STR: left_arm_upward
}
right_arm_function_dict = {
    ARM_DEFAULT_STR: right_arm_default,
    ARM_OUTSTRETCHED_STR: right_arm_outstretched,
    ARM_FORWARD_STR: right_arm_forward,
    ARM_UPWARD_STR: right_arm_upward
}
left_leg_function_dict = {
    LEG_POSITION_01_STR: left_leg_pos1,
    LEG_POSITION_02_STR: left_leg_pos2,
    LEG_POSITION_03_STR: left_leg_pos3,
    LEG_POSITION_04_STR: left_leg_pos4,
    LEG_POSITION_05_STR: left_leg_pos5,
    LEG_OUTWARD_STR: left_leg_outward
}
right_leg_function_dict = {
    LEG_POSITION_01_STR: right_leg_pos1,
    LEG_POSITION_02_STR: right_leg_pos2,
    LEG_POSITION_03_STR: right_leg_pos3,
    LEG_POSITION_04_STR: right_leg_pos4,
    LEG_POSITION_05_STR: right_leg_pos5,
    LEG_OUTWARD_STR: right_leg_outward
}

class PoseMachine(bpy.types.Operator):
    bl_idname = "custom.pose_machine"
    bl_label = "Specify the accessory type."

    left_arm: bpy.props.EnumProperty(
        items=(
            (ARM_DEFAULT_STR, "Default", ""),
            (ARM_OUTSTRETCHED_STR, "Outstretched", ""),
            (ARM_FORWARD_STR, "Forward", ""),
            (ARM_UPWARD_STR, "Upward", ""),
        ),
        name="Left Arm Position",
    )
    right_arm: bpy.props.EnumProperty(
        items=(
            (ARM_DEFAULT_STR, "Default", ""),
            (ARM_OUTSTRETCHED_STR, "Outstretched", ""),
            (ARM_FORWARD_STR, "Forward", ""),
            (ARM_UPWARD_STR, "Upward", ""),
        ),
        name="Right Arm Position",
    )
    left_leg: bpy.props.EnumProperty(
        items=(
            (LEG_POSITION_03_STR, "Position 03 (Default)", ""),
            (LEG_POSITION_01_STR, "Position 01 (Forward, Full)", ""),
            (LEG_POSITION_02_STR, "Position 02 (Forward, Quarter)", ""),
            (LEG_POSITION_04_STR, "Position 04 (Aft, Quarter)", ""),
            (LEG_POSITION_05_STR, "Position 05 (Aft, Full)", ""),
            (LEG_OUTWARD_STR, "Outward", ""),
        ),
        name="Left Leg Position",
    )
    right_leg: bpy.props.EnumProperty(
        items=(
            (LEG_POSITION_03_STR, "Position 03 (Default)", ""),
            (LEG_POSITION_01_STR, "Position 01 (Forward, Full)", ""),
            (LEG_POSITION_02_STR, "Position 02 (Forward, Quarter)", ""),
            (LEG_POSITION_04_STR, "Position 04 (Aft, Quarter)", ""),
            (LEG_POSITION_05_STR, "Position 05 (Aft, Full)", ""),
            (LEG_OUTWARD_STR, "Outward", ""),
        ),
        name="Right Leg Position",
    )
    
    def execute(self, context):
        # Do all the functions the user specified
        left_arm_function_dict[self.left_arm]()
        right_arm_function_dict[self.right_arm]()
        left_leg_function_dict[self.left_leg]()
        right_leg_function_dict[self.right_leg]()
        # All done! Back out.
        return {'FINISHED'}
        
    def invoke(self, context, event):
        wm = context.window_manager
        wm.invoke_props_dialog(self)
        return {'RUNNING_MODAL'}
        
bpy.utils.register_class(PoseMachine)

if __name__ == "__main__":
    # If we're running this as a pose library
    bpy.ops.custom.pose_machine('INVOKE_DEFAULT')


