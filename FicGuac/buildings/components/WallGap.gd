tool
extends Spatial

export(Material) var cutaway_sides_mat setget set_cutaway_sides
export(Material) var cutaway_caps_mat setget set_cutaway_caps
export(Material) var interior_mat setget set_interior
export(Material) var exterior_mat setget set_exterior

# While both walls have their own individual uv shifts, we provide the user with
# this option to provide additional shift
export(Vector3) var uv_shift setget set_uv_shift
# How long is the wall? Note that this include the gap!
export(float) var wall_length = 6 setget set_wall_length
# How thick is the wall?
export(float) var thickness = 1 setget set_thickness
# How high is the wall?
export(float) var wall_height = 2 setget set_wall_height
# How long is the gap?
export(float) var gap_length = 2 setget set_gap_length
# Is there a cap wall for the gap?
export(bool) var generate_cap_wall = false setget set_generate_cap_wall
# How tall is the gap?
export(float) var gap_height = 1 setget set_gap_height

# We may want this construct to appear on a different layer for whatever reason
# (most likely for some shader nonsense). Since that is normally set at the mesh
# level, we'll provide this convenience variable.
export(int, LAYERS_3D_RENDER) var render_layers_3D setget set_render_layers

# Should we update the polygons anytime something is updated?
export(bool) var update_on_value_change = true

# Are we in shadow only mode?
export(bool) var shadow_only_mode = false setget set_shadow_only_mode

# What's the minimum length for the wall?
const MIN_LEN = .04
# At a minimum, how thick must the wall be?
const MIN_THICKNESS = .01
# What's the minimum height for the wall?
const MIN_HEIGHT = .01
# What's the minimum size of the gap?
const MIN_GAP_LEN = .01
# What's the minimum height of the gap?
const MIN_GAP_HEIGHT = .01

# Load the RothWall scene so we can spawn the gap in on the fly
const WALL_SCENE = preload("res://buildings/components/WallBasic.tscn")

# We're gonna store the fourth wall node because we can't easily change the name
# on the fly - and having it stored will be good!
var cap_wall_node = null

func _ready():
    # When we enter the scene for the first time, we have to build out both of
    # our walls
    build_all()
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

func set_wall_length(new_length):
    wall_length = max(new_length, MIN_LEN)
    # Now that we've set the length, we need to adjust the gap length, since
    # this is determined by the length
    var max_gap_length = wall_length - MIN_LEN
    # Clamp it!
    gap_length = clamp(gap_length, MIN_GAP_LEN, max_gap_length)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_thickness(new_thickness):
    thickness = max(new_thickness, MIN_THICKNESS)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_wall_height(new_height):
    wall_height = max(new_height, MIN_HEIGHT)
    # Calculate the maximum gap length, which is derived from the current length
    var max_gap_height = wall_height - MIN_GAP_HEIGHT
    # Clamp it!
    gap_height = clamp(gap_height, MIN_GAP_HEIGHT, max_gap_height)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_gap_length(new_length):
    # Calculate the maximum gap length, which is derived from the current length
    var max_gap_length = wall_length - MIN_LEN
    # Clamp it!
    gap_length = clamp(new_length, MIN_GAP_LEN, max_gap_length)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_generate_cap_wall(new_option):
    generate_cap_wall = new_option
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_gap_height(new_height):
    # Calculate the maximum gap length, which is derived from the current length
    var max_gap_height = wall_height - MIN_GAP_HEIGHT
    # Clamp it!
    gap_height = clamp(new_height, MIN_GAP_HEIGHT, max_gap_height)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_shadow_only_mode(new_shadow_mode):
    # Accept the value
    shadow_only_mode = new_shadow_mode
    
    # ASSERT!
    if shadow_only_mode:
        $WallA.shadow_only_mode = true
        $WallB.shadow_only_mode = true
        if cap_wall_node:
            cap_wall_node.shadow_only_mode = true
    else:
        $WallA.shadow_only_mode = false
        $WallB.shadow_only_mode = false
        if cap_wall_node:
            cap_wall_node.shadow_only_mode = false
  
func set_render_layers(new_layers):
    render_layers_3D = new_layers
    # Because this a tool script, and Godot is a bit wacky about exactly how 
    # things load in, we'll check each node before setting the layers.
    if has_node("WallA"):
        $WallA.render_layers_3D = render_layers_3D
    if has_node("WallB"):
        $WallB.render_layers_3D = render_layers_3D
    if cap_wall_node:
        cap_wall_node.render_layers_3D = render_layers_3D

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    # Back out if we have no walls, for some reason
    if not has_node("WallA") or not has_node("WallB"):
        return

    # Step 1: If we have a fourth wall, remove it (and recreate it if necessary) 
    if cap_wall_node:
        self.remove_child(cap_wall_node)
        
    if generate_cap_wall:
        cap_wall_node = WALL_SCENE.instance()
        cap_wall_node.update_on_value_change = false
        cap_wall_node.render_bottom_cap = true
        self.add_child(cap_wall_node)
        cap_wall_node.set_owner(self)

    # Step 2: Calculate the length of each component wall and set it
    var subwall_length = (self.wall_length - self.gap_length) / 2.0
    $WallA.length = subwall_length
    $WallB.length = subwall_length
    if cap_wall_node:
        cap_wall_node.length = self.gap_length
    
    # Step 3: Ensure the height of each wall is correct
    var subwall_height = (self.wall_height - self.gap_height)
    $WallA.height = self.wall_height
    $WallB.height = self.wall_height
    if cap_wall_node:
        cap_wall_node.height = subwall_height
    
    # Step 4: Ensure the thickness of each wall is correct
    $WallA.thickness = self.thickness
    $WallB.thickness = self.thickness
    if cap_wall_node:
        cap_wall_node.thickness = self.thickness
    
    # Step 5: Calculate the vector shift of each wall and set it on the walls
    # combined with the current shift.
    var shiftA = Vector3.ZERO
    shiftA.x = -(subwall_length + self.gap_length) / 2.0
    var shiftB = Vector3.ZERO
    shiftB.x =  (subwall_length + self.gap_length) / 2.0  
    var shiftC = Vector3.ZERO
    shiftC.y = self.gap_height
    
    $WallA.uv_shift = shiftA + self.uv_shift
    $WallB.uv_shift = shiftB + self.uv_shift
    if cap_wall_node:
        cap_wall_node.uv_shift = shiftC + self.uv_shift
    
    # Step 6: Move the walls using the base vectors
    $WallA.transform.origin = shiftA
    $WallB.transform.origin = shiftB
    if cap_wall_node:
        cap_wall_node.transform.origin = shiftC
    
    # Step 7: Ensure the materials are correct
    $WallA.cutaway_sides_mat = self.cutaway_sides_mat
    $WallB.cutaway_sides_mat = self.cutaway_sides_mat
    $WallA.cutaway_caps_mat = self.cutaway_caps_mat
    $WallB.cutaway_caps_mat = self.cutaway_caps_mat
    $WallA.interior_mat = self.interior_mat
    $WallB.interior_mat = self.interior_mat
    $WallA.exterior_mat = self.exterior_mat
    $WallB.exterior_mat = self.exterior_mat
    if cap_wall_node:
        cap_wall_node.cutaway_sides_mat = self.cutaway_sides_mat
        cap_wall_node.cutaway_caps_mat = self.cutaway_caps_mat
        cap_wall_node.interior_mat = self.interior_mat
        cap_wall_node.exterior_mat = self.exterior_mat
    
    # Step 8: Rebuild those walls!
    $WallA.build_all()
    $WallB.build_all()
    if cap_wall_node:
        cap_wall_node.build_all()
