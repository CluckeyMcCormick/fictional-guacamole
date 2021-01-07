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
INPUT_NODE_INDEXOB_INDEX = 2

ID_MASK_NODE_TYPE = 'CompositorNodeIDMask'
ID_MASK_NODE_POSITION = (350, -100)
ID_MASK_NODE_ID_INDEX = 0
ID_MASK_NODE_ALPHA_INDEX = 0

OUTPUT_NODE_TYPE = 'CompositorNodeComposite'
OUTPUT_NODE_POSITION = (600, 0)
OUTPUT_NODE_IMAGE_INDEX = 0
OUTPUT_NODE_ALPHA_INDEX = 1

OP_RENDER_ALL = 'RENDER_ALL'
OP_ONLY_WEAPON = 'ONLY_WEAPON'
OP_ONLY_PAWN = 'ONLY_PAWN'

# ~~~~~~~~~~~~~~~~~~
#
# Utilities
#
# ~~~~~~~~~~~~~~~~~~
# Given the name of a root object, goes through a tree disabling the render
# visibility of that object and it's tree. This is done on the assumption that
# any children of a weapon were probably intended as decorations or effects on
# the weapon.
def modify_tree_render_visibility(root_name, disabling=True):
    # If the root node doesn't exist, back out.
    if not root_name in bpy.data.objects:
        return
    
    # Otherwise, let's get to work.
    bpy.data.objects[root_name].hide_render = disabling

    # Go over all the objects in the hierarchy like @zeffi suggested:
    def set_child_vis(obj):
        for child in obj.children:
            # Hide/show this node (depending)
            child.hide_render = disabling
            # If we have children, then go deeper!
            if child.children:
                set_child_vis(child)

    # Now that we defined that function, let's call it!
    set_child_vis( bpy.data.objects[root_name] )

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Operation Function Definitions
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def render_all():
    # Disable the nodes, which disables the weapon mask
    bpy.context.scene.use_nodes = False
    
    # Enable rendering on all weapons in the scene
    for weapon_str in PC.WEAPON_STR_LIST:
        if weapon_str in bpy.data.objects:
            modify_tree_render_visibility(weapon_str, disabling=False)
    
    return "Rendering everything!"
    
def only_weapons():
    # switch on nodes and get reference
    bpy.context.scene.use_nodes = True
    tree = bpy.context.scene.node_tree

    # Ensure we're rendering all of the weapons
    for weapon_str in PC.WEAPON_STR_LIST:
        if weapon_str in bpy.data.objects:
            modify_tree_render_visibility(weapon_str, disabling=False)

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
    # switch off nodes
    bpy.context.scene.use_nodes = False
    
    # Disable rendering on all weapons in the scene
    for weapon_str in PC.WEAPON_STR_LIST:
        if weapon_str in bpy.data.objects:
            modify_tree_render_visibility(weapon_str)
    
    # We're done! Back out!
    return "Now only rendering the pawn!"

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
            (OP_RENDER_ALL, "Render All", ""),
            (OP_ONLY_WEAPON, "Render Weapon Only (Masked)", ""),
            (OP_ONLY_PAWN, "Render Pawn Only", ""),
        ),
        name="Configuration Action",
        description=action_desc
    )

    def execute(self, context):
        # In order to execute the action, we need to get the right function.
        # We'll cloister that here.
        func = None
        
        # Assign the function given our action!
        if self.action_enum == OP_RENDER_ALL:
            func = render_all
        elif self.action_enum == OP_ONLY_WEAPON:
            func = only_weapons
        elif self.action_enum == OP_ONLY_PAWN:
            func = only_pawn
        
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

