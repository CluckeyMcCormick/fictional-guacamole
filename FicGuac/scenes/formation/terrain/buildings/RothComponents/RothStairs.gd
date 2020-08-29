tool
extends StaticBody

# Required materials
export(Material) var sides_mat
export(Material) var tops_mat

export(float, 1, 10, .25) var x_length = 2 setget set_x_length
export(float, 1, 10, .25) var z_length = 2 setget set_z_length
export(int, 1, 10) var steps = 4 setget set_steps 
export(float, .05, 10, .05) var target_height = .5 setget set_target_height

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
func set_x_length(new_length):
    x_length = new_length
    if Engine.editor_hint:
        build_all()

func set_z_length(new_length):
    z_length = new_length
    if Engine.editor_hint:
        build_all()

func set_steps(new_step_count):
    steps = new_step_count
    if Engine.editor_hint:
        build_all()

func set_target_height(new_target):
    target_height = new_target
    if Engine.editor_hint:
        build_all()

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_tops()
    build_collision()
    build_sides()

func build_tops():
    
    # For the purpose of calculating how high each step should be, we consider
    # there to be 1 extra step, since we stop just BEFORE the height of the
    # foundation
    var height_step = self.target_height / float(self.steps + 1)
    
    # We want the specified number of steps on Z, though
    var z_step = self.z_length / float(self.steps)
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = -self.z_length / 2.0
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -self.x_length / 2.0
    var right_x = self.x_length / 2.0
    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    for i in range(self.steps):
        # Calculate the step height. Calculate with our "current step" as the
        # total steps minus the current count; this has the effect of counting 
        # downard as the steps go on - like stairs!
        var eff_height = float(self.steps - i) * float(height_step)
        # Calculate the z of our step that's closer to the origin
        var near_z = z_base + (float(i) * z_step)
        # Calculate the z of our step that's farther from the origin
        var far_z = z_base + (float(i + 1) * z_step)
        
        # If we're on the final step, automatically set the far z value to the
        # full z length. This will ensure our stair steps fit FULLY into the
        # appropriate length. 
        if i == (self.steps - 1):
            far_z = z_base + self.z_length
        
        # Create the faces for the tops of the stairs
        var pd = PolyGen.create_upward_face(
            Vector2(right_x, far_z), Vector2(left_x, near_z), eff_height
        )
        verts.append_array( pd[PolyGen.VECTOR3_KEY] )
        UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(tops_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $StairTops.mesh = new_mesh

func build_sides():
    
    # For the purpose of calculating how high each step should be, we consider
    # there to be 1 extra step, since we stop just BEFORE the height of the
    # foundation
    var height_step = self.target_height / float(self.steps + 1)
    
    # We want the specified number of steps on Z, though
    var z_step = self.z_length / float(self.steps)
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = -self.z_length / 2.0
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -self.x_length / 2.0
    var right_x = self.x_length / 2.0
    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    for i in range(self.steps):
        # Calculate the upper-step height. Calculate with "current step" as the
        # total steps minus the current count; this has the effect of counting 
        # downard as the steps go on - like stairs!
        var top_height = float(self.steps - i) * float(height_step)
        # We need to do the same thing to caluclate the height, but for the step
        # ahead of us
        var base_height = float(self.steps - (i + 1)) * float(height_step)
        # Calculate the z length of this step
        var z_len = float(i + 1) * z_step
        # Calculate the z of our step that's farther from the origin
        var far_z = z_base + z_len
        
        # If we're on the final step, automatically set the far z value to the
        # full z length. This will ensure our stair steps fit FULLY into the
        # appropriate length. 
        if i == (self.steps - 1):
            far_z = z_base + self.z_length
        
        # Face 1
        var pd = PolyGen.create_xlock_face_simple(
            Vector2(far_z, base_height), Vector2(z_base, top_height), left_x
        )
        verts.append_array( pd[PolyGen.VECTOR3_KEY] )
        UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
        
        # Face 2
        pd = PolyGen.create_zlock_face_simple(
            Vector2(right_x, base_height), Vector2(left_x, top_height), far_z
        )
        verts.append_array( pd[PolyGen.VECTOR3_KEY] )
        UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

        # Face 3
        pd = PolyGen.create_xlock_face_simple(
            Vector2(z_base, base_height), Vector2(far_z, top_height), right_x
        )
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
    $StairSides.mesh = new_mesh


func build_collision():
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = -self.z_length / 2.0
    var z_end = z_base + self.z_length
    var height = self.target_height
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -self.x_length / 2.0
    var right_x = self.x_length / 2.0
    
    var new_shape = ConvexPolygonShape.new()
    var verts = PoolVector3Array()
        
    # Step Triangle 1
    verts.push_back( Vector3(left_x, 0, z_end) )
    verts.push_back( Vector3(left_x, 0, z_base))
    verts.push_back( Vector3(left_x, height, z_base) )
    
    # Step Triangle 2
    verts.push_back( Vector3(right_x, 0, z_end) )
    verts.push_back( Vector3(right_x, 0, z_base) )
    verts.push_back( Vector3(right_x, height, z_base) )
    
    new_shape.set_points(verts)
    $StairCollision.shape = new_shape


