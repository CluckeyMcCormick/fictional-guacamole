tool
extends StaticBody

# Required materials
export(Material) var gable_mat setget set_gable_mat
export(Material) var sheeting_mat setget set_sheeting_mat
export(Material) var sideboard_mat setget set_sideboard_mat
export(Material) var longboard_mat setget set_longboard_mat
export(Material) var underboard_mat setget set_underboard_mat

# How long is the roof on x?
export(float) var x_length = 10 setget set_x_length
# How long is the roof on z?
export(float) var z_length = 5 setget set_z_length
# How tall is the gable roof?
export(float) var gable_height = 1 setget set_gable_height
# How thick/tall is the fascia?
export(float) var fascia_height = .25 setget set_fascia_height
# In total, how much do the fascia overhang from the roof, on x?
export(float) var overhang_x = .5 setget set_overhang_x
# In total, how much do the fascia overhang from the roof, on z?
export(float) var overhang_z = .5 setget set_overhang_z

# Should we update the polygon anytime something is updated?
export(bool) var update_on_value_change = true

# Load the PolyGen script
const PolyGen = preload("res://scenes/formation/util/PolyGen.gd")

# In order to build out the collision shape for the fascia/roof matter, we need
# to build the faces individually. But can't just tear the information out of
# the array mesh - so we're gonna save all the faces to this pool as we go on.
var _fascia_faces_pool = null

# What's the minimum length for a side?
const MIN_LEN = 0.01
# What's the minimum height for the steps?
const MIN_GABLE_HEIGHT = 0.01
# What's the minimum height/thickness of the fascia?
const MIN_FASCIA_HEIGHT = 0.01
# What's the minimum overhang of the fascia?
const MIN_FASCIA_OVERHANG = 0.01

# Called when the node enters the scene tree for the first time.
func _ready():
    build_all()

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_gable_mat(new_mat):
    gable_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_sheeting_mat(new_mat):
    sheeting_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_longboard_mat(new_mat):
    longboard_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_sideboard_mat(new_mat):
    sideboard_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()      

func set_underboard_mat(new_mat):
    underboard_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()      

