# Blender-specific imports
import bpy
import bmesh
import mathutils

# Other imports
import math
import os
import sys
import imp

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

#~~~~~~~~~~~~~~~~~~~~~
#
# UTILITY FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

# Adds a new object to the scene and prepares for mesh operations (if we need to
# do any mesh preparations). Returns the new object.
def prep_object(mesh_name, object_name):
    # Create a linked mesh and object using our string / names.
    mesh = bpy.data.meshes.new(mesh_name)
    obj = bpy.data.objects.new(object_name, mesh)

    # Get the scene
    scene = bpy.context.scene
    # Put the object into the scene
    scene.objects.link(obj)

    # Return the object
    return obj

# Builds a rectangulon, which is a garbage way of saying rectangular prism. Just
# add in extents on x, y, and z! All arguments are in world units. Returns a
# Blender object of the completed rectagonal.
def build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name, translate_up=True):
    # Now we need to our vertices - we need the four corners and the peak.
    CORNER_A = (-wuX / 2.0, -wuY / 2.0, -wuZ / 2.0)
    CORNER_B = (-wuX / 2.0,  wuY / 2.0, -wuZ / 2.0)
    CORNER_C = ( wuX / 2.0,  wuY / 2.0, -wuZ / 2.0)
    CORNER_D = ( wuX / 2.0, -wuY / 2.0, -wuZ / 2.0)

    CORNER_E = (-wuX / 2.0, -wuY / 2.0, wuZ / 2.0)
    CORNER_F = (-wuX / 2.0,  wuY / 2.0, wuZ / 2.0)
    CORNER_G = ( wuX / 2.0,  wuY / 2.0, wuZ / 2.0)
    CORNER_H = ( wuX / 2.0, -wuY / 2.0, wuZ / 2.0)

    build_list = [
        # Do the top and bottom
        (CORNER_A, CORNER_B, CORNER_C, CORNER_D), # Bottom
        (CORNER_E, CORNER_F, CORNER_G, CORNER_H), # Top
        # Now the sides
        (CORNER_A, CORNER_B, CORNER_F, CORNER_E), # Side 1
        (CORNER_B, CORNER_C, CORNER_G, CORNER_F), # Side 2
        (CORNER_C, CORNER_D, CORNER_H, CORNER_G), # Side 3
        (CORNER_D, CORNER_A, CORNER_E, CORNER_H), # Side 4
    ]

    # Create the object and mesh for us to work with.
    base_obj = prep_object(mesh_name, object_name)
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()
    # We need to save the vertex object/references as we make them, so we'll
    # stick them in this array
    face_listing = []

    # Make each vert in our list!
    for vA, vB, vC, vD in build_list:
        # Our current face-list is empty
        curr = []
        # Add our three verts to the work mesh - at the same time, capture the
        # vert items as they're returned
        curr.append( work_mesh.verts.new(vA) )
        curr.append( work_mesh.verts.new(vB) )
        curr.append( work_mesh.verts.new(vC) )
        curr.append( work_mesh.verts.new(vD) )
        # Shove the current array-set into our face listing
        face_listing.append(curr)

    # Now we've got a list-of-lists, where each sublist is the verts required to
    # make our shape. So, iterate through the list listing...
    for sublist in face_listing:
        # Use the sublist to make a face
        work_mesh.faces.new(sublist)

    # Free those assets
    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

    # If we have to translate this rectangulus upward (so that it's sitting
    # atop the floor-grid), then MAKE IT SO
    if translate_up:
        base_obj.location = (0, 0, wuZ / 2.0)

    return base_obj

#~~~~~~~~~~~~~~~~~~~~~
#
# FOOT FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_foot(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = PC.FEET_LENGTH / float(PC.MM_PER_WORLD_UNIT)
    wuY = PC.FEET_WIDTH / float(PC.MM_PER_WORLD_UNIT)
    wuZ = PC.FEET_HEIGHT / float(PC.MM_PER_WORLD_UNIT)

    return build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name)

