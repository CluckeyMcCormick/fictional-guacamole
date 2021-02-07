tool
extends StaticBody

export(Material) var top_mat setget set_top
export(Material) var primary_mat setget set_primary
export(Material) var alternate_mat setget set_alternate

# Flags for setting whether a particular face uses the primary or alternate
# material - see below for more.
const PRI_MAT_MASK_Z_POS = 1
const PRI_MAT_MASK_Z_NEG = 2
const PRI_MAT_MASK_X_POS = 4
const PRI_MAT_MASK_X_NEG = 8
const PRI_MAT_MASK_ALL = 15

# Each face of the column can use one of two materials - the primary, or the
# alternate. This can be used for a variety of effects, but the driving use case
# was so that we could "shadow" columns that faced into walls appropriately.
export( int, FLAGS,
    "Z Positive", "Z Negative",
    "X Positive", "X Negative"
) var use_primary_material = PRI_MAT_MASK_ALL setget set_use_primary_material

# How long are the sides of the column?
export(float) var side_length = 1 setget set_length
# How tall is this column?
export(float) var height = 2 setget set_height

# We may want this construct to appear on a different layer for whatever reason
# (most likely for some shader nonsense). Since that is normally set at the mesh
# level, we'll provide this convenience variable.
export(int, LAYERS_3D_RENDER) var render_layers_3D setget set_render_layers

# Should we update the polygons anytime something is updated?
export(bool) var update_on_value_change = true

# Are we in shadow only mode?
export(bool) var shadow_only_mode = false setget set_shadow_only_mode

# Load the PolyGen script
const PolyGen = preload("res://util/scripts/PolyGen.gd")

# What's the minimum length for a column?
const MIN_LEN = 0.01

# What's the minimum height for a column?
const MIN_HEIGHT = 0.01

