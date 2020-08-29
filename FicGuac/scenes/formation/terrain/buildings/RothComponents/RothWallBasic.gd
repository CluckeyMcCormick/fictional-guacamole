tool
extends StaticBody

export(Material) var cutaway_sides_mat setget set_cutaway_sides
export(Material) var cutaway_top_mat setget set_cutaway_top
export(Material) var interior_mat setget set_interior
export(Material) var exterior_mat setget set_exterior

# Sometimes, this procedural component doesn't line up with the textures of it's
# neighbors. This Vector3 should solve that.
export(Vector3) var uv_shift setget set_uv_shift
# How long is the wall?
export(float, .25, 10, .25) var length = 2 setget set_length
# How thick is the wall?
export(float, .25, 10, .25) var thickness = 1 setget set_thickness
# How high is the wall?
export(float, .25, 10, .25) var height = 2 setget set_height

# Load the PolyGen script
const PolyGen = preload("res://scenes/formation/util/PolyGen.gd")

func _ready():
    # When we enter the scene for the first time, we have to build out the
    # stairs
    self.build_all()

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_cutaway_sides(new_mat):
    cutaway_sides_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_cutaway_top(new_mat):
    cutaway_top_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_interior(new_mat):
    interior_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_exterior(new_mat):
    exterior_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_uv_shift(new_shift):
    uv_shift = new_shift
    if Engine.editor_hint:
        build_all()

func set_length(new_length):
    length = new_length
    if Engine.editor_hint:
        build_all()

func set_thickness(new_thickness):
    thickness = new_thickness
    if Engine.editor_hint:
        build_all()

func set_height(new_height):
    height = new_height
    if Engine.editor_hint:
        build_all()

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_interior()
    build_exterior()
    build_cutaway_sides()
    build_cutaway_top()
    adjust_base_collision()

func build_interior():    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the depth (z-lock)
    var z_lock = thickness / 2.0
    
    # Create our points
    var pointA = Vector2( length / 2.0, 0)
    var pointB = Vector2(-length / 2.0, height)
    
    # Make the face
    var pd = PolyGen.create_zlock_face_shifted(pointA, pointB, z_lock, uv_shift)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(interior_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Interior.mesh = new_mesh

func build_exterior():  
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the depth (z-lock)
    var z_lock = -thickness / 2.0
    
    # Create our points
    var pointA = Vector2(-length / 2.0 + uv_shift.x, 0)
    var pointB = Vector2( length / 2.0 + uv_shift.x, height)
    
    # Make the face
    var pd = PolyGen.create_zlock_face_shifted(pointA, pointB, z_lock, uv_shift)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(exterior_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Exterior.mesh = new_mesh

func build_cutaway_sides():    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the depth (z-lock)
    var z_lock = -thickness / 2.0
    
    # Create our points
    var pointA = Vector2(-thickness / 2.0, 0)
    var pointB = Vector2( thickness / 2.0, height)
    
    # Make the positive X-face
    var pd = PolyGen.create_xlock_face_simple(pointA, pointB, length / 2.0)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # Recreate our points for the negative X-face
    pointA = Vector2( thickness / 2.0, 0)
    pointB = Vector2(-thickness / 2.0, height)
    # Create the negative X-face
    pd = PolyGen.create_xlock_face_simple(pointA, pointB, -length / 2.0)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(cutaway_sides_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $CutawaySides.mesh = new_mesh

func build_cutaway_top():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the depth (z-lock)
    var z_lock = -thickness / 2.0
    
    # Create our points
    var pointA = Vector2(-length / 2.0, -thickness / 2.0)
    var pointB = Vector2(length / 2.0, thickness / 2.0)
    
    # Make the positive X-face
    var pd = PolyGen.create_upward_face(pointA, pointB, height)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(cutaway_top_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $CutawayTop.mesh = new_mesh

func adjust_base_collision():
    # Calculate the new size for the collision box
    var new_size = Vector3(length / 2.0, height / 2.0, thickness / 2.0)
    
    # Reset the foundation back to zero so we know what we're doing
    $Collision.transform.origin = Vector3.ZERO
    $Collision.shape = BoxShape.new()
    $Collision.shape.extents = new_size
    $Collision.translate(Vector3(0, height / 2.0, 0))
