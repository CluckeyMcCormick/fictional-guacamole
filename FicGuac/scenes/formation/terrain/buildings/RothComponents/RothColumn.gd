tool
extends StaticBody

export(Material) var top_mat setget set_top
export(Material) var sides_mat setget set_sides

# How long are the sides of the column?
export(float) var side_length = 1 setget set_length
# How tall is this column?
export(float) var height = 2 setget set_height

# Load the PolyGen script
const PolyGen = preload("res://scenes/formation/util/PolyGen.gd")

# What's the minimum length for a column?
const MIN_LEN = 0.01

# What's the minimum height for a column?
const MIN_HEIGHT = 0.01

func _ready():
    # When we enter the scene for the first time, we have to build out the
    # stairs
    self.build_all()

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_top(new_mat):
    top_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_sides(new_mat):
    sides_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_length(new_length):
    # Side length MUST at LEAST be MIN_LEN
    side_length = max(new_length, MIN_LEN)
    if Engine.editor_hint:
        build_all()

func set_height(new_height):
    # Height MUST BE AN ACTUAL POSITIVE value!
    height = max(new_height, MIN_HEIGHT)
    if Engine.editor_hint:
        build_all()

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_top()
    build_sides()
    adjust_base_collision()

func build_sides():    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    # Since the column is a square (top-down, at least), all the points are the
    # same absolute value. We can just precalculate and vary the sign!
    var abs_point = side_length / 2.0
    
    # Points and such
    var pd
    var pointA
    var pointB 
    
    # Face 1: X-Positive
    pointA = Vector2(-abs_point, 0)
    pointB = Vector2( abs_point, height)
    pd = PolyGen.create_xlock_face_simple(pointA, pointB, abs_point)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

    # Face 2: Z-Negative
    pointA = Vector2(-abs_point, 0)
    pointB = Vector2( abs_point, height)
    pd = PolyGen.create_zlock_face_simple(pointA, pointB, -abs_point)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

    # Face 3: X-Negative
    pointA = Vector2( abs_point, 0)
    pointB = Vector2(-abs_point,  height)
    pd = PolyGen.create_xlock_face_simple(pointA, pointB, -abs_point)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # Face 4: Z-Positive
    pointA = Vector2( abs_point, 0)
    pointB = Vector2(-abs_point, height)
    pd = PolyGen.create_zlock_face_simple(pointA, pointB, abs_point)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(sides_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Sides.mesh = new_mesh

func build_top():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the height (y-lock)
    var y_lock = height / 2.0
    # Since the column is a square (top-down, at least), all the points are the
    # same absolute value. We can just precalculate and vary the sign!
    var abs_point = side_length / 2.0
    
    # Create our points
    var pointA = Vector2(-abs_point, -abs_point)
    var pointB = Vector2( abs_point,  abs_point)
    
    # Make the upward Y-face
    var pd = PolyGen.create_ylock_face_simple(pointA, pointB, height)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(top_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Top.mesh = new_mesh

func adjust_base_collision():
    # Calculate the new size for the collision box
    var new_size = Vector3(side_length / 2.0, height / 2.0, side_length / 2.0)
    
    # Reset the foundation back to zero so we know what we're doing
    $Collision.transform.origin = Vector3.ZERO
    $Collision.shape = BoxShape.new()
    $Collision.shape.extents = new_size
    $Collision.translate(Vector3(0, height / 2.0, 0))
