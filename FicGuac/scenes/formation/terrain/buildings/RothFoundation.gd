tool
extends StaticBody

# Required materials
export(Material) var wall_mat
export(Material) var doorframe_mat
export(Material) var floor_mat

func build_all(spec_node):
    build_floor(spec_node)
    build_frame(spec_node)
    build_wall(spec_node)
    adjust_base_collision(spec_node)
    pass

func build_floor(spec_node):
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    var height = spec_node.foundation_height
    var x_size = spec_node.x_size - (spec_node.wall_thickness * 2)
    var z_size = spec_node.z_size - (spec_node.wall_thickness * 2)
    
    var vec3_p1 = Vector3(x_size / 2.0, height, -z_size / 2.0)
    var vec2_p1 = Vector2(x_size / 2.0, -z_size / 2.0)
    
    var vec3_p2 = Vector3(x_size / 2.0, height, z_size / 2.0)
    var vec2_p2 = Vector2(x_size / 2.0, z_size / 2.0)
    
    var vec3_p3 = Vector3(-x_size / 2.0, height, z_size / 2.0)
    var vec2_p3 = Vector2(-x_size / 2.0, z_size / 2.0)
    
    var vec3_p4 = Vector3(-x_size / 2.0, height, -z_size / 2.0) 
    var vec2_p4 = Vector2(-x_size / 2.0, -z_size / 2.0)
    
    # Triangle 1
    verts.push_back( vec3_p1)
    verts.push_back( vec3_p2 )
    verts.push_back( vec3_p3 )
    UVs.push_back( vec2_p1 )
    UVs.push_back( vec2_p2 )
    UVs.push_back( vec2_p3 )
    
    # Triangle 2
    verts.push_back( vec3_p1 )
    verts.push_back( vec3_p3 )
    verts.push_back( vec3_p4 )
    UVs.push_back( vec2_p1 )
    UVs.push_back( vec2_p3 )
    UVs.push_back( vec2_p4 )
   
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(floor_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FoundationFloor.mesh = new_mesh

func build_frame(spec_node):
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    #
    # We're gonna make a square with a missing section, as illustrated below:
    # 
    #   8 E---D---------------C---B
    #     |   |               |   |
    #   7 |---K---------------J---|            
    #     |   |               |   |
    #     |   |               |   |
    #     |   |               |   |
    #   6 |---L---------------I---|
    #     |   |               |   |
    #   5 F---G---------------H---A
    #     1   2               3   4
    #
    # Our triangles are:               Our points are:
    # (A, B, C)                        1:  -x_size / 2
    # (A, C, H)                        2: (-x_size / 2) + wall_thickness
    # (J, C, D)                        3: ( x_size / 2) - wall_thickness
    # (J, D, K)                        4:   x_size / 2
    # (G, D, E)                        5:  -z_size / 2
    # (G, E, F)                        6: (-z_size / 2) + wall_thickness
    # (H, I, L)                        7: ( z_size / 2) - wall_thickness
    # (H, L, G)                        8:   z_size / 2
    
    # What's the height of the foundation?
    var height = spec_node.foundation_height
    
    # What's the location of the various x points?
    var x1 = -spec_node.x_size / 2.0
    var x2 = (-spec_node.x_size / 2.0) + spec_node.wall_thickness
    var x3 = (spec_node.x_size / 2.0) - spec_node.wall_thickness
    var x4 = spec_node.x_size / 2.0
    # What's the location of the various z points?
    var z5 = -spec_node.z_size / 2.0
    var z6 = (-spec_node.z_size / 2.0) + spec_node.wall_thickness
    var z7 = (spec_node.z_size / 2.0) - spec_node.wall_thickness
    var z8 = spec_node.z_size / 2.0
    
    # Vector 3 Points
    var point_A_3 = Vector3( x4, height, z5)
    var point_B_3 = Vector3( x4, height, z8)
    var point_C_3 = Vector3( x3, height, z8)
    var point_D_3 = Vector3( x2, height, z8)
    var point_E_3 = Vector3( x1, height, z8)
    var point_F_3 = Vector3( x1, height, z5)
    var point_G_3 = Vector3( x2, height, z5)
    var point_H_3 = Vector3( x3, height, z5)
    var point_I_3 = Vector3( x3, height, z6)
    var point_J_3 = Vector3( x3, height, z7)
    var point_K_3 = Vector3( x2, height, z7)
    var point_L_3 = Vector3( x2, height, z6)

    # Vector 2 Points
    var point_A_2 = Vector2( x4, z5)
    var point_B_2 = Vector2( x4, z8)
    var point_C_2 = Vector2( x3, z8)
    var point_D_2 = Vector2( x2, z8)
    var point_E_2 = Vector2( x1, z8)
    var point_F_2 = Vector2( x1, z5)
    var point_G_2 = Vector2( x2, z5)
    var point_H_2 = Vector2( x3, z5)
    var point_I_2 = Vector2( x3, z6)
    var point_J_2 = Vector2( x3, z7)
    var point_K_2 = Vector2( x2, z7)
    var point_L_2 = Vector2( x2, z6)
    
    # Triangle 1 (A, B, C)
    verts.push_back( point_A_3)
    verts.push_back( point_B_3 )
    verts.push_back( point_C_3 )
    UVs.push_back( point_A_2 )
    UVs.push_back( point_B_2 )
    UVs.push_back( point_C_2 )
    
    # Triangle 2 (A, C, H)
    verts.push_back( point_A_3 )
    verts.push_back( point_C_3 )
    verts.push_back( point_H_3 )
    UVs.push_back( point_A_2 )
    UVs.push_back( point_C_2 )
    UVs.push_back( point_H_2 )
   
    # Triangle 3 (J, C, D)
    verts.push_back( point_J_3 )
    verts.push_back( point_C_3 )
    verts.push_back( point_D_3 )
    UVs.push_back( point_J_2 )
    UVs.push_back( point_C_2 )
    UVs.push_back( point_D_2 )

    # Triangle 4 (J, D, K)
    verts.push_back( point_J_3 )
    verts.push_back( point_D_3 )
    verts.push_back( point_K_3 )
    UVs.push_back( point_J_2 )
    UVs.push_back( point_D_2 )
    UVs.push_back( point_K_2 )
    
    # Triangle 5 (G, D, E)
    verts.push_back( point_G_3 )
    verts.push_back( point_D_3 )
    verts.push_back( point_E_3 )
    UVs.push_back( point_G_2 )
    UVs.push_back( point_D_2 )
    UVs.push_back( point_E_2 )
    
    # Triangle 6 (G, E, F)
    verts.push_back( point_G_3 )
    verts.push_back( point_E_3 )
    verts.push_back( point_F_3 )
    UVs.push_back( point_G_2 )
    UVs.push_back( point_E_2 )
    UVs.push_back( point_F_2 )
    
    # Triangle 7 (H, I, L)
    verts.push_back( point_H_3 )
    verts.push_back( point_I_3 )
    verts.push_back( point_L_3 )
    UVs.push_back( point_H_2 )
    UVs.push_back( point_I_2 )
    UVs.push_back( point_L_2 )
    
    # Triangle 8 (H, L, G)
    verts.push_back( point_H_3 )
    verts.push_back( point_L_3 )
    verts.push_back( point_G_3 )
    UVs.push_back( point_H_2 )
    UVs.push_back( point_L_2 )
    UVs.push_back( point_G_2 )

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

func build_wall(spec_node):
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    # This is our first truly 3D component, so we'll cut it int two layers. Both
    # layers look like this from the top down:
    #
    #       1          4
    #       |          |
    #       |          |
    #       2----------3
    #
    # So we'll call the bottom Layer A, and the top layer B. Our polygons thusly
    # look like:
    #               B1------B2------------------B3------B4
    #               ||      ||                  ||      ||
    #               A1------A2------------------A3------A4
    # So our triangles are:
    #       (A2, B2, B1)    (A2, B1, A1)
    #       (A3, B3, B2)    (A3, B2, A2)
    #       (A4, B4, B3)    (A4, B3, A3)
    #
    
    var height = spec_node.foundation_height
    var x_size = spec_node.x_size
    var z_size = spec_node.z_size
    
    var A1_3 = Vector3(-x_size / 2.0, 0, -z_size / 2.0)
    var A2_3 = Vector3(-x_size / 2.0, 0,  z_size / 2.0)
    var A3_3 = Vector3( x_size / 2.0, 0,  z_size / 2.0)
    var A4_3 = Vector3( x_size / 2.0, 0,  -z_size / 2.0)
    var B1_3 = A1_3 + Vector3(0, height, 0)
    var B2_3 = A2_3 + Vector3(0, height, 0)
    var B3_3 = A3_3 + Vector3(0, height, 0)
    var B4_3 = A4_3 + Vector3(0, height, 0)
    
    var A1_2 = Vector2(0, 0)
    var A2_2 = Vector2(z_size, 0)
    var A3_2 = Vector2(z_size + x_size, 0)
    var A4_2 = Vector2(z_size + x_size + z_size, 0)
    var B1_2 = A1_2 + Vector2(0, height)
    var B2_2 = A2_2 + Vector2(0, height)
    var B3_2 = A3_2 + Vector2(0, height)
    var B4_2 = A4_2 + Vector2(0, height)   

    # Triangle 1 (A2, B2, B1)
    verts.push_back( A2_3 )
    verts.push_back( B2_3 )
    verts.push_back( B1_3 )
    UVs.push_back( A2_2 )
    UVs.push_back( B2_2 )
    UVs.push_back( B1_2 )
    
    # Triangle 2 (A2, B1, A1)
    verts.push_back( A2_3 )
    verts.push_back( B1_3 )
    verts.push_back( A1_3 )
    UVs.push_back( A2_2 )
    UVs.push_back( B1_2 )
    UVs.push_back( A1_2 )
    
    # Triangle 3 (A3, B3, B2)
    verts.push_back( A3_3 )
    verts.push_back( B3_3 )
    verts.push_back( B2_3 )
    UVs.push_back( A3_2 )
    UVs.push_back( B3_2 )
    UVs.push_back( B2_2 )
    
    # Triangle 4 (A3, B2, A2)
    verts.push_back( A3_3 )
    verts.push_back( B2_3 )
    verts.push_back( A2_3 )
    UVs.push_back( A3_2 )
    UVs.push_back( B2_2 )
    UVs.push_back( A2_2 )
    
    # Triangle 5 (A4, B4, B3)
    verts.push_back( A4_3 )
    verts.push_back( B4_3 )
    verts.push_back( B3_3 )
    UVs.push_back( A4_2 )
    UVs.push_back( B4_2 )
    UVs.push_back( B3_2 )
    
    # Triangle 6 (A4, B3, A3)
    verts.push_back( A4_3 )
    verts.push_back( B3_3 )
    verts.push_back( A3_3 )
    UVs.push_back( A4_2 )
    UVs.push_back( B3_2 )
    UVs.push_back( A3_2 )

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

func adjust_base_collision(spec_node):
    var height = spec_node.foundation_height
    var x_size = spec_node.x_size
    var z_size = spec_node.z_size
    
    var new_size = Vector3(x_size / 2.0, height / 2.0, z_size / 2.0)
    
    # Reset the foundation back to zero so we know what we're doing
    $FoundationBaseCollide.transform.origin = Vector3.ZERO
    $FoundationBaseCollide.shape = BoxShape.new()
    $FoundationBaseCollide.shape.extents = new_size
    $FoundationBaseCollide.translate(Vector3(0, height / 2.0, 0))
