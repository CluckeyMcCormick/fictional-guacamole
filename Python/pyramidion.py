
# This script generates a square-based pyramid according to the constraints that
# we've declared via constants.

# Blender-specific imports
import bpy
import bmesh

# ~~~~~~~~~~~
# Constants!
# ~~~~~~~~~~

# This is a key value for creating our model. The different constraints that
# allow us to build the pyramidion are in millimeter.
# that are measured in terms of pixels. Using this value, we can translate those
# per-pixel measurements into vertex positions and UV values.
MM_PER_WORLD_UNIT = 60

# What's the total length of the pyramids BASE on x? In millimeters
BASE_LEN_X = 40
# What's the total length of the pyramids BASE on y? In millimeters
BASE_LEN_Y = 40
# How tall is the pyramid? In millimeters
PYRAMID_HEIGHT = 50

# We look at our little pyramidion as two texturable components: the base, and
# the slopes. These are separated since they are of different shapes and
# different constraints.

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

def create_base():
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = BASE_LEN_X / float(MM_PER_WORLD_UNIT)
    wuY = BASE_LEN_Y / float(MM_PER_WORLD_UNIT)

    # Now we need to our vertices - pretty easy since it's four corners
    vert_list = [
        (-wuX / 2.0, -wuY / 2.0, 0),
        (-wuX / 2.0,  wuY / 2.0, 0),
        ( wuX / 2.0,  wuY / 2.0, 0),
        ( wuX / 2.0, -wuY / 2.0, 0)
    ]

    # Create the object and mesh for us to work with.
    base_obj = prep_object("pyramidSquareMesh", "pyramidSquare")
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()
    # We need to save the vertex object/references as we make them, so we'll
    # stick them in this array
    verts_made = []

    # Make each vert in our list!
    for v in vert_list:
        vert = work_mesh.verts.new(v)
        verts_made.append(vert)

    # Now that we've made those verts, we can use the array to make a face:
    work_mesh.faces.new(verts_made)

    # Free those assets
    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

def create_slopes():
    # First, let's convert our constraint measurements from mm to world
    # units
    wuX = BASE_LEN_X / float(MM_PER_WORLD_UNIT)
    wuY = BASE_LEN_Y / float(MM_PER_WORLD_UNIT)
    wuZ = PYRAMID_HEIGHT / float(MM_PER_WORLD_UNIT)

    # Now we need to our vertices - we need the four corners and the peak.
    CORNER_A = (-wuX / 2.0, -wuY / 2.0, 0)
    CORNER_B = (-wuX / 2.0,  wuY / 2.0, 0)
    CORNER_C = ( wuX / 2.0,  wuY / 2.0, 0)
    CORNER_D = ( wuX / 2.0, -wuY / 2.0, 0)
    PEAK = (0, 0, wuZ)

    # Now that we have those points, we'll pack them into groups of three - each
    # group a face of the pyramidion's slope.
    build_list = [
        (CORNER_A, CORNER_B, PEAK), (CORNER_B, CORNER_C, PEAK),
        (CORNER_C, CORNER_D, PEAK), (CORNER_D, CORNER_A, PEAK)   
    ]

    # Create the object and mesh for us to work with.
    base_obj = prep_object("pyramidSlopeMesh", "pyramidSlope")
    # Create a mesh so we can edit stuff
    work_mesh = bmesh.new()
    # We need to save the vertex object/references as we make them, so we'll
    # stick them in this array
    face_listing = []

    # Make each vert in our list!
    for vA, vB, vC in build_list:
        # Our current face-list is empty
        curr = []
        # Add our three verts to the work mesh - at the same time, capture the
        # vert items as they're returned
        curr.append( work_mesh.verts.new(vA) )
        curr.append( work_mesh.verts.new(vB) )
        curr.append( work_mesh.verts.new(vC) )
        # Shove the current array-set into our face listing
        face_listing.append(curr)

    # Now we've got a list-of-lists, where each sublist is the verts required to
    # make a pyramidion slope. So, iterate through the list listing...
    for sublist in face_listing:
        # Use the sublist to make a face
        work_mesh.faces.new(sublist)

    # Free those assets
    work_mesh.to_mesh(base_obj.data) 
    work_mesh.free()

create_base()
create_slopes()
