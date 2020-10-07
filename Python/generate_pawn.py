# Blender-specific imports
import bpy
import bmesh
import math
import mathutils

# ~~~~~~~~~~~
# Constants!
# ~~~~~~~~~~

# Of course, our handy reference is about 110 millimeters tall (11 cm) - how
# many millimeters are there in a world unit? (This is mostly for reference)
MM_PER_WORLD_UNIT = 70

# The body is divided into six different types of relatively simple polygonal
# components, for a total of 10 components overall. Each individual component
# has it's own mesh, and each type of component is governed by several specific
# component constants. They are also governed by several relational constants in
# addition to being influenced by the constants of other components.

# The components are:
# 2 Feet, 2 Legs, 1 Body, 2 Arms, 2 Hands, 1 Head

### Feet Constants!
# The feet are sort of like tissue boxes or sardine cans
# How long are the feet, in millimeters? (Original 39mm)
FEET_LENGTH = 39
# How wide are the feet, in millimeters? (Original 18mm)
FEET_WIDTH = 18
# How tall are the feet, in pixels? (Original 8mm)
FEET_HEIGHT = 8
# How far apart are the feet from each other? The distance from the edge of the
# feet to the x-axis is this value / 2. Keep in mind that the "position" of the
# feet are measured from the center of the foot. Ergo, it should exceed
# FEET_WIDTH - and probably then some. (Original ~23mm, Measured 5mm)  
FEET_DISTANCE = 23
# To help us position the feet, we shift them back and forth on the x-axis - how
# much do we move the feet by (in millimeters)? 
FEET_X_SHIFT = FEET_LENGTH / 4.0

### Leg Constants!
# The legs are rectangular prisms with square ends, but they're rotated by 45
# degrees.
# What's the measurement on one side of said square? In other words, how wide is
# each leg? (Original 11mm)
LEG_WIDTH = 11
# How tall are the prisms/legs? (Original 20mm) Keep in mind these sit on top of
# the feet!
LEG_HEIGHT = 20

### Body Constants!
# The body is also a rectangular prism.
# What's the width (y-length) of this body? (Original 39mm)
BODY_WIDTH = 39
# What's the depth (x-length) of this body? (Original 16mm)
BODY_DEPTH = 16
# What's the height (z-length) of this body? (Original 50mm)
BODY_HEIGHT = 50

### Arm Constants!
# The arms are just like the legs, in that they are rectangular-square prisms
# and are rotated at 45 degrees.
# How wide is one side of the arm-prism? (Original 11mm)
ARM_WIDTH = 11
# How tall are the prisms/arms? (Original 20mm)
ARM_HEIGHT = 20
# When setting the arms down from the top of the body, we need to shift the arms
# down, so it looks like the pawn has shoulders. How much should we move the
# shoulders down by? (measured 5mm)
ARM_SHOULDER_OFFSET = 5

### Hand Constants!
# The hands are little cubes attached at the end of the arms. They are rotated
# so that they are sort of like little diamonds - basically so that one of the
# points contacts the arm and that is the joint.
# Since the side of the hand is made up of a little cube, what's the measurement
# on one side of that cube? (Original 10mm)
HAND_SIDE = 10

### Head Constants!
# The head is a much more complex shape than    *----*
# the rest of the body. The face is sort of     |    |
# a shield shape, as seen on the right. This    *    *
# shape is extruded in to create some sorta      \  /
# prism shape.                                    **
# 
# Since the head is a prism/extruded shape, we need to give it a thickness - but
# how thick should it be? (Original 25mm)
HEAD_THICKNESS = 25
# How wide/fat is the pawn's head?
HEAD_WIDTH = 25
# Okay, so the head can be cut up into two parts - the lower part which is a
# sloping triangle coming to a point, and the upper part of which is
# rectangular. How tall is the triangular component?
HEAD_TRI_HEIGHT = 5
# How tall is the rectangular component that sits atop the triangular component?
HEAD_RECT_HEIGHT = 25

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
        base_obj.location = base_obj.location = (0, 0, wuZ / 2.0)
        pass

    return base_obj