func _ready():
    # When we enter the scene for the first time, we have to build out the
    # stairs
    self.build_all()
    # Asset our render layers - since we already do this in the setter method,
    # let's just pass the current value into the setter
    set_render_layers(self.render_layers_3D)

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_top(new_mat):
    top_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_primary(new_mat):
    primary_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_alternate(new_mat):
    alternate_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_length(new_length):
    # Side length MUST at LEAST be MIN_LEN
    side_length = max(new_length, MIN_LEN)
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_height(new_height):
    # Height MUST BE AN ACTUAL POSITIVE value!
    height = max(new_height, MIN_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_use_primary_material(new_flags):
    use_primary_material = new_flags
    if Engine.editor_hint and update_on_value_change:
        build_all()

# Utility function for controlling the Z Positive primary material bit
func set_primary_mat_z_positive(bool_val):
    if bool_val:
        self.use_primary_material |= PRI_MAT_MASK_Z_POS
    else:
        self.use_primary_material &= (PRI_MAT_MASK_ALL ^ PRI_MAT_MASK_Z_POS)

# Utility function for controlling the Z Negative primary material bit
func set_primary_mat_z_negative(bool_val):
    if bool_val:
        self.use_primary_material |= PRI_MAT_MASK_Z_NEG
    else:
        self.use_primary_material &= (PRI_MAT_MASK_ALL ^ PRI_MAT_MASK_Z_NEG)

# Utility function for controlling the X Positive primary material bit
func set_primary_mat_x_positive(bool_val):
    if bool_val:
        self.use_primary_material |= PRI_MAT_MASK_X_POS
    else:
        self.use_primary_material &= (PRI_MAT_MASK_ALL ^ PRI_MAT_MASK_X_POS)

# Utility function for controlling the X Negative primary material bit
func set_primary_mat_x_negative(bool_val):
    if bool_val:
        self.use_primary_material |= PRI_MAT_MASK_X_NEG
    else:
        self.use_primary_material &= (PRI_MAT_MASK_ALL ^ PRI_MAT_MASK_X_NEG)
        
func set_shadow_only_mode(new_shadow_mode):
    # Accept the value
    shadow_only_mode = new_shadow_mode
    
    # The values affected by shadow only mode require some constants with really
    # long names - we're just gonna capture and hold those values.
    var shade_only = GeometryInstance.SHADOW_CASTING_SETTING_SHADOWS_ONLY
    var shade_default = GeometryInstance.SHADOW_CASTING_SETTING_ON
    
    # ASSERT!
    if shadow_only_mode:
        $Top.cast_shadow = shade_only
        $XPosFace.cast_shadow = shade_only
        $XNegFace.cast_shadow = shade_only
        $ZPosFace.cast_shadow = shade_only
        $ZNegFace.cast_shadow = shade_only
        # If set to shade only mode, then we're no longer blocking visibility.
        # Turn off the "Camera Obstruction" collision layer.
        self.set_collision_layer_bit(2, false)
        self.set_collision_mask_bit(2, false)
    else:
        $Top.cast_shadow = shade_default
        $XPosFace.cast_shadow = shade_default
        $XNegFace.cast_shadow = shade_default
        $ZPosFace.cast_shadow = shade_default
        $ZNegFace.cast_shadow = shade_default
        # If set to shade only mode is off, then we're blocking visibility.
        # Turn on the "Camera Obstruction" collision layer.
        self.set_collision_layer_bit(2, true)
        self.set_collision_mask_bit(2, true)
        

func set_render_layers(new_layers):
    render_layers_3D = new_layers
    # Because this a tool script, and Godot is a bit wacky about exactly how 
    # things load in, we'll check each node before setting the layers.
    if has_node("Top"):
        $Top.layers = render_layers_3D
    if has_node("XPosFace"):
        $XPosFace.layers = render_layers_3D
    if has_node("ZNegFace"):
        $ZNegFace.layers = render_layers_3D
    if has_node("XNegFace"):
        $XNegFace.layers = render_layers_3D
    if has_node("ZPosFace"):
        $ZPosFace.layers = render_layers_3D

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    build_top()
    build_sides()
    adjust_base_collision()

func ready_mesh(pointA, pointB, axis_point, is_x, use_primary):    
    var new_mesh = Mesh.new()
    var verts = PoolVector3Array()
    var UVs = PoolVector2Array()
    
    # Since the column is a square (top-down, at least), all the points are the
    # same absolute value. We can just precalculate and vary the sign!
    var abs_point = side_length / 2.0
    
    # Points and such
    var pd
    
    # Face 1: X-Positive
    if is_x:
        pd = PolyGen.create_xlock_face_simple(pointA, pointB, axis_point)
    else:
        pd = PolyGen.create_zlock_face_simple(pointA, pointB, axis_point)
    verts.append_array( pd[PolyGen.VECTOR3_KEY] )
    UVs.append_array( pd[PolyGen.VECTOR2_KEY] )
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Set the material depending on whether this face is configured to use the
    # primary or alternate material
    if use_primary:
        st.set_material(primary_mat)
    else:
        st.set_material(alternate_mat)

    for v in verts.size():
        st.add_uv(UVs[v])
        st.add_vertex(verts[v])

    st.generate_normals()
    st.generate_tangents()

    st.commit(new_mesh)
    return new_mesh

func build_sides():    
    # Since the column is a square (top-down, at least), all the points are the
    # same absolute value. We can just precalculate and vary the sign!
    var abs_point = side_length / 2.0
    
    # Points!
    var pointA
    var pointB
    # Do we use the primary material? This info is bitpacked so we need to pull
    # it out.
    var use_primary
    
    # Face 1: X-Positive
    pointA = Vector2(-abs_point, 0)
    pointB = Vector2( abs_point, height)
    use_primary = (self.use_primary_material & self.PRI_MAT_MASK_X_POS) != 0
    $XPosFace.mesh = ready_mesh(pointA, pointB, abs_point, true, use_primary)

    # Face 2: Z-Negative
    pointA = Vector2(-abs_point, 0)
    pointB = Vector2( abs_point, height)
    use_primary = (self.use_primary_material & self.PRI_MAT_MASK_Z_NEG) != 0
    $ZNegFace.mesh = ready_mesh(pointA, pointB, -abs_point, false, use_primary)

    # Face 3: X-Negative
    pointA = Vector2( abs_point, 0)
    pointB = Vector2(-abs_point,  height)
    use_primary = (self.use_primary_material & self.PRI_MAT_MASK_X_NEG) != 0
    $XNegFace.mesh = ready_mesh(pointA, pointB, -abs_point, true, use_primary)
    
    # Face 4: Z-Positive
    pointA = Vector2( abs_point, 0)
    pointB = Vector2(-abs_point, height)
    use_primary = (self.use_primary_material & self.PRI_MAT_MASK_Z_POS) != 0
    $ZPosFace.mesh = ready_mesh(pointA, pointB, abs_point, false, use_primary)

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
