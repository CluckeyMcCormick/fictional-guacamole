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

# Just in case it changed (Blender scripting doesn't re-import, or uses some
# sort of caching, I guess), we'll do a real quick reload of both.
imp.reload(PC)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Constants and near-constants
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# As part of the overall animation, we'll rotate the camera by 45 degrees, then
# repeat the animation. We start facing "East" and then rotate counter-clockwise
# (like a unit circle) through to the "Southeast". We presume that we're
# rotating the 'camera rig' from scene_configuration.py. In that case, our
# angles are a bit wacky, but I've tested them. They work for east-to-southeast
# rotation.
ANGLES = [
    math.radians(-135), # East
    math.radians(180),  # Northeast
    math.radians(135),  # North
    math.radians(90),   # Northwest
    math.radians(45),   # West
    math.radians(0),    # Southwest
    math.radians(-45),  # South
    math.radians(-90),  # Southeast
]

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

# ~~~~~~~~~~~~~~~~~~
#
# Classes
#
# ~~~~~~~~~~~~~~~~~~

# A class to represent a pose. Calls a list of functions, which allows us to
# spread out the functions that pose the body.
class Pose:
    def __init__(self, function_list):
        # Save that list of functions as a pose function list
        self.pf_list = function_list
        
    def pose(self):
        # For each pose function in our list, call it.
        for p in self.pf_list:
            p()

# Sometimes, we don't want to manually pose every frame - we just want to add
# blank frames and have Blender interpolate between them. This class enables
# that.
class InterpolatePose:
    def __init__(self, frame_count):
        self.frame_count = frame_count
        if self.frame_count < 1:
            self.frame_count

# The Animation class allows us to chain poses together and manages them (and
# allows for keyframing)
class Animation:
    def __init__(self, pose_list):
        # Save the pose objects we've been given 
        self.pose_list = pose_list
        # Index of our current pose
        self.curr_pose = 0
        self.pose_list[0].pose()
        
        # If we reached the end of the frames, then we'll store it in this
        self.end_reached = False
        
    def __len__(self):
        frame_length = 0
    
        for pose in self.pose_list:
            # It's technically bad form to do type checking like this in Python;
            # it'd be much more Pythonic to implement a common function on the
            # two classes that mirrors this functionality. However, I don't
            # care.
            if isinstance(pose, InterpolatePose):
                frame_length += pose.frame_count
            else:
                frame_length += 1
        
        return frame_length
        
    def next_pose(self):
        # Increment our current pose counter (cap it at the length of the pose
        # list)
        self.curr_pose += 1
        # If we capped out, mark that we hit the end and then cap the index so
        # we don't do something stupid
        if self.curr_pose >= len(self.pose_list):
            self.curr_pose = len(self.pose_list) - 1
            self.end_reached = True
    
    def get_current_pose(self):
        return self.pose_list[self.curr_pose]

    def assert_pose(self):
        if isinstance(self.pose_list[self.curr_pose], Pose):
            self.pose_list[self.curr_pose].pose()
   
    def reset(self):
        self.curr_pose = 0
        self.pose_list[self.curr_pose].pose()
        self.end_reached = False
    
    def set_keyframe(self, frame_number):
        # Now we don't really have any way of knowing what body component
        # actually got moved - so we're just gonna keyframe everything. That's
        # either a terrible idea or a good one.
        # Left Foot
        foot_l.keyframe_insert(data_path="location", frame=frame_number)
        foot_l.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Right Foot
        foot_r.keyframe_insert(data_path="location", frame=frame_number)
        foot_r.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Left Leg
        leg_l.keyframe_insert(data_path="location", frame=frame_number)
        leg_l.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Right Leg
        leg_r.keyframe_insert(data_path="location", frame=frame_number)
        leg_r.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Left Arm
        arm_l.keyframe_insert(data_path="location", frame=frame_number)
        arm_l.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Right Arm
        arm_r.keyframe_insert(data_path="location", frame=frame_number)
        arm_r.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Left Hand
        hand_l.keyframe_insert(data_path="location", frame=frame_number)
        hand_l.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Right Hand
        hand_r.keyframe_insert(data_path="location", frame=frame_number)
        hand_r.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Head
        head.keyframe_insert(data_path="location", frame=frame_number)
        head.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        # Body
        body.keyframe_insert(data_path="location", frame=frame_number)
        body.keyframe_insert(data_path="rotation_euler", frame=frame_number)
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility function - do the thing!
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def animation_to_keyframes(anim):    
    #
    # Step 1: Clear all of our items of animation
    #
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

    #
    # Step 2: Scene set-up
    #
    # Get the current scene
    current_scene = bpy.context.scene
    # First frame is always 1
    current_scene.frame_start = 1
    # Frames count is our number of angles times the number of frames in the
    # animation
    current_scene.frame_end = len(ANGLES) * len(anim)
    # Frame step is 1 - in other words, render every frame
    current_scene.frame_step = 1
    
    #
    # Step 3: MAKE THOSE KEYFRAMES!
    #
    # Current frame? That's 1!
    curr_frame = 1
    # For each angle...
    for curr_ang in ANGLES:
        # Set the angle for the camera rig
        camera_rig.rotation_euler = (0, 0, curr_ang)
        
        while(not anim.end_reached):
    	    # It's technically bad form to do type checking like this in Python;
    	    # it'd be much more Pythonic to implement a common function on the
    	    # two classes that mirrors this functionality. However, I don't
    	    # care.
    	    # If we're on an interpolation pose...
            if isinstance(anim.get_current_pose(), InterpolatePose):
                # We don't have anything we need to keyframe, we just need to
                # move up the current frame.
                curr_frame += anim.get_current_pose().frame_count
                # Next!
                anim.next_pose()

            # Otherwise, this must be a regular pose!
            else:
                # We need to keyframe the camera so Blender doesn't try to
                # interpolate it.
                camera_rig.keyframe_insert(
                    data_path="rotation_euler", 
                    frame=curr_frame
                )
                # Pose!
                anim.assert_pose()
                # Keyframe!
                anim.set_keyframe(curr_frame)
                # Next!
                anim.next_pose()
                # Frame goes up by 1!
                curr_frame += 1
            
        # Okay, that part of the animation has played out. Now reset it, and
        # then the camera will rotate at the top of the for loop.
        anim.reset()
    
    # And all of our keyframes should be set. Yipee!