def build_foot(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = FEET_LENGTH / float(MM_PER_WORLD_UNIT)
    wuY = FEET_WIDTH / float(MM_PER_WORLD_UNIT)
    wuZ = FEET_HEIGHT / float(MM_PER_WORLD_UNIT)

    return build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name)

def build_both_feet():
    # We need to move each foot to the side, based on FEET_DISTANCE.
    moveY = (FEET_DISTANCE / float(MM_PER_WORLD_UNIT)) / 2
    # We also need to shift the feet forward and backward.
    moveX = FEET_X_SHIFT / float(MM_PER_WORLD_UNIT)
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorX = mathutils.Vector((moveX, 0.0, 0.0))
    
    # Build them feets
    left_foot = build_foot("footLeftMesh", "footLeft")
    right_foot = build_foot("footRightMesh", "footRight")
    # Move them feets
    left_foot.location = left_foot.location + vectorX
    left_foot.location = left_foot.location + vectorY
    right_foot.location = right_foot.location + vectorX
    right_foot.location = right_foot.location - vectorY

def build_leg(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = LEG_WIDTH / float(MM_PER_WORLD_UNIT)
    wuY = LEG_WIDTH / float(MM_PER_WORLD_UNIT)
    wuZ = LEG_HEIGHT / float(MM_PER_WORLD_UNIT)

    return build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name)

def build_both_legs():
    # Both legs need to be moved to the center of each leg. Ergo, our move value
    # on Y is the same as it was for the feet: FEET_DISTANCE (divided by 2).
    moveY = (FEET_DISTANCE / float(MM_PER_WORLD_UNIT)) / 2
    # We also need to shift the legs upward so the sit on top of the feet -
    # that's the FEET_HEIGHT!
    moveZ = FEET_HEIGHT / float(MM_PER_WORLD_UNIT)
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_leg = build_leg("legLeftMesh", "legLeft")
    right_leg = build_leg("legRightMesh", "legRight")
    # Move them feets
    left_leg.location = left_leg.location + vectorZ
    left_leg.location = left_leg.location + vectorY
    left_leg.rotation_euler = (0, 0, math.radians(45))
    right_leg.location = right_leg.location + vectorZ
    right_leg.location = right_leg.location - vectorY
    right_leg.rotation_euler = (0, 0, math.radians(45))

def build_body():
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = BODY_DEPTH / float(MM_PER_WORLD_UNIT)
    wuY = BODY_WIDTH / float(MM_PER_WORLD_UNIT)
    wuZ = BODY_HEIGHT / float(MM_PER_WORLD_UNIT)

    # We also need to shift the legs upward so the sit on top of the feet -
    # that's the FEET_HEIGHT!
    moveZ = (FEET_HEIGHT + LEG_HEIGHT) / float(MM_PER_WORLD_UNIT)
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))

    body = build_rectangulon(wuX, wuY, wuZ, "bodyMesh", "body")
    body.location = body.location + vectorZ

def build_arm(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = ARM_WIDTH / float(MM_PER_WORLD_UNIT)
    wuY = ARM_WIDTH / float(MM_PER_WORLD_UNIT)
    wuZ = ARM_HEIGHT / float(MM_PER_WORLD_UNIT)

    return build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name)

def build_both_arms():
    # The position of the arms is more complex than other body components.
    # First, we need to move the arm to the sides of the body.
    moveY = BODY_WIDTH / float(MM_PER_WORLD_UNIT)
    # Next, we need to move the arms out by the arm's width, so that the arms do
    # not clip into the body. However, since we rotate the arms at a 45 degree
    # angle (so that the contact is along the ridge of the arm), the true
    # distance/width to use is the hypotenuse.
    moveY += math.hypot(ARM_WIDTH, ARM_WIDTH) / float(MM_PER_WORLD_UNIT)
    # Then, since we're doing this to either side, we need to cut the move
    # vector in half.
    moveY /= 2

    # We also need to shift the arms upward using a specific formula based on
    # all the previous height values.
    moveZ = FEET_HEIGHT + LEG_HEIGHT + BODY_HEIGHT
    # We then shift them downward by the height of the arm (this drops the top
    # of the arm to be level with the body top) AND the shoulder offset
    # configurable
    moveZ -= ARM_HEIGHT + ARM_SHOULDER_OFFSET
    # Now convert from millimeters to world units
    moveZ /= float(MM_PER_WORLD_UNIT)
    
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_arm = build_arm("armLeftMesh", "armLeft")
    right_arm = build_arm("armRightMesh", "armRight")

    # Move things around, up down, left, gone to ground
    left_arm.location = left_arm.location + vectorY
    left_arm.location = left_arm.location + vectorZ
    left_arm.rotation_euler = (0, 0, math.radians(45))
    right_arm.location = right_arm.location - vectorY
    right_arm.location = right_arm.location + vectorZ
    right_arm.rotation_euler = (0, 0, math.radians(45))

