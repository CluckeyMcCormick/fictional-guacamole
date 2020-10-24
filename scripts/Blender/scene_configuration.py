# Blender-specific imports
import bpy
import mathutils

# We need to do... MATH! *distant screaming*
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
# Constants
#
# ~~~~~~~~~~~~~~~~~~
# What's the resolution of our output image
RESOLUTION_X = 128
RESOLUTION_Y = 128

# We use 'Freestyle' to add lines to our finished render, giving the Pawns a
# more finished look
FREESTYLE_LINE_THICKNESS = .25

# We use orthographic cameras. With orthographic cameras, the scope of what we
# can see is determined by the "scale" of the camera.
CAMERA_SCALE = 1.8

# To help us control our lighting and rig/other nonsense, we create an empty
# cube centered on the pawn's body. How big is that cube?
EMPTY_SIZE = 1

# How high up do we put our lights? (World units, on z)
LIGHT_HEIGHT = 2
# What's the energy of the lights? How bright is the light?
LIGHT_ENERGY = 416.3
# What's the readius of the lights - how far does their light reach? In World
# Units.
LIGHT_RADIUS = 2.7
# Specular coefficient for each light. Far as I can understand, specular relates
# to the reflection of light and can give things a "shiny" texture - not what we
# want at all!
LIGHT_SPECULAR = 0

# The cameras are kept at a specific distance on X and Y (except for the
# top-down) - what is that distance?
CAMERA_DISTANCE = 12
# The isometric camera has to be at a specific angle in order to be as close to
# isometric as possible. However, in Blender, a camera at 90 degrees is pointing
# forward. Ergo, we have to subtract the appropriate isometric angle from 90
# degrees.
CAMERA_ISO_ANGLE = 90 - 35.264
# Each camera generally needs to face the same direction, which we do by
# rotating on Z - how much do we rotate?
CAMERA_Z_ROTATION = 135
# To help position the pawn in the frame appropriately, we have to move the
# camera up and down - by how much?
CAMERA_Z_HEIGHT = 12

# Once the camera is in position, we can shift the frame up and down using these
# values
ISO_CAMERA_Y_SHIFT = -0.015
FORWARD_CAMERA_Y_SHIFT = -0.015
TOP_DOWN_CAMERA_Y_SHIFT = 0

#~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utilities and Preparation
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Get the current scene
current_scene = bpy.context.scene
# Get the body - many things in the scene center on the body so we'll need to
# get the body's position
body = bpy.data.objects[PC.BODY_STR]

# Adds a new object to the scene and prepares for mesh operations (if we need to
# do any mesh preparations). Returns the new object.
def prep_object(mesh_name, object_name):
    # Create a linked mesh and object using our string / names.
    mesh = bpy.data.meshes.new(mesh_name)
    obj = bpy.data.objects.new(object_name, mesh)

    # Put the object into the scene/collection
    bpy.context.collection.objects.link(obj)

    # Return the object
    return obj

def prep_empty_object(object_name):
    # Create an empty object using our string / names.
    obj = bpy.data.objects.new(object_name, None)

    # Put the object into the scene/collection
    bpy.context.collection.objects.link(obj)

    # Return the object
    return obj

def prep_light_object(light_name, object_name):
    # Create a linked mesh and object using our string / names.
    light = bpy.data.lights.new(light_name, 'POINT')
    obj = bpy.data.objects.new(object_name, light)

    # Put the object into the scene/collection
    bpy.context.collection.objects.link(obj)

    # Return the object
    return obj

def prep_camera_object(camera_name, object_name):
    # Create a linked mesh and object using our string / names.
    camera = bpy.data.cameras.new(camera_name)
    obj = bpy.data.objects.new(object_name, camera)

    # Put the object into the scene/collection
    bpy.context.collection.objects.link(obj)

    # Return the object
    return obj

# ~~~~~~~~~~~~~~~~~~
#
# Set-Up Empty
#
# ~~~~~~~~~~~~~~~~~~
# Create empty
empty_rig = prep_empty_object(PC.EMPTY_RIG_STR)
# Set the size and the display type / value
empty_rig.empty_display_size = EMPTY_SIZE
empty_rig.empty_display_type = 'CUBE'

# Move the empty rig to the middle of the body
empty_rig.location = mathutils.Vector(( 0.0, 0.0, body.location.z ))

