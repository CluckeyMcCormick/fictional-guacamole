tool
extends StaticBody

# Required materials
export(Material) var sides_mat
export(Material) var tops_mat

func build_all(spec_node):
    build_tops(spec_node)
    build_collision(spec_node)
    build_sides(spec_node)
# generate_stairs
# foundation_height
# stair_x_length
# stair_z_length
# stair_steps

func build_tops(spec_node):
    
    # For the purpose of calculating how high each step should be, we consider
    # there to be 1 extra step, since we stop just BEFORE the height of the
    # foundation
    var height_step = spec_node.foundation_height / float(spec_node.stair_steps + 1)
    
    # We want the specified number of steps on x, though
    var z_step = spec_node.stair_z_length / float(spec_node.stair_steps)
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = spec_node.z_size / 2.0
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -spec_node.stair_x_length / 2.0
    var right_x = spec_node.stair_x_length / 2.0
    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    for i in range(spec_node.stair_steps):
        
        # Calculate the step height. Calculate with our "current step" as the
        # total steps minus the current count; this has the effect of counting 
        # downard as the steps go on - like stairs!
        var eff_height = float(spec_node.stair_steps - i) * float(height_step)
        # Calculate the z of our step that's closer to the origin
        var near_z = z_base + (float(i) * z_step)
        # Calculate the z of our step that's farther from the origin
        var far_z = z_base + (float(i + 1) * z_step)
        
        # If we're on the final step, automatically set the far z value to the
        # full z length. This will ensure our stair steps fit FULLY into the
        # appropriate length. 
        if i == (spec_node.stair_steps - 1):
            far_z = z_base + spec_node.stair_z_length
        
        # Step Triangle 1
        verts.push_back( Vector3(left_x, eff_height, near_z) )
        verts.push_back( Vector3(right_x, eff_height, near_z))
        verts.push_back( Vector3(right_x, eff_height, far_z) )
        
        UVs.push_back( Vector2(left_x, near_z) )
        UVs.push_back( Vector2(right_x, near_z) )
        UVs.push_back( Vector2(right_x, far_z) )    
        
        # Step Triangle 2
        verts.push_back( Vector3(left_x, eff_height, far_z) )
        verts.push_back( Vector3(left_x, eff_height, near_z) )
        verts.push_back( Vector3(right_x, eff_height, far_z) )
        UVs.push_back( Vector2(left_x, far_z) )
        UVs.push_back( Vector2(left_x, near_z) )
        UVs.push_back( Vector2(right_x, far_z) )  
    
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

func build_sides(spec_node):
    
    # For the purpose of calculating how high each step should be, we consider
    # there to be 1 extra step, since we stop just BEFORE the height of the
    # foundation
    var height_step = spec_node.foundation_height / float(spec_node.stair_steps + 1)
    
    # We want the specified number of steps on x, though
    var z_step = spec_node.stair_z_length / float(spec_node.stair_steps)
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = spec_node.z_size / 2.0
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -spec_node.stair_x_length / 2.0
    var right_x = spec_node.stair_x_length / 2.0
    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    for i in range(spec_node.stair_steps):
        
        # Calculate the upper-step height. Calculate with "current step" as the
        # total steps minus the current count; this has the effect of counting 
        # downard as the steps go on - like stairs!
        var top_height = float(spec_node.stair_steps - i) * float(height_step)
        # We need to do the same thing to caluclate the height, but for the step
        # ahead of us
        var base_height = float(spec_node.stair_steps - (i + 1)) * float(height_step)
        # Calculate the z of our step that's farther from the origin
        var far_z = z_base + ( float(i + 1) * z_step )
        
        # If we're on the final step, automatically set the far z value to the
        # full z length. This will ensure our stair steps fit FULLY into the
        # appropriate length. 
        if i == (spec_node.stair_steps - 1):
            far_z = z_base + spec_node.stair_z_length
        
        print("\t" + str(i) + " " + str(top_height) + " " + str(base_height))
        
        # Triangle 1
        verts.push_back( Vector3(left_x, top_height, z_base) )
        verts.push_back( Vector3(left_x, top_height, far_z))
        verts.push_back( Vector3(left_x, base_height, far_z) )
        UVs.push_back( Vector2(z_base, top_height) ) 
        UVs.push_back( Vector2(far_z, top_height) )
        UVs.push_back( Vector2(far_z, base_height) )
        
        # Triangle 2
        verts.push_back( Vector3(left_x, top_height, z_base) )
        verts.push_back( Vector3(left_x, base_height, far_z) )
        verts.push_back( Vector3(left_x, base_height, z_base) )
        UVs.push_back( Vector2(z_base, top_height) )
        UVs.push_back( Vector2(far_z, base_height) )
        UVs.push_back( Vector2(z_base, base_height) )
        
        #
        #
        #
        
        # Triangle 3
        verts.push_back( Vector3(left_x, top_height, far_z) )
        verts.push_back( Vector3(right_x, top_height, far_z))
        verts.push_back( Vector3(right_x, base_height, far_z) )
        UVs.push_back( Vector2(left_x, top_height) ) 
        UVs.push_back( Vector2(right_x, top_height) )
        UVs.push_back( Vector2(right_x, base_height) )
        
        # Triangle 4
        verts.push_back( Vector3(left_x, top_height, far_z) )
        verts.push_back( Vector3(right_x, base_height, far_z) )
        verts.push_back( Vector3(left_x, base_height, far_z) )
        UVs.push_back( Vector2(left_x, top_height) )
        UVs.push_back( Vector2(right_x, base_height) )
        UVs.push_back( Vector2(left_x, base_height) )
        
        #
        #
        #
        
        # Triangle 5
        verts.push_back( Vector3(right_x, top_height, far_z) )
        verts.push_back( Vector3(right_x, top_height, z_base))
        verts.push_back( Vector3(right_x, base_height, z_base) )
        UVs.push_back( Vector2(far_z, top_height) ) 
        UVs.push_back( Vector2(z_base, top_height) )
        UVs.push_back( Vector2(z_base, base_height) )
        
        # Triangle 6
        verts.push_back( Vector3(right_x, top_height, far_z) )
        verts.push_back( Vector3(right_x, base_height, z_base) )
        verts.push_back( Vector3(right_x, base_height, far_z) )
        UVs.push_back( Vector2(far_z, top_height) )
        UVs.push_back( Vector2(z_base, base_height) )
        UVs.push_back( Vector2(far_z, base_height) )
    
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


func build_collision(spec_node):
    
    # spec_node.foundation_height
    # spec_node.stair_z_length
    
    # The stairs are positioned at the front of the foundation, so capture the
    # length of the foundation
    var z_base = spec_node.z_size / 2.0
    var z_end = z_base + spec_node.stair_z_length
    
    var height = spec_node.foundation_height
    
    # Pre-calculate our points on the left-and-right-hand side
    var left_x = -spec_node.stair_x_length / 2.0
    var right_x = spec_node.stair_x_length / 2.0
    
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