def build_both_feet():
    # We need to move each foot to the side.
    moveY = PC.FOOT_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT)
    # We also need to shift the feet forward and backward.
    moveX = PC.FEET_X_SHIFT / float(PC.MM_PER_WORLD_UNIT)
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorX = mathutils.Vector((moveX, 0.0, 0.0))
    
    # Build them feets
    left_foot = build_foot(PC.FOOT_L_STR + "Mesh", PC.FOOT_L_STR)
    right_foot = build_foot(PC.FOOT_R_STR + "Mesh", PC.FOOT_R_STR)
    # Move them feets
    left_foot.location += vectorX + vectorY
    right_foot.location += vectorX - vectorY

#~~~~~~~~~~~~~~~~~~~~~
#
# LEG FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_leg(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units.
    diameter = PC.LEG_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    height = PC.LEG_HEIGHT / float(PC.MM_PER_WORLD_UNIT)

    # Create the object and mesh for us to work with.
    base_obj = prep_object(mesh_name, object_name)
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()

    # Create a... cone? Yes, a cone. Blender doesn't have a function for a
    # cylinder, so you have to create a cone with the top and bottom diameters
    # equal - note how diameter is provided as an argument twice.
    bmesh.ops.create_cone(
        # bm (The bmesh to operate on)
        work_mesh,
        # Whether or not to fill in the ends with faces
        cap_ends=True,
        # Fill ends with triangles instead of ngons. I know what that means, but
        # I'm unsure of the impact. Most likely minimal
        cap_tris=False,
        # "Undocumented.", says the documentation. In reality, the number of
        # sides for the cylinder. More sides, more round.
        segments=PC.LEG_SEGMENTS,
        # Diameter of end 1 and end 2.
        diameter1=diameter, diameter2=diameter,
        # "Depth" - what they really mean is the height.
        depth= height 
    )

    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

    # Shift the leg upwards so that it's base is sitting on z = 0
    base_obj.location = (0, 0, height / 2.0)

    return base_obj

def build_both_legs():
    # Both legs need to be moved to the center of each leg.
    moveY = PC.LEG_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT)
    # We also need to shift the legs upward.
    moveZ = PC.LEG_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_leg = build_leg( PC.LEG_L_STR + "Mesh", PC.LEG_L_STR)
    right_leg = build_leg( PC.LEG_R_STR + "Mesh", PC.LEG_R_STR)
    # Move them feets
    left_leg.location += vectorZ + vectorY
    right_leg.location += vectorZ - vectorY

#~~~~~~~~~~~~~~~~~~~~~
#
# BODY FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_body():
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = PC.BODY_DEPTH / float(PC.MM_PER_WORLD_UNIT)
    wuY = PC.BODY_WIDTH / float(PC.MM_PER_WORLD_UNIT)
    wuZ = PC.BODY_HEIGHT / float(PC.MM_PER_WORLD_UNIT)

    # We also need to shift the legs upward so the sit on top of the feet -
    # that's the FEET_HEIGHT!
    moveZ = PC.BODY_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))

    body = build_rectangulon(wuX, wuY, wuZ, PC.BODY_STR + "Mesh", PC.BODY_STR)
    body.location += vectorZ