# ~~~~~~~~~~~~~~~~~~
#
# Set-Up Lights
#
# ~~~~~~~~~~~~~~~~~~
# Create Light A
temp = prep_light_object(PC.LIGHTA_STR + " Actual", PC.LIGHTA_STR)
# Light A goes at the first corner of the rig
temp.location = mathutils.Vector((EMPTY_SIZE, EMPTY_SIZE, LIGHT_HEIGHT))
temp.parent = empty_rig
temp.matrix_parent_inverse = empty_rig.matrix_world.inverted()

# Lights A L W A Y S cast shadow.
temp.data.use_shadow = True
# Set our other values
temp.data.energy = LIGHT_ENERGY
temp.data.shadow_soft_size = LIGHT_RADIUS
temp.data.specular_factor = LIGHT_SPECULAR

# Create Light B
temp = prep_light_object(PC.LIGHTB_STR + " Actual", PC.LIGHTB_STR)
# Light B goes at the opposite corner of the rig
temp.location = mathutils.Vector((-EMPTY_SIZE, -EMPTY_SIZE, LIGHT_HEIGHT))
temp.parent = empty_rig
temp.matrix_parent_inverse = empty_rig.matrix_world.inverted()

# Lights A L W A Y S cast shadow.
temp.data.use_shadow = True
# Set our other values
temp.data.energy = LIGHT_ENERGY
temp.data.shadow_soft_size = LIGHT_RADIUS
temp.data.specular_factor = LIGHT_SPECULAR

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Set-Up Camera A (Isometric)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
temp = prep_camera_object(PC.ISO_CAM_STR + " Actual", PC.ISO_CAM_STR)
temp.location = mathutils.Vector((
    CAMERA_DISTANCE, 
    CAMERA_DISTANCE, 
    CAMERA_Z_HEIGHT
))
temp.rotation_euler = (
    math.radians(CAMERA_ISO_ANGLE), 
    0,
    math.radians(CAMERA_Z_ROTATION)
)
temp.parent = empty_rig
temp.matrix_parent_inverse = empty_rig.matrix_world.inverted()

temp.data.type = 'ORTHO'
temp.data.ortho_scale = CAMERA_SCALE
temp.data.shift_y = ISO_CAMERA_Y_SHIFT

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Set-Up Camera B (Head-On)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
temp = prep_camera_object(PC.FORWARD_CAM_STR + " Actual", PC.FORWARD_CAM_STR)
temp.location = mathutils.Vector((CAMERA_DISTANCE, CAMERA_DISTANCE, 0))
temp.rotation_euler = (
    math.radians(90), 
    0,
    math.radians(CAMERA_Z_ROTATION)
)
temp.parent = empty_rig
temp.matrix_parent_inverse = empty_rig.matrix_world.inverted()

temp.data.type = 'ORTHO'
temp.data.ortho_scale = CAMERA_SCALE
temp.data.shift_y = FORWARD_CAMERA_Y_SHIFT

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Set-Up Camera C (Top-Down)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
temp = prep_camera_object(PC.DOWN_CAM_STR + " Actual", PC.DOWN_CAM_STR)
temp.location = mathutils.Vector((0, 0, CAMERA_Z_HEIGHT))
temp.rotation_euler = (0, 0, math.radians(CAMERA_Z_ROTATION))
temp.parent = empty_rig
temp.matrix_parent_inverse = empty_rig.matrix_world.inverted()

temp.data.type = 'ORTHO'
temp.data.ortho_scale = CAMERA_SCALE
temp.data.shift_y = TOP_DOWN_CAMERA_Y_SHIFT

# ~~~~~~~~~~~~~~~~~~~~
#
# Set Render Settings
#
# ~~~~~~~~~~~~~~~~~~~~
# Set 'Film' to Transparent
current_scene.render.film_transparent = True

# Enable freestyle
current_scene.render.use_freestyle = True

# Set freestyle mode to absolute
current_scene.render.line_thickness_mode = 'ABSOLUTE'

# Set freestyle line-thickness
current_scene.render.line_thickness = FREESTYLE_LINE_THICKNESS

# Set Resolution
current_scene.render.resolution_x = RESOLUTION_X
current_scene.render.resolution_y = RESOLUTION_Y
current_scene.render.resolution_percentage = 100

