tool
extends StaticBody

# Required materials
export(Material) var wall_mat
export(Material) var doorframe_mat
export(Material) var floor_mat

export(int, 5, 20) var x_size = 10 setget set_x_size
export(int, 5, 20) var z_size = 5 setget set_z_size
export(float, .05, 1, .05) var frame_thickness = .5 setget set_frame_thickness
export(float, .05, 1, .05) var foundation_height = .5 setget set_foundation_height

# Load the PolyGen script
const PolyGen = preload("res://scenes/formation/util/PolyGen.gd")

func _ready():
    # When we enter the scene for the first time, we have to build out the
    # foundation
    self.build_all()

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_x_size(new_x):
    x_size = new_x
    if Engine.editor_hint:
        build_all()

func set_z_size(new_z):
    z_size = new_z
    if Engine.editor_hint:
        build_all()

func set_frame_thickness(new_thickness):
    frame_thickness = new_thickness
    if Engine.editor_hint:
        build_all()

func set_foundation_height(new_height):
    foundation_height = new_height
    if Engine.editor_hint:
        build_all()

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_floor()
    build_frame()
    build_wall()
    adjust_base_collision()

func build_floor():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    var dheight = self.foundation_height
    var dx_size = (self.x_size - (self.frame_thickness * 2)) / 2.0
    var dz_size = (self.z_size - (self.frame_thickness * 2)) / 2.0
    
    # Create the vertex and UV points
    var points = PolyGen.create_upward_face(
        Vector2(dx_size, dz_size), Vector2(-dx_size, -dz_size), dheight
    )
    # Unpack the dictionary we got back
    UVs = points[ PolyGen.VECTOR2_KEY ]
    verts = points[ PolyGen.VECTOR3_KEY ]   

    # Start making a new surface
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(floor_mat)

    # Iterate through our points, adding them
    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    # Generate stuff I'm too lazy to do manually
    st.generate_normals()
    st.generate_tangents()

    # Commit our mesh - we're done here!
    st.commit(new_mesh)
    $FoundationFloor.mesh = new_mesh

func build_frame():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    #
    # We're gonna make a square with a missing section, as illustrated below:
    # 
    #   8 D---C---------------B---+
    #     |   |               |   |
    #   7 |---+---------------G---|            
    #     |   |               |   |
    #     |   |               |   |
    #     |   |               |   |
    #   6 |---H---------------+---+
    #     |   |               |   |
    #   5 +---E---------------F---A
    #     1   2               3   4
    #
    # Our Faces are:                   Our points are:
    # (A, B)                           1:  -x_size / 2
    # (G, C)                           2: (-x_size / 2) + frame_thickness
    # (E, D)                           3: ( x_size / 2) - frame_thickness
    # (F, H)                           4:   x_size / 2
    #                                  5:  -z_size / 2
    #                                  6: (-z_size / 2) + frame_thickness
    #                                  7: ( z_size / 2) - frame_thickness
    #                                  8:   z_size / 2
    
    # What's the height of the foundation?
    var dheight = self.foundation_height
    
    # What's the location of the various x points?
    var x1 = -self.x_size / 2.0
    var x2 = (-self.x_size / 2.0) + self.frame_thickness
    var x3 = (self.x_size / 2.0) - self.frame_thickness
    var x4 = self.x_size / 2.0
    # What's the location of the various z points?
    var z5 = self.z_size / 2.0
    var z6 = (self.z_size / 2.0) - self.frame_thickness
    var z7 = (-self.z_size / 2.0) + self.frame_thickness
    var z8 = -self.z_size / 2.0

    # Vector 2 Points
    var point_A_2 = Vector2( x4, z5)
    var point_B_2 = Vector2( x3, z8)
    var point_C_2 = Vector2( x2, z8)
    var point_D_2 = Vector2( x1, z8)
    var point_E_2 = Vector2( x2, z5)
    var point_F_2 = Vector2( x3, z5)
    var point_G_2 = Vector2( x3, z7)
    var point_H_2 = Vector2( x2, z6)
    
    # Dictionary of points - for making faces!
    var pd
    
    # Face 1
    pd = PolyGen.create_upward_face(point_A_2, point_B_2, dheight)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # Face 2
    pd = PolyGen.create_upward_face(point_G_2, point_C_2, dheight)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

    # Face 3
    pd = PolyGen.create_upward_face(point_E_2, point_D_2, dheight)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # Face 4
    pd = PolyGen.create_upward_face(point_F_2, point_H_2, dheight)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(doorframe_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FoundationFrame.mesh = new_mesh

func build_wall():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    # This is our first truly 3D component, so we'll cut it int two layers. Both
    # layers look like this from the top down:
    #
    #       1----------4
    #       |          |
    #       |          |
    #       2----------3
    #
    # So we'll call the bottom Layer A, and the top layer B. Our polygons thusly
    # look like:
    #        B1------B2------------------B3------B4------------------B1
    #        ||      ||                  ||      ||                  ||
    #        A1------A2------------------A3------A4------------------A1
    # So our faces are:
    #       (A2, B1)    (A3, B2)    (A4, B3)    (A1, B4)
    
    var dheight = self.foundation_height
    var dx_size = self.x_size
    var dz_size = self.z_size
    
    # Face 1: A2 -> B1
    var pd = PolyGen.create_xlock_face_linear(
        Vector2(dz_size / 2.0, 0), Vector2(-dz_size / 2.0, dheight), # A & B
        -dx_size / 2.0, # X-Lock Position
        (dz_size * 1), 0 # UV Horizontal Coords
    )
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )    
    
    # Face 2: A3 -> B2
    pd = PolyGen.create_zlock_face_linear(
        Vector2(dx_size / 2.0, 0), Vector2(-dx_size / 2.0, dheight), # A & B
        dz_size / 2.0, # Z-Lock Position
        (dz_size * 1) + (dx_size * 1), (dz_size * 1) # UV Horizontal Coords
    )
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )   
    
    # Face 3: A4 -> B3
    pd = PolyGen.create_xlock_face_linear(
        Vector2(-dz_size / 2.0, 0), Vector2(dz_size / 2.0, dheight), # A & B
        dx_size / 2.0, # X-Lock Position
        (dz_size * 2) + (dx_size * 1),  (dz_size * 1) + (dx_size * 1)
    )
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )    

    # Face 4: A1 -> B4
    pd = PolyGen.create_zlock_face_linear(
        Vector2(-dx_size / 2.0, 0), Vector2(dx_size / 2.0, dheight), # A & B
        -dz_size / 2.0, # Z-Lock Position
        (dz_size * 2) + (dx_size * 2), (dz_size * 2) + (dx_size * 1)
    )
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )    

    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(wall_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FoundationWall.mesh = new_mesh

func adjust_base_collision():
    var dheight = self.foundation_height
    var dx_size = self.x_size
    var dz_size = self.z_size
    
    var new_size = Vector3(dx_size / 2.0, dheight / 2.0, dz_size / 2.0)
    
    # Reset the foundation back to zero so we know what we're doing
    $FoundationCollision.transform.origin = Vector3.ZERO
    $FoundationCollision.shape = BoxShape.new()
    $FoundationCollision.shape.extents = new_size
    $FoundationCollision.translate(Vector3(0, dheight / 2.0, 0))