func set_x_length(new_length):
    # Length MUST at LEAST be MIN_LEN
    x_length = max(new_length, MIN_LEN)
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_z_length(new_length):
    # Length MUST at LEAST be MIN_LEN
    z_length = max(new_length, MIN_LEN)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_gable_height(new_height):
    # Height MUST at LEAST be MIN_HEIGHT
    gable_height = max(new_height, MIN_GABLE_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_fascia_height(new_height):
    fascia_height = max(new_height, MIN_FASCIA_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_overhang_x(new_len):
    overhang_x = max(new_len, MIN_FASCIA_OVERHANG)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_overhang_z(new_len):
    overhang_z = max(new_len, MIN_FASCIA_OVERHANG)
    if Engine.editor_hint and update_on_value_change:
        build_all()

# --------------------------------------------------------
#
# Utility Functions
#
# --------------------------------------------------------

# Given z, gets the height (y-value) for the top of the roof - the top matter,
# the sheeting. It's a very basic line-slope equation; this utility method just
# encapsulates the line and makes thing easier.
func get_sheeting_height(z_pos):
    var shift = self.gable_height + self.fascia_height
    var slope = self.gable_height / (self.z_length / 2.0)
    
    var out_pos
    
    if z_pos > 0:
        out_pos = (-slope * z_pos) + shift
    elif z_pos == 0:
        out_pos = shift
    else:
        out_pos = ( slope * z_pos) + shift
    
    return out_pos

# Ditto the above, but for the bottom of the fascia.
func get_fascia_height(z_pos):
    var shift = self.gable_height
    var slope = self.gable_height / (self.z_length / 2.0)
  
    var out_pos
  
    if z_pos > 0:
        out_pos = (-slope * z_pos) + shift
    elif z_pos == 0:
        out_pos = shift
    else:
        out_pos = ( slope * z_pos) + shift
    
    return out_pos

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    # Prepare our fascia pool so that we can build faces easily
    _fascia_faces_pool = PoolVector3Array()
    build_gables()
    build_sheeting()
    build_fascia_longboard()
    build_fascia_sideboard()
    build_fascia_underboard()
    build_collision()
    # We're all done with the fascia faces - clear em out!
    _fascia_faces_pool = null

func build_gables():    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("Gables"):
        return

    # The gable consists of two triangles facing in opposite directions. They
    # are connected by a downward facing surface that the user generally won't
    # see but is needed to block light from breaking upward through the wall.
    #
    #       C         B ------------ E         F
    #     /   \       |              |       /   \ 
    #    /     \      |              |      /     \
    #   /       \     |              |     /       \
    #  B---------A    A ------------ D    D---------E
    #
    # B & A are at -x_edge. E & D are at x_edge. D & A are at z_edge. E & B are
    # at -z_edge.

    # Calculate where the edges go
    var x_edge = self.x_length / 2.0
    var z_edge = self.z_length / 2.0
    
    # Calculate our points
    var v3_A = Vector3(-x_edge, 0,  z_edge)
    var v3_B = Vector3(-x_edge, 0, -z_edge)
    var v3_C = Vector3(-x_edge, self.gable_height, 0)
    
    var v3_D = Vector3(x_edge, 0,  z_edge)
    var v3_E = Vector3(x_edge, 0, -z_edge)
    var v3_F = Vector3(x_edge, self.gable_height, 0)
    
    var v2_E = Vector2(v3_E.x, v3_E.z)
    var v2_A = Vector2(v3_A.x, v3_A.z)
    
    # Triangle 1 - ABC
    verts.append( v3_A ) # A
    verts.append( v3_B ) # B
    verts.append( v3_C ) # C
    UVs.append( Vector2( z_edge, 0) ) # A
    UVs.append( Vector2(-z_edge, 0) ) # B
    UVs.append( Vector2( 0, self.gable_height) ) # C

    # Triangle 2 - EDF
    verts.append( v3_E ) # E
    verts.append( v3_D ) # D
    verts.append( v3_F ) # F
    UVs.append( Vector2( z_edge, 0) ) # E
    UVs.append( Vector2(-z_edge, 0) ) # D
    UVs.append( Vector2( 0, self.gable_height) ) # F
    
    # Face 3/4 - BD
    var pd = PolyGen.create_ylock_face_simple(v2_E, v2_A, 0)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(gable_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Gables.mesh = new_mesh

func build_sheeting():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("Sheeting"):
        return

    # The sheeting is the top-matter of the roof - generally the shingles or
    # what-have you. Polygonally speaking, this takes the form of two large
    # faces, facing opposite directions but sloped inward towards each other
    # such that they meet at the top. One faces z-positive, the other faces
    # z-negative. It should look something like this:
    #
    # C-------------B B-------------C   D------C------E
    # |             | |             |   |      |      |
    # | Z-Posi Face | | Z-Negi Face |   |  +Z  |  -Z  |
    # |             | |             |   |      |      |
    # D-------------A F-------------E   A------B------F

    # Calculate where the edges go
    var x_edge = (self.x_length / 2.0) + (self.overhang_x / 2.0)
    var z_edge = (self.z_length / 2.0) + (self.overhang_z / 2.0)
    var sheet_peak = self.get_sheeting_height(0)
    var sheet_base = self.get_sheeting_height(z_edge)
    
    # Create our points - In 3D!
    var v3_A = Vector3( x_edge, sheet_base, z_edge)
    var v3_D = Vector3(-x_edge, sheet_base, z_edge)    
    
    var v3_B = Vector3( x_edge, sheet_peak, 0)
    var v3_C = Vector3(-x_edge, sheet_peak, 0)
    
    var v3_E = Vector3(-x_edge, sheet_base, -z_edge)
    var v3_F = Vector3( x_edge, sheet_base, -z_edge)
    
    # Because the sheeting is a slope, we can't just use "height" - we need to
    # actually calculate the distance to our base. Fortunately that's as easy as
    # calculating the distance from a peak point to any base point, or vice
    # versa!
    var peak_dist = v3_A.distance_to(v3_B)
    
    # Create our TEXTURE POINTS!
    var v2_A = Vector2( x_edge, 0)
    var v2_D = Vector2(-x_edge, 0)
    
    var v2_B = Vector2( x_edge, -peak_dist)
    var v2_C = Vector2(-x_edge, -peak_dist)
    
    var v2_E = Vector2(-x_edge, 0)
    var v2_F = Vector2( x_edge, 0)
    
    # Triangle 1 - ACB
    verts.append( v3_A ) # A
    verts.append( v3_C ) # C
    verts.append( v3_B ) # B
    UVs.append( v2_A ) # A
    UVs.append( v2_C ) # C
    UVs.append( v2_B ) # B

    # Triangle 2 - ADC
    verts.append( v3_A ) # A
    verts.append( v3_D ) # D
    verts.append( v3_C ) # C
    UVs.append( v2_A ) # A
    UVs.append( v2_D ) # D
    UVs.append( v2_C ) # C
    
    # Triangle 3 - EBC
    verts.append( v3_E ) # E
    verts.append( v3_B ) # B
    verts.append( v3_C ) # C
    UVs.append( v2_E ) # E
    UVs.append( v2_B ) # B
    UVs.append( v2_C ) # C

    # Triangle 4 - EFB
    verts.append( v3_E ) # E
    verts.append( v3_F ) # F
    verts.append( v3_B ) # B
    UVs.append( v2_E ) # E
    UVs.append( v2_F ) # F
    UVs.append( v2_B ) # B
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(sheeting_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])
        _fascia_faces_pool.append(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $Sheeting.mesh = new_mesh

func build_fascia_longboard():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("Sheeting"):
        return

    # The fascia is the bracing/boards that go below the top-matter of the roof;
    # for our purposes, it is essentially the "meat" or "bulk" of the roof. It
    # serves to connect the sheeting to the gables.
    #
    # The fascia longboards are the... long... boards... that face Z. It's
    # actually pretty simple - we just need two z-locked faces.
    # 
    # B------------------------+        D------------------------+
    # |                        |        |                        |
    # |       Z-Posi Face      |        |       Z-Negi Face      | 
    # |                        |        |                        |
    # +------------------------A        +------------------------C

    var height = 1

    # Calculate where the edges go
    var fascia_x_edge = (self.x_length / 2.0) + (self.overhang_x / 2.0)
    var fascia_z_edge = (self.z_length / 2.0) + (self.overhang_z / 2.0)
    var gable_x_edge = self.x_length / 2.0
    var gable_z_edge = self.z_length / 2.0
    
    var fascia_peak = self.get_sheeting_height(fascia_z_edge)
    var fascia_base = self.get_fascia_height(fascia_z_edge)
    
    # Create our TEXTURE POINTS!
    var v2_A = Vector2( fascia_x_edge, fascia_base)
    var v2_B = Vector2(-fascia_x_edge, fascia_peak)
    
    var v2_C = Vector2(-fascia_x_edge, fascia_base)
    var v2_D = Vector2( fascia_x_edge, fascia_peak)
    
    # Face 1/2 - AB
    var pd = PolyGen.create_zlock_face_simple(v2_A, v2_B, fascia_z_edge)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )

    # Face 3/4 - CD
    pd = PolyGen.create_zlock_face_simple(v2_C, v2_D, -fascia_z_edge)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(longboard_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])
        _fascia_faces_pool.append(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FasciaLongboard.mesh = new_mesh

func build_fascia_underboard():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("FasciaUnderboard"):
        return

    # The fascia is the bracing/boards that go below the top-matter of the roof;
    # for our purposes, it is essentially the "meat" or "bulk" of the roof. It
    # serves to connect the sheeting to the gables.
    #
    # The sideboards are the catchall term for the parts of the fascia that are
    # either on the side (x-facing) or form the underside (y-facing). Like the
    # sheeting, the structure is zymmetrical about the z-axis. It's a bit
    # hard to illustrate, but here's my best shot:
    # 
    # D------C------B
    # |      |      |
    # |      |      |
    # |  +Z  |  -Z  |
    # |      |      |
    # |      |      |
    # E------F------A

    var height = 1

    # Calculate where the edges go
    var x_edge = (self.x_length / 2.0) + (self.overhang_x / 2.0)
    var z_edge = (self.z_length / 2.0) + (self.overhang_z / 2.0)
    
    var lower_base = self.get_fascia_height(z_edge)
    var lower_peak = self.get_fascia_height(0)
    
    var upper_base = self.get_sheeting_height(z_edge)
    var upper_peak = self.get_sheeting_height(0)
    
    # Create our points - In 3D!
    var v3_A = Vector3( x_edge, lower_base, -z_edge)
    var v3_F = Vector3( x_edge, lower_peak, 0)
    var v3_E = Vector3( x_edge, lower_base,  z_edge)

    var v3_D = Vector3(-x_edge, lower_base,  z_edge)
    var v3_C = Vector3(-x_edge, lower_peak,  0)
    var v3_B = Vector3(-x_edge, lower_base, -z_edge)
    
    # Now we need to create the texture coordinates. In order to do that, we
    # need to know the length from the peak to the base. We can do that with any
    # of the points, really, but we'll do it with F & A
    var peak_dist = v3_A.distance_to(v3_F)
    
    # Since we're facing multiple directions, we're actually just going to
    # create the Vector2's as we go along.
    
    #
    # Underside ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    
    # Triangle 1 - BCA
    verts.append( v3_B ) # B
    verts.append( v3_C ) # C
    verts.append( v3_A ) # A
    UVs.append( Vector2(-x_edge, 0) ) # B
    UVs.append( Vector2(-x_edge, -peak_dist) ) # C
    UVs.append( Vector2( x_edge, 0) ) # A

    # Triangle 2 - CFA
    verts.append( v3_C ) # C
    verts.append( v3_F ) # F
    verts.append( v3_A ) # A
    UVs.append( Vector2(-x_edge, -peak_dist) ) # C
    UVs.append( Vector2( x_edge, -peak_dist) ) # F
    UVs.append( Vector2( x_edge, 0) ) # A
    
    # Triangle 3 - CDF
    verts.append( v3_C ) # C
    verts.append( v3_D ) # D
    verts.append( v3_F ) # F
    UVs.append( Vector2(-x_edge, -peak_dist) ) # C
    UVs.append( Vector2(-x_edge, 0) ) # D
    UVs.append( Vector2( x_edge, -peak_dist) ) # F
    
    # Triangle 4 - DEF
    verts.append( v3_D ) # D
    verts.append( v3_E ) # E
    verts.append( v3_F ) # F
    UVs.append( Vector2(-x_edge, 0) ) # D
    UVs.append( Vector2( x_edge, 0) ) # E
    UVs.append( Vector2( x_edge, -peak_dist) ) # F
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(underboard_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])
        _fascia_faces_pool.append(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FasciaUnderboard.mesh = new_mesh

func build_fascia_sideboard():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("FasciaSideboard"):
        return

    # The fascia is the bracing/boards that go below the top-matter of the roof;
    # for our purposes, it is essentially the "meat" or "bulk" of the roof. It
    # serves to connect the sheeting to the gables.
    #
    # The sideboards are the catchall term for the parts of the fascia that are
    # either on the side (x-facing) or form the underside (y-facing). Like the
    # sheeting, the structure is zymmetrical about the z-axis. It's a bit
    # hard to illustrate, but here's my best shot:
    # 
    #    H           K
    #   /|\         /|\
    #  / | \       / | \
    # I  F  G     L  C  J
    # | / \ |     | / \ |
    # |/   \|     |/   \|
    # E     A     B     D 

    var height = 1

    # Calculate where the edges go
    var x_edge = (self.x_length / 2.0) + (self.overhang_x / 2.0)
    var z_edge = (self.z_length / 2.0) + (self.overhang_z / 2.0)
    
    var lower_base = self.get_fascia_height(z_edge)
    var lower_peak = self.get_fascia_height(0)
    
    var upper_base = self.get_sheeting_height(z_edge)
    var upper_peak = self.get_sheeting_height(0)
    
    # Create our points - In 3D!
    var v3_A = Vector3( x_edge, lower_base, -z_edge)
    var v3_F = Vector3( x_edge, lower_peak, 0)
    var v3_E = Vector3( x_edge, lower_base,  z_edge)
    
    var v3_G = Vector3( x_edge, upper_base, -z_edge)
    var v3_H = Vector3( x_edge, upper_peak, 0)
    var v3_I = Vector3( x_edge, upper_base,  z_edge)

    var v3_D = Vector3(-x_edge, lower_base,  z_edge)
    var v3_C = Vector3(-x_edge, lower_peak,  0)
    var v3_B = Vector3(-x_edge, lower_base, -z_edge)
    
    var v3_J = Vector3(-x_edge, upper_base,  z_edge)
    var v3_K = Vector3(-x_edge, upper_peak,  0)
    var v3_L = Vector3(-x_edge, upper_base, -z_edge)
    
    # Now we need to create the texture coordinates. In order to do that, we
    # need to know the length from the peak to the base. We can do that with any
    # of the points, really, but we'll do it with F & A
    var peak_dist = v3_A.distance_to(v3_F)
    
    # Since we're facing multiple directions, we're actually just going to
    # create the Vector2's as we go along.
    
    #
    # X Facing, Positive ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    
    # Triangle 1 - AHG
    verts.append( v3_A ) # A
    verts.append( v3_H ) # H
    verts.append( v3_G ) # G
    UVs.append( Vector2(0, 0) ) # A
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # H
    UVs.append( Vector2(0, -self.fascia_height) ) # G
    
    # Triangle 2 - AFH
    verts.append( v3_A ) # A
    verts.append( v3_F ) # F
    verts.append( v3_H ) # H
    UVs.append( Vector2(0, 0) ) # A
    UVs.append( Vector2(peak_dist, 0) ) # F
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # H
    
    # Triangle 3 - FIH
    verts.append( v3_F) # F
    verts.append( v3_I ) # I
    verts.append( v3_H ) # H
    UVs.append( Vector2(peak_dist, 0) ) # F
    UVs.append( Vector2(0, -self.fascia_height) ) # I
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # H
    
    # Triangle 4 - FEI
    verts.append( v3_F) # F
    verts.append( v3_E ) # E
    verts.append( v3_I ) # I
    UVs.append( Vector2(peak_dist, 0) ) # F
    UVs.append( Vector2(0, 0) ) # E
    UVs.append( Vector2(0, -self.fascia_height) ) # I
    
    #
    # X Facing, Negative ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    
    # Triangle 5 - DKJ
    verts.append( v3_D ) # D
    verts.append( v3_K ) # K
    verts.append( v3_J ) # J
    UVs.append( Vector2(0, 0) ) # D
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # K
    UVs.append( Vector2(0, -self.fascia_height) ) # J
    
    # Triangle 6 - DCK
    verts.append( v3_D ) # D
    verts.append( v3_C ) # C
    verts.append( v3_K ) # K
    UVs.append( Vector2(0, 0) ) # D
    UVs.append( Vector2(peak_dist, 0) ) # C
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # K
    
    # Triangle 7 - CLK
    verts.append( v3_C ) # C
    verts.append( v3_L ) # L
    verts.append( v3_K ) # K
    UVs.append( Vector2(peak_dist, 0) ) # C
    UVs.append( Vector2(0, -self.fascia_height) ) # L
    UVs.append( Vector2(peak_dist, -self.fascia_height) ) # K
    
    # Triangle 8 - CBL
    verts.append( v3_C ) # C
    verts.append( v3_B ) # B
    verts.append( v3_L ) # L
    UVs.append( Vector2(peak_dist, 0) ) # C
    UVs.append( Vector2(0, 0) ) # B
    UVs.append( Vector2(0, -self.fascia_height) ) # L
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(sideboard_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])
        _fascia_faces_pool.append(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $FasciaSideboard.mesh = new_mesh

func build_collision():
    var verts = PoolVector3Array()

    # If we don't have gables (somwhow?!?!), back out
    if not has_node("GableCollision") or not has_node("FasciaCollision"):
        return
    
    $GableCollision.make_convex_from_brothers()
    
    var new_shape = ConcavePolygonShape.new()
    new_shape.set_faces(_fascia_faces_pool)
    $FasciaCollision.shape = new_shape
