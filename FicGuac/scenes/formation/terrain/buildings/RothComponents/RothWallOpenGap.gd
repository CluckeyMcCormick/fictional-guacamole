tool
extends Spatial

export(Material) var cutaway_sides_mat setget set_cutaway_sides
export(Material) var cutaway_top_mat setget set_cutaway_top
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
export(float) var height = 2 setget set_height
# How big is the gap?
export(float) var gap_length = 2 setget set_gap_length

# What's the minimum length for the wall?
const MIN_LEN = .04
# At a minimum, how thick must the wall be?
const MIN_THICKNESS = .01
# What's the minimum height for the wall?
const MIN_HEIGHT = .01
# What's the minimum size of the gap?
const MIN_GAP_LEN = .01

# Load the PolyGen script
const PolyGen = preload("res://scenes/formation/util/PolyGen.gd")

func _ready():
    # When we enter the scene for the first time, we have to build out both of
    # our walls
    build_all()

# --------------------------------------------------------
#
# Setters and Getters
#
# --------------------------------------------------------
func set_cutaway_sides(new_mat):
    cutaway_sides_mat = new_mat
    $WallA.cutaway_sides_mat = new_mat
    $WallB.cutaway_sides_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_cutaway_top(new_mat):
    cutaway_top_mat = new_mat
    $WallA.cutaway_top_mat = new_mat
    $WallB.cutaway_top_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_interior(new_mat):
    interior_mat = new_mat
    $WallA.interior_mat = new_mat
    $WallB.interior_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_exterior(new_mat):
    exterior_mat = new_mat
    $WallA.exterior_mat = new_mat
    $WallB.exterior_mat = new_mat
    if Engine.editor_hint:
        build_all()

func set_uv_shift(new_shift):
    uv_shift = new_shift
    if Engine.editor_hint:
        build_all()

func set_wall_length(new_length):
    wall_length = max(new_length, MIN_LEN)
    # Now that we've set the length, we need to adjust the gap length, since
    # this is determined by the length
    var max_gap_length = wall_length - MIN_LEN
    # Clamp it!
    gap_length = clamp(gap_length, MIN_GAP_LEN, max_gap_length)
    if Engine.editor_hint:
        build_all()

func set_thickness(new_thickness):
    thickness = max(new_thickness, MIN_THICKNESS)
    $WallA.thickness = new_thickness
    $WallB.thickness = new_thickness
    if Engine.editor_hint:
        build_all()

func set_height(new_height):
    height = max(new_height, MIN_HEIGHT)
    $WallA.height = new_height
    $WallB.height = new_height
    if Engine.editor_hint:
        build_all()

func set_gap_length(new_length):
    # Calculate the maximum gap length, which is derived from the current length
    var max_gap_length = wall_length - MIN_LEN
    # Clamp it!
    gap_length = clamp(new_length, MIN_GAP_LEN, max_gap_length)
    if Engine.editor_hint:
        build_all()

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    # Back out if we have no walls, for some reason
    if not has_node("WallA") or not has_node("WallB"):
        return
    
    # Step 1: Calculate the length of each component wall and set it
    var subwall_length = (self.wall_length - self.gap_length) / 2.0
    $WallA.length = subwall_length
    $WallB.length = subwall_length
    
    # Step 2: Ensure the height of each wall is correct
    $WallA.height = height
    $WallB.height = height
    
    # Step 3: Ensure the thickness of each wall is correct
    $WallA.thickness = thickness
    $WallB.thickness = thickness
    
    # Step 4: Calculate the vector shift of each wall and set it on the walls
    # combined with the current shift.
    var shiftA = Vector3.ZERO
    shiftA.x = -(subwall_length + self.gap_length) / 2.0
    var shiftB = Vector3.ZERO
    shiftB.x =  (subwall_length + self.gap_length) / 2.0  
    
    $WallA.uv_shift = shiftA + self.uv_shift
    $WallB.uv_shift = shiftB + self.uv_shift
    
    # Step 5: Move the walls using the base vectors
    $WallA.transform.origin = shiftA
    $WallB.transform.origin = shiftB
    
    # Step 6: Rebuild those walls!
    $WallA.build_all()
    $WallB.build_all()