#~~~~~~~~~~~~~~~~~~~~~
#
# ARM FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_arm(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    diameter = PC.ARM_DIAMETER / float(PC.MM_PER_WORLD_UNIT)
    height = PC.ARM_HEIGHT / float(PC.MM_PER_WORLD_UNIT)

    # Create the object and mesh for us to work with.
    base_obj = prep_object(mesh_name, object_name)
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()

    # Create a... cone? Yes, a cone. Blender doesn't have a function for a
    # cylinder, so you have to create a cone with the top and bottom diameters
    # equal - note how diameter is provided as an argument twice.
    bmesh.ops.create_cone(
        # bm (The bmesh to operate on)
        work_mesh,
        # Whether or not to fill in the ends with faces
        cap_ends=True,
        # Fill ends with triangles instead of ngons. I know what that means, but
        # I'm unsure of the impact. Most likely minimal
        cap_tris=False,
        # "Undocumented.", says the documentation. In reality, the number of
        # sides for the cylinder. More sides, more round.
        segments=PC.ARM_SEGMENTS,
        # Diameter of end 1 and end 2.
        diameter1=diameter, diameter2=diameter,
        # "Depth" - what they really mean is the height.
        depth= height 
    )

    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

    # Shift the leg upwards so that it's base is sitting on z = 0
    base_obj.location = (0, 0, height / 2.0)

    return base_obj

def build_both_arms():
    # Get/convert the pre calculated arm shifts on Y and Z
    moveY = PC.ARM_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT)
    moveZ = PC.ARM_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
    
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_arm = build_arm(PC.ARM_L_STR + "Mesh", PC.ARM_L_STR)
    right_arm = build_arm(PC.ARM_R_STR + "Mesh", PC.ARM_R_STR)

    # Move things around, up down, left, gone to ground
    left_arm.location += vectorZ + vectorY 
    right_arm.location += vectorZ - vectorY

#~~~~~~~~~~~~~~~~~~~~~
#
# HAND FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_hand(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units.
    diameter = PC.HAND_DIAMETER / float(PC.MM_PER_WORLD_UNIT)

    # Create the object and mesh for us to work with.
    base_obj = prep_object(mesh_name, object_name)
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()

    # Create a... cone? Yes, a cone. Blender doesn't have a function for a
    # cylinder, so you have to create a cone with the top and bottom diameters
    # equal - note how diameter is provided as an argument twice.
    bmesh.ops.create_icosphere(
        # bm (The bmesh to operate on)
        work_mesh,
        # "How many times to recursively subdivide the sphere"
        subdivisions=PC.HAND_SUBDIVISIONS,
        # Diameter!
        diameter=diameter
    )

    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

    # Shift the leg upwards so that it's base is sitting on z = 0
    base_obj.location = (0, 0, diameter / 2.0)

    return base_obj

def build_both_hands():
    # Get/convert the pre calculated arm shifts on Y and Z
    moveY = PC.HAND_SHIFT_Y / float(PC.MM_PER_WORLD_UNIT)
    moveZ = PC.HAND_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
    
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_hand = build_hand( PC.HAND_L_STR + "Mesh", PC.HAND_L_STR )
    right_hand = build_hand( PC.HAND_R_STR + "Mesh", PC.HAND_R_STR )

    # Move things around, up down, left, gone to ground
    left_hand.location += vectorZ + vectorY
    right_hand.location += vectorZ - vectorY

#~~~~~~~~~~~~~~~~~~~~~
#
# HEAD FUNCTIONS!
#
#~~~~~~~~~~~~~~~~~~~~~

