tool
extends StaticBody

export(Material) var cutaway_sides_mat setget set_cutaway_sides
export(Material) var cutaway_caps_mat setget set_cutaway_caps
export(Material) var interior_mat setget set_interior
export(Material) var exterior_mat setget set_exterior

# Sometimes, this procedural component doesn't line up with the textures of it's
# neighbors. This Vector3 should solve that.
export(Vector3) var uv_shift setget set_uv_shift
# How long is the wall?
export(float) var length = 2 setget set_length
# How thick is the wall?
export(float) var thickness = 1 setget set_thickness
# How high is the wall?
export(float) var height = 2 setget set_height

# We may want this construct to appear on a different layer for whatever reason
# (most likely for some shader nonsense). Since that is normally set at the mesh
# level, we'll provide this convenience variable.
export(int, LAYERS_3D_RENDER) var render_layers_3D setget set_render_layers

# Should we update the polygons anytime something is updated?
export(bool) var update_on_value_change = true

# Are we in shadow only mode?
export(bool) var shadow_only_mode = false setget set_shadow_only_mode

# We always want the wall to collide with stuff, but how exactly we want it to
# collide may change. The (Terrain, Nonpathable) layer was meant/designed for
# walls and unpassable obstacles. However, sometimes the wall is used similar to
# a roof or an overhang. This was the purpose of the (Terrain, Path Ignored)
# collision layer. So, we need option to quickly and easily switch between the
# two - ergo, this enum and configurable.
enum CollisionMode {NONPATHABLE, PATH_IGNORED}
export(CollisionMode) var collide_mode = CollisionMode.NONPATHABLE setget set_collide_mode

# The wall has two "caps" - one on the top and one on the bottom. Normally, we
# don't bother rendering the bottom because the angle of the camera means it
# won't ever be seen. However, sometimes the wall is used for overhangs - in
# that case, we need to render the bottom so it can effectively block light (as
# we would expect something to).
export(bool) var render_bottom_cap = false setget set_render_bottom_cap

# Load the PolyGen script
const PolyGen = preload("res://util/scripts/PolyGen.gd")

# What's the minimum length for the wall?
const MIN_LEN = 0.01
# At a minimum, how thick must the wall be?
const MIN_THICKNESS = .01
# What's the minimum height for the wall?
const MIN_HEIGHT = 0.01

func _ready():
    # When we enter the scene for the first time, we have to build out the
    # walls
    self.build_all()
    # Asset our render layers - since we already do this in the setter method,
    # let's just pass the current value into the setter
    set_render_layers(self.render_layers_3D)

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_cutaway_sides(new_mat):
    cutaway_sides_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_cutaway_caps(new_mat):
    cutaway_caps_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_interior(new_mat):
    interior_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_exterior(new_mat):
    exterior_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_uv_shift(new_shift):
    uv_shift = new_shift
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_length(new_length):
    # Length MUST at LEAST be MIN_LEN
    length = max(new_length, MIN_LEN)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_thickness(new_thickness):
    # Thickness MUST at LEAST be MIN_THICKNESS
    thickness = max(new_thickness, MIN_THICKNESS)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_height(new_height):
    # Height MUST at LEAST be MIN_HEIGHT
    height = max(new_height, MIN_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_shadow_only_mode(new_shadow_mode):
    # Accept the value
    shadow_only_mode = new_shadow_mode
    
    # The values affected by shadow only mode require some constants with really
    # long names - we're just gonna capture and hold those values.
    var shade_only = GeometryInstance.SHADOW_CASTING_SETTING_SHADOWS_ONLY
    var shade_default = GeometryInstance.SHADOW_CASTING_SETTING_ON
    
    # ASSERT!
    if shadow_only_mode:
        $Exterior.cast_shadow = shade_only
        $Interior.cast_shadow = shade_only
        $CutawaySides.cast_shadow = shade_only
        $CutawayCaps.cast_shadow = shade_only
    else:
        $Exterior.cast_shadow = shade_default
        $Interior.cast_shadow = shade_default
        $CutawaySides.cast_shadow = shade_default
        $CutawayCaps.cast_shadow = shade_default

func set_collide_mode(new_mode):
     # Accept the value
    collide_mode = new_mode
    
    # Assert neutral status
    self.set_collision_layer_bit(1, false)
    self.set_collision_layer_bit(2, false)
    self.set_collision_mask_bit(1, false)
    self.set_collision_mask_bit(2, false)
    
    match collide_mode:
        CollisionMode.NONPATHABLE:
            self.set_collision_layer_bit(1, true)
            self.set_collision_mask_bit(1, true)
        CollisionMode.PATH_IGNORED:
            self.set_collision_layer_bit(2, true)
            self.set_collision_mask_bit(2, true)

func set_render_bottom_cap(new_bool):
    render_bottom_cap = new_bool
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_render_layers(new_layers):
    render_layers_3D = new_layers
    # Because this a tool script, and Godot is a bit wacky about exactly how 
    # things load in, we'll check each node before setting the layers.
    if has_node("Exterior"):
        $Exterior.layers = render_layers_3D
    if has_node("Interior"):
        $Interior.layers = render_layers_3D
    if has_node("CutawaySides"):
        $CutawaySides.layers = render_layers_3D
    if has_node("CutawayCaps"):
        $CutawayCaps.layers = render_layers_3D

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_interior()
    build_exterior()
    build_cutaway_sides()
    build_cutaway_caps()
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
    var pointA = Vector2(-length / 2.0, 0)
    var pointB = Vector2( length / 2.0, height)
    
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
    var pd = PolyGen.create_xlock_face_shifted(pointA, pointB, length / 2.0, uv_shift)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # Recreate our points for the negative X-face
    pointA = Vector2( thickness / 2.0, 0)
    pointB = Vector2(-thickness / 2.0, height)
    # Create the negative X-face
    pd = PolyGen.create_xlock_face_shifted(pointA, pointB, -length / 2.0, uv_shift)
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

func build_cutaway_caps():
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()

    # Calculate the depth (z-lock)
    var z_lock = -thickness / 2.0
    
    # Create our points
    var pointA = Vector2(-length / 2.0, -thickness / 2.0)
    var pointB = Vector2(length / 2.0, thickness / 2.0)
    
    # Make the positive Y-face
    var pd = PolyGen.create_ylock_face_shifted(pointA, pointB, height, uv_shift)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    # If we need to make a bottom face...
    if render_bottom_cap:
        pointA = Vector2(-length / 2.0, thickness / 2.0)
        pointB = Vector2( length / 2.0, -thickness / 2.0)
        # Then make the negative Y-face
        pd = PolyGen.create_ylock_face_shifted(pointA, pointB, 0, uv_shift)
        verts.append_array( pd[PolyGen.VECTOR3_KEY] )
        UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(cutaway_caps_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    $CutawayCaps.mesh = new_mesh

func adjust_base_collision():
    # Calculate the new size for the collision box
    var new_size = Vector3(length / 2.0, height / 2.0, thickness / 2.0)
    
    # Reset the foundation back to zero so we know what we're doing
    $Collision.transform.origin = Vector3.ZERO
    $Collision.shape = BoxShape.new()
    $Collision.shape.extents = new_size
    $Collision.translate(Vector3(0, height / 2.0, 0))
