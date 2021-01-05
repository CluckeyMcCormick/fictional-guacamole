# Blender-specific imports
import bpy
import mathutils

# Import math
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
# sort of caching, I guess), we'll do a real quick reload.
imp.reload(PC)

# ~~~~~~~~~~~~~~~~~~
#
# Utilities
#
# ~~~~~~~~~~~~~~~~~~
# We're gonna arrange the weapons to be attached to the hands - so let's get the 
# hands.
hand_l = bpy.data.objects[PC.HAND_L_STR]
hand_r = bpy.data.objects[PC.HAND_R_STR]

# Unlike other scripts, it's not guaranteed that the "accessories" we need or
# want is actually in the scene. So we'll need some more flexibility - this
# function allows us to display an error message in Blender so the user knows
# what they need to correct.
def show_message_box(message = "", title = "Message Box", icon = 'INFO'):

    def draw(self, context):
        self.layout.label(text=message)

    bpy.context.window_manager.popup_menu(draw, title = title, icon = icon)

# ~~~~~~~~~~~~~~~~~~~~
#
# Function definitions
#
# ~~~~~~~~~~~~~~~~~~~~

def prepare_short_sword():
    # If we don't have a short sword, inform the user and back out
    if PC.SHORT_SWORD_STR not in bpy.data.objects:
        # Format our error message
        error_msg = "No short sword found! Please add an object called "
        error_msg += PC.SHORT_SWORD_STR
        error_msg += " at origin!"
        # Print!
        print(error_msg)
        show_message_box(message=error_msg, title=PC.SHORT_SWORD_STR)
        return
    
    # Get the short sword
    short_sword = bpy.data.objects[PC.SHORT_SWORD_STR]
    
    # Now, ASSIGN THE PARENT
    short_sword.parent = hand_r

    # Okay, so chances are everything got all kinds of messed up when we
    # parented that stuff just now. BUT THROUGH THE POWER OF MATRICIES AND MATH
    # BEYOND MY COMPREHENSION, we can set everything back to what it's supposed
    # to be.
    short_sword.matrix_parent_inverse = hand_r.matrix_world.inverted()

    # The sword needs to be in the middle of the hand. That should be handled
    # automatically on X and Y, but we'll need to do some manuvering on Z.
    SWORD_MOVE_VECTOR = mathutils.Vector((
        0.0, 
        0.0, 
        # Move the sword down by the hand's diameter (which is actually the
        # radius even though blender says it's not).
        -PC.HAND_DIAMETER / PC.MM_PER_WORLD_UNIT,
    )) 
    # Move the sword to the hand's position, shifting it by the move vector
    short_sword.location = hand_r.location + SWORD_MOVE_VECTOR
    # Rotate the sword so that it faces forward.
    short_sword.rotation_euler = [0, 0, -math.radians(90)]
    
    # Assign the pass index so we can do the compositing nonsense
    short_sword.pass_index  = PC.WEAPON_PASS_INDEX

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Call the correct prepare function here
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prepare_short_sword()