def build_head():
    # Unfortunately for us, the head is a pretty complex shape - a sort of
    # shield-gone-chevron. So we can't cheap out and use our easy rectangulation
    # function, gonna have to do this by hand...

    # First, calculate our world unit measurements. We're gonna need THREE
    # separate measurements just for the height of the head.
    wuX = PC.HEAD_THICKNESS / float(PC.MM_PER_WORLD_UNIT)
    wuY = PC.HEAD_WIDTH / float(PC.MM_PER_WORLD_UNIT)
    wuZ_pointA = PC.HEAD_TRI_HEIGHT / float(PC.MM_PER_WORLD_UNIT)
    wuZ_pointB = PC.TOTAL_HEAD_HEIGHT / float(PC.MM_PER_WORLD_UNIT)

    # Next, calculate how much we have to move the head by and then pack that
    # into a vector
    moveZ = PC.HEAD_SHIFT_Z / float(PC.MM_PER_WORLD_UNIT)
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))

    # Now then, the shield has 5 points across 2 layers...
    # X-forward layer, and...
    CORNER_A = ( wuX / 2.0,          0,          0)
    CORNER_B = ( wuX / 2.0,  wuY / 2.0, wuZ_pointA)
    CORNER_C = ( wuX / 2.0,  wuY / 2.0, wuZ_pointB)
    CORNER_D = ( wuX / 2.0, -wuY / 2.0, wuZ_pointB)
    CORNER_E = ( wuX / 2.0, -wuY / 2.0, wuZ_pointA)
    # X-backward layer
    CORNER_V = (-wuX / 2.0,          0,          0)
    CORNER_W = (-wuX / 2.0,  wuY / 2.0, wuZ_pointA)
    CORNER_X = (-wuX / 2.0,  wuY / 2.0, wuZ_pointB)
    CORNER_Y = (-wuX / 2.0, -wuY / 2.0, wuZ_pointB)
    CORNER_Z = (-wuX / 2.0, -wuY / 2.0, wuZ_pointA)

    # First, we're gonna construct the front and back, which are five points
    # each
    front_and_back = [
        (CORNER_A, CORNER_B, CORNER_C, CORNER_D, CORNER_E), # Front
        (CORNER_V, CORNER_W, CORNER_X, CORNER_Y, CORNER_Z), # Back
    ]
    # Then we're gonna work on the sides
    sides = [
        # +Y side
        (CORNER_A, CORNER_B, CORNER_W, CORNER_V),
        (CORNER_B, CORNER_C, CORNER_X, CORNER_W),
        # -Y side
        (CORNER_A, CORNER_E, CORNER_Z, CORNER_V),
        (CORNER_E, CORNER_D, CORNER_Y, CORNER_Z),
        # Top
        (CORNER_C, CORNER_D, CORNER_Y, CORNER_X),
    ]
    # Create the object and mesh for us to work with.
    head_obj = prep_object( PC.HEAD_STR + "Mesh", PC.HEAD_STR )
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()
    # We need to save the vertex object/references as we make them, so we'll
    # stick them in this array
    face_listing = []

    # Make each vert in our face list!
    for vA, vB, vC, vD, vE in front_and_back:
        # Our current face-list is empty
        curr = []
        # Add our three verts to the work mesh - at the same time, capture the
        # vert items as they're returned
        curr.append( work_mesh.verts.new(vA) )
        curr.append( work_mesh.verts.new(vB) )
        curr.append( work_mesh.verts.new(vC) )
        curr.append( work_mesh.verts.new(vD) )
        curr.append( work_mesh.verts.new(vE) )
        # Shove the current array-set into our face listing
        face_listing.append(curr)

    # Make each vert in our side list!
    for vA, vB, vC, vD in sides:
        # Our current face-list is empty
        curr = []
        # Add our three verts to the work mesh - at the same time, capture the
        # vert items as they're returned
        curr.append( work_mesh.verts.new(vA) )
        curr.append( work_mesh.verts.new(vB) )
        curr.append( work_mesh.verts.new(vC) )
        curr.append( work_mesh.verts.new(vD) )
        # Shove the current array-set into our face listing
        face_listing.append(curr)

    # Now we've got a list-of-lists, where each sublist is the verts required to
    # make our shape. So, iterate through the list listing...
    for sublist in face_listing:
        # Use the sublist to make a face
        work_mesh.faces.new(sublist)

    # Free those assets
    work_mesh.to_mesh(head_obj.data) 
    work_mesh.free()

    # Translate our head object - get that head on those shoulders!
    head_obj.location += vectorZ

#~~~~~~~~~~~~~~~~~~~~~~~~
#
# ACTUAL FUNCTION CALLS!
#
#~~~~~~~~~~~~~~~~~~~~~~~~

# Build the whole of everything!
build_both_feet()
build_both_legs()
build_body()
build_both_arms()
build_both_hands()
build_head()

