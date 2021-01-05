# Blender-specific imports
import bpy
from bpy.props import EnumProperty
import mathutils

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
# Constants
#
# ~~~~~~~~~~~~~~~~~~

INPUT_NODE_TYPE = 'CompositorNodeRLayers'
INPUT_NODE_POSITION = (0,0)
INPUT_NODE_IMAGE_INDEX = 0
INPUT_NODE_INDEXOB_INDEX = 3

ID_MASK_NODE_TYPE = 'CompositorNodeIDMask'
ID_MASK_NODE_POSITION = (350, -100)
ID_MASK_NODE_ID_INDEX = 0
ID_MASK_NODE_ALPHA_INDEX = 0

OUTPUT_NODE_TYPE = 'CompositorNodeComposite'
OUTPUT_NODE_POSITION = (600, 0)
OUTPUT_NODE_IMAGE_INDEX = 0
OUTPUT_NODE_ALPHA_INDEX = 1

OP_DISABLE_NODES = 'DISABLE_NODES'
OP_ONLY_WEAPON = 'ONLY_WEAPON'
OP_ONLY_PAWN = 'ONLY_PAWN'
OP_CANCEL_OPERATION = 'CANCEL'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Operation Function Definitions
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def disable_nodes():
    bpy.context.scene.use_nodes = False
    return "Node Rendering disabled!"
    
def only_weapons():
    # switch on nodes and get reference
    bpy.context.scene.use_nodes = True
    tree = bpy.context.scene.node_tree

    # clear default nodes
    for node in tree.nodes:
        tree.nodes.remove(node)

    # create input render layers node
    in_node = tree.nodes.new(type=INPUT_NODE_TYPE)
    in_node.location = INPUT_NODE_POSITION

    # create ID mask node
    mask_node = tree.nodes.new(type=ID_MASK_NODE_TYPE)
    mask_node.location = ID_MASK_NODE_POSITION
    # NO anti-aliasing!
    mask_node.use_antialiasing = False
    # We only want to get the weapons, so get the weapon mask
    mask_node.index = PC.WEAPON_PASS_INDEX

    # create output node
    out_node = tree.nodes.new(type=OUTPUT_NODE_TYPE)   
    out_node.location = OUTPUT_NODE_POSITION
    # Use alpha!
    out_node.use_alpha = True

    # Link the nodes
    tree.links.new(
        in_node.outputs[INPUT_NODE_IMAGE_INDEX], 
        out_node.inputs[OUTPUT_NODE_IMAGE_INDEX]
    )
    tree.links.new(
        in_node.outputs[INPUT_NODE_INDEXOB_INDEX], 
        mask_node.inputs[OUTPUT_NODE_IMAGE_INDEX]
    )
    tree.links.new(
        mask_node.outputs[ID_MASK_NODE_ALPHA_INDEX], 
        out_node.inputs[OUTPUT_NODE_ALPHA_INDEX]
    )
    
    # We're done! Back out!
    return "Now only rendering weapons (masked)!"

def only_pawn():
    # switch on nodes and get reference
    bpy.context.scene.use_nodes = True
    tree = bpy.context.scene.node_tree

    # clear default nodes
    for node in tree.nodes:
        tree.nodes.remove(node)

    # create input render layers node
    in_node = tree.nodes.new(type=INPUT_NODE_TYPE)
    in_node.location = INPUT_NODE_POSITION

    # create ID mask node
    mask_node = tree.nodes.new(type=ID_MASK_NODE_TYPE)
    mask_node.location = ID_MASK_NODE_POSITION
    # NO anti-aliasing!
    mask_node.use_antialiasing = False
    # We only want to get the weapons, so get the weapon mask
    mask_node.index = PC.PAWN_PASS_INDEX

    # create output node
    out_node = tree.nodes.new(type=OUTPUT_NODE_TYPE)   
    out_node.location = OUTPUT_NODE_POSITION
    # Use alpha!
    out_node.use_alpha = True

    # Link the nodes
    tree.links.new(
        in_node.outputs[INPUT_NODE_IMAGE_INDEX], 
        out_node.inputs[OUTPUT_NODE_IMAGE_INDEX]
    )
    tree.links.new(
        in_node.outputs[INPUT_NODE_INDEXOB_INDEX], 
        mask_node.inputs[OUTPUT_NODE_IMAGE_INDEX]
    )
    tree.links.new(
        mask_node.outputs[ID_MASK_NODE_ALPHA_INDEX], 
        out_node.inputs[OUTPUT_NODE_ALPHA_INDEX]
    )
    
    # We're done! Back out!
    return "Now only rendering the pawn (masked)!"

def cancel():
    return "Action Canceled!"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Dialog Operator Definition Call
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set up a description of our action descriptor. Had to do that here because the
# description was a bit too long.
action_desc = "Configuring action to take."
action_desc += " " + "Any 'Force' options will clear the current node setup!"

class DialogOperator(bpy.types.Operator):
    bl_idname = "object.dialog_operator"
    bl_label = "Composition Node Configuration (Pawn)"

    action_enum : EnumProperty(
        items=(
            (OP_DISABLE_NODES, "Disable Node Rendering (Renders All)", ""),
            (OP_ONLY_WEAPON, "Force 'Only Weapon' Rendering", ""),
            (OP_ONLY_PAWN, "Force 'Only Pawn' Rendering", ""),
            (OP_CANCEL_OPERATION, "Cancel", "")
        ),
        name="Configuration Action",
        description=action_desc
    )

    def execute(self, context):
        # In order to execute the action, we need to get the right function.
        # We'll cloister that here.
        func = None
        
        # Assign the function given our action!
        if self.action_enum == OP_DISABLE_NODES:
            func = disable_nodes
        elif self.action_enum == OP_ONLY_WEAPON:
            func = only_weapons
        elif self.action_enum == OP_ONLY_PAWN:
            func = only_pawn
        elif self.action_enum == OP_CANCEL_OPERATION:
            func = cancel
        
        # If we have a function - call it!
        if not func is None:
            self.report( {'INFO'}, func() )
        
        # We're done!
        return {'FINISHED'}

    def invoke(self, context, event):
        wm = context.window_manager
        return wm.invoke_props_dialog(self)

bpy.utils.register_class(DialogOperator)

# In order for the above code to work, we NEED to use the 'cycles' renderer.
bpy.context.scene.render.engine = 'CYCLES'
# We also need the Object Index pass enabled (that pass is unique to Cycles)
bpy.context.scene.view_layers["View Layer"].use_pass_object_index = True

# Call it!
bpy.ops.object.dialog_operator('INVOKE_DEFAULT')