def build_hand(mesh_name, object_name):
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = HAND_SIDE / float(MM_PER_WORLD_UNIT)
    wuY = HAND_SIDE / float(MM_PER_WORLD_UNIT)
    wuZ = HAND_SIDE / float(MM_PER_WORLD_UNIT)

    return build_rectangulon(wuX, wuY, wuZ, mesh_name, object_name)

def build_both_hands():
    # The positions of the hands are more complex than other body components,
    # but mirror many of the same movements we make for the arms (since they're
    # attached and whatnot.)
    # First, we need to move the arm to the sides of the body.
    moveY = BODY_WIDTH / float(MM_PER_WORLD_UNIT)
    # Next, we need to move the hands out by the arm's width, so that the hands
    # connect at the middle of the arms. However, since we rotate the arms at a
    # 45 degree angle (so that the contact is along the ridge of the arm), the
    # true distance/width to use is the hypotenuse.
    moveY += math.hypot(ARM_WIDTH, ARM_WIDTH) / float(MM_PER_WORLD_UNIT)
    # Then, since we're doing this to either side, we need to cut the move
    # vector in half.
    moveY /= 2

    # We also need to shift the hands upwards and downwards using a specific
    # formula based on all the previous height values.
    moveZ = FEET_HEIGHT + LEG_HEIGHT + BODY_HEIGHT
    # We then shift them downward by the height of the arm (this drops the top
    # of the arm to be level with the body top) AND the shoulder offset
    # configurable
    moveZ -= ARM_HEIGHT + ARM_SHOULDER_OFFSET
    # Now, lower the hands down by the whole of their size
    moveZ -= HAND_SIDE
    # Finally, convert from millimeters to world units
    moveZ /= float(MM_PER_WORLD_UNIT)
    
    # Pack the above into vectors so we can easily translate our feets
    vectorY = mathutils.Vector((0.0, moveY, 0.0))
    vectorZ = mathutils.Vector((0.0, 0.0, moveZ))
    
    # Build them feets
    left_hand = build_hand("handLeftMesh", "handLeft")
    right_hand = build_hand("handRightMesh", "handRight")

    # Move things around, up down, left, gone to ground
    left_hand.location = left_hand.location + vectorY
    left_hand.location = left_hand.location + vectorZ
    right_hand.location = right_hand.location - vectorY
    right_hand.location = right_hand.location + vectorZ

def build_head():
    # Unfortunately for us, the head is a pretty complex shape - a sort of
    # shield-gone-chevron. So we can't cheap out and use our easy rectangulation
    # function, gonna have to do this by hand...

    # First, calculate our world unit measurements. We're gonna need THREE
    # separate measurements just for the height of the head.
    wuX = HEAD_THICKNESS / float(MM_PER_WORLD_UNIT)
    wuY = HEAD_WIDTH / float(MM_PER_WORLD_UNIT)
    wuZ_pointA = HEAD_TRI_HEIGHT / float(MM_PER_WORLD_UNIT)
    wuZ_pointB = wuZ_pointA + (HEAD_RECT_HEIGHT / float(MM_PER_WORLD_UNIT))

    # Next, calculate how much we have to move the head by and then pack that
    # into 
    moveZ = (FEET_HEIGHT + LEG_HEIGHT + BODY_HEIGHT) / float(MM_PER_WORLD_UNIT)
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
    head_obj = prep_object("headMesh", "head")
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
    head_obj.location = head_obj.location + vectorZ

# Build the whole of everything!
build_both_feet()
build_both_legs()
build_body()
build_both_arms()
build_both_hands()
build_head()


