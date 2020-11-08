tool
extends Spatial

# Wall Materials
export(Material) var wall_cutaway_sides_mat setget set_cutaway_sides
export(Material) var wall_cutaway_top_mat setget set_cutaway_top
export(Material) var wall_interior_mat setget set_interior
export(Material) var wall_exterior_mat setget set_exterior
# Column Materials
export(Material) var col_top_mat setget set_top
export(Material) var col_sides_mat setget set_sides

# The wall set has four walls - our "Fourth" wall is the Z positive one. We
# could have no wall there, an open gap wall, or a closed gap wall - it's all up
# to the user!
enum WallStyles {NO_WALL, OPEN_GAP, CLOSED_GAP}
export(WallStyles) var fourth_wall_style = WallStyles.NO_WALL setget set_fourth_wall
# We're gonna store the fourth wall node because we can't easily change the name
# on the fly - and having it stored will be good!
var fourth_wall_node = null

# How long is this wall set, on x?
export(float) var x_size = 10 setget set_x_size
# How long is this wall set, on z?
export(float) var z_size = 5 setget set_z_size
# How thick are the walls and columns of this set?
export(float) var thickness = 1 setget set_thickness
# How tall are the wall?
export(float) var height = 2 setget set_wall_height
# How long is the gap?
export(float) var gap_length = 2 setget set_gap_length
# How tall is the gap?
export(float) var gap_height = 1 setget set_gap_height

# Should we update the polygons anytime something is updated?
export(bool) var update_on_value_change = true

# Are we in shadow only mode?
enum ShadowModes {
    FULL_VIS, # Every single mesh is visible. Yipee!
    # Sometimes we only want specific walls to disappear. Each one of these
    # disappears two walls and a column.
    SHADOW_NE, SHADOW_NW, SHADOW_SW, SHADOW_SE,
    # Every wall disappears. Neat!
    SHADOW_ONLY
}
export(ShadowModes) var shadow_only_mode = ShadowModes.FULL_VIS setget set_shadow_only_mode

# What's the minimum length for the wall?
const MIN_SIZE = 1
# At a minimum, how thick must the wall be?
const MIN_THICKNESS = .01
# What's the minimum height for the wall?
const MIN_HEIGHT = .01
# What's the minimum size of the gap?
const MIN_GAP_LEN = .01
# What's the minimum height of the gap?
const MIN_GAP_HEIGHT = .01

# Preload the two varieties of fourth wall
const GAP_WALL = preload("res://buildings/components/WallGap.tscn")
#res://buildings/components/WallGap.tscn
# Called when the node enters the scene tree for the first time.
func _ready():
    build_all()

# --------------------------------------------------------
#
# Material Setters
#
# --------------------------------------------------------
func set_cutaway_sides(new_mat):
    wall_cutaway_sides_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_cutaway_top(new_mat):
    wall_cutaway_top_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_interior(new_mat):
    wall_interior_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_exterior(new_mat):
    wall_exterior_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_top(new_mat):
    col_top_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_sides(new_mat):
    col_sides_mat = new_mat
    if Engine.editor_hint and update_on_value_change:
        build_all()

# --------------------------------------------------------
#
# Constraint Setters
#
# --------------------------------------------------------
func set_fourth_wall(new_wall_type):
    fourth_wall_style = new_wall_type
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_x_size(new_size):
    x_size = max(new_size, MIN_SIZE)
    if Engine.editor_hint and update_on_value_change:
        build_all()
        
func set_z_size(new_size):
    z_size = max(new_size, MIN_SIZE)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_thickness(new_thickness):
    thickness = max(new_thickness, MIN_THICKNESS)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_wall_height(new_height):
    height = max(new_height, MIN_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_gap_length(new_length):
    gap_length = max(new_length, MIN_GAP_LEN)
    if Engine.editor_hint and update_on_value_change:
        build_all()

func set_gap_height(new_height):
    gap_height = max(new_height, MIN_GAP_HEIGHT)
    if Engine.editor_hint and update_on_value_change:
        build_all()

# --------------------------------------------------------
#
# Status Setters
#
# --------------------------------------------------------

func set_shadow_only_mode(new_shadow_mode):
    # Accept the value
    shadow_only_mode = new_shadow_mode
    
    # Update as appropriate
    match shadow_only_mode:
        ShadowModes.FULL_VIS:
            $FirstWall.shadow_only_mode = false
            $FirstColumn.shadow_only_mode = false
            $SecondWall.shadow_only_mode = false
            $SecondColumn.shadow_only_mode = false
            $ThirdWall.shadow_only_mode = false
            $ThirdColumn.shadow_only_mode = false
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = false
            $FourthColumn.shadow_only_mode = false
        ShadowModes.SHADOW_NE:
            $FirstWall.shadow_only_mode = true
            $FirstColumn.shadow_only_mode = true
            $SecondWall.shadow_only_mode = true
            $SecondColumn.shadow_only_mode = false
            $ThirdWall.shadow_only_mode = false
            $ThirdColumn.shadow_only_mode = false
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = false
            $FourthColumn.shadow_only_mode = false
        ShadowModes.SHADOW_NW:
            $FirstWall.shadow_only_mode = false
            $FirstColumn.shadow_only_mode = false
            $SecondWall.shadow_only_mode = true
            $SecondColumn.shadow_only_mode = true
            $ThirdWall.shadow_only_mode = true
            $ThirdColumn.shadow_only_mode = false
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = false
            $FourthColumn.shadow_only_mode = false
        ShadowModes.SHADOW_SW:
            $FirstWall.shadow_only_mode = false
            $FirstColumn.shadow_only_mode = false
            $SecondWall.shadow_only_mode = false
            $SecondColumn.shadow_only_mode = false
            $ThirdWall.shadow_only_mode = true
            $ThirdColumn.shadow_only_mode = true
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = true
            $FourthColumn.shadow_only_mode = false
        ShadowModes.SHADOW_SE:
            $FirstWall.shadow_only_mode = true
            $FirstColumn.shadow_only_mode = false
            $SecondWall.shadow_only_mode = false
            $SecondColumn.shadow_only_mode = false
            $ThirdWall.shadow_only_mode = false
            $ThirdColumn.shadow_only_mode = false
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = true
            $FourthColumn.shadow_only_mode = true
        ShadowModes.SHADOW_ONLY:
            $FirstWall.shadow_only_mode = true
            $FirstColumn.shadow_only_mode = true
            $SecondWall.shadow_only_mode = true
            $SecondColumn.shadow_only_mode = true
            $ThirdWall.shadow_only_mode = true
            $ThirdColumn.shadow_only_mode = true
            if fourth_wall_node:
                fourth_wall_node.shadow_only_mode = true
            $FourthColumn.shadow_only_mode = true
    # Aaaand we're done!

# --------------------------------------------------------
#
# Build Functions
#
# --------------------------------------------------------
func build_all():
    # Back out if we have none of the correct nodes, for some reason. Mostly we
    # do this because sometimes the script gets into a funk in the editor
    if not has_node("FirstWall") or not has_node("SecondWall") or not has_node("ThirdWall"):
        return
    if not has_node("FirstColumn") or not has_node("SecondColumn"):
        return
    if not has_node("ThirdColumn") or not has_node("FourthColumn"):
        return
    
    # Step 1: If we have a fourth wall, remove it (and recreate it if necessary) 
    if fourth_wall_node:
        self.remove_child(fourth_wall_node)
        
    match self.fourth_wall_style:
        # If there's not supposed to be a wall, just skip it
        WallStyles.NO_WALL:
            fourth_wall_node = null
        # If there's supposed to be an open wall, create the node and then set
        # the length of the gap
        WallStyles.OPEN_GAP:
            fourth_wall_node = GAP_WALL.instance()
            fourth_wall_node.update_on_value_change = false
            fourth_wall_node.generate_cap_wall = false
            self.add_child(fourth_wall_node)
            fourth_wall_node.set_owner(self)
            fourth_wall_node.gap_length = self.gap_length
        # If there's supposed to be an open wall, create the node and then set
        # the length of the gap AND the height of the gap
        WallStyles.CLOSED_GAP:
            fourth_wall_node = GAP_WALL.instance()
            fourth_wall_node.update_on_value_change = false
            fourth_wall_node.generate_cap_wall = true
            self.add_child(fourth_wall_node)
            fourth_wall_node.set_owner(self)
            fourth_wall_node.gap_length = self.gap_length
            fourth_wall_node.gap_height = self.gap_height
    
    # Step 2: Calculate where the items need to go and how big they need to be.
    # Since the wall set is symmetrical, the means the values are either -x, x,
    # -z, or z. So we only have to calculate the appropriate X value and the
    # appropriate Z value.
    var x_point = (self.x_size / 2) - (self.thickness / 2)
    var z_point = (self.z_size / 2) - (self.thickness / 2)
    var x_lock_len = self.z_size - (self.thickness * 2)
    var z_lock_len = self.x_size - (self.thickness * 2)
    
    # Step 3: Ensure the height of each item is correct
    $FirstWall.height = self.height
    $FirstColumn.height = self.height
    $SecondWall.height = self.height
    $SecondColumn.height = self.height
    $ThirdWall.height = self.height
    $ThirdColumn.height = self.height
    $FourthColumn.height = self.height
    if fourth_wall_node:
        fourth_wall_node.wall_height = self.height
    
    # Step 4: Ensure the thickness of each item is correct
    $FirstWall.thickness = self.thickness
    $SecondWall.thickness = self.thickness
    $ThirdWall.thickness = self.thickness
    if fourth_wall_node:
        fourth_wall_node.thickness = self.thickness
    
    $FirstColumn.side_length = self.thickness
    $SecondColumn.side_length = self.thickness
    $ThirdColumn.side_length = self.thickness
    $FourthColumn.side_length = self.thickness
    
    # Step 5: Ensure the length of the walls is correct
    $FirstWall.length = x_lock_len
    $SecondWall.length = z_lock_len
    $ThirdWall.length = x_lock_len
    if fourth_wall_node:
        fourth_wall_node.wall_length = z_lock_len
    
    # Step 6: Apply the materials
    $FirstWall.interior_mat = self.wall_interior_mat
    $SecondWall.interior_mat = self.wall_interior_mat
    $ThirdWall.interior_mat = self.wall_interior_mat
    
    $FirstWall.exterior_mat = self.wall_exterior_mat
    $SecondWall.exterior_mat = self.wall_exterior_mat
    $ThirdWall.exterior_mat = self.wall_exterior_mat
    
    $FirstWall.cutaway_sides_mat = self.wall_cutaway_sides_mat
    $SecondWall.cutaway_sides_mat = self.wall_cutaway_sides_mat
    $ThirdWall.cutaway_sides_mat = self.wall_cutaway_sides_mat
    
    $FirstWall.cutaway_top_mat = self.wall_cutaway_top_mat
    $SecondWall.cutaway_top_mat = self.wall_cutaway_top_mat
    $ThirdWall.cutaway_top_mat = self.wall_cutaway_top_mat
    
    if fourth_wall_node:
        fourth_wall_node.interior_mat = self.wall_interior_mat
        fourth_wall_node.exterior_mat = self.wall_exterior_mat
        fourth_wall_node.cutaway_sides_mat = self.wall_cutaway_sides_mat
        fourth_wall_node.cutaway_top_mat = self.wall_cutaway_top_mat
        
    $FirstColumn.sides_mat = self.col_sides_mat
    $SecondColumn.sides_mat = self.col_sides_mat
    $ThirdColumn.sides_mat = self.col_sides_mat
    $FourthColumn.sides_mat = self.col_sides_mat
    
    $FirstColumn.top_mat = self.col_top_mat
    $SecondColumn.top_mat = self.col_top_mat
    $ThirdColumn.top_mat = self.col_top_mat
    $FourthColumn.top_mat = self.col_top_mat
    
    # Step 7: Make sure the walls are rotated appropriately
    $FirstWall.rotation_degrees.y = -90
    $SecondWall.rotation_degrees.y = 0
    $ThirdWall.rotation_degrees.y = 90
    if fourth_wall_node:
        fourth_wall_node.rotation_degrees.y = 180
    
    # Step 8: Move the walls using the base vectors
    $FirstWall.transform.origin = Vector3(x_point, 0, 0)
    $SecondWall.transform.origin = Vector3(0, 0, -z_point)
    $ThirdWall.transform.origin = Vector3(-x_point, 0, 0)
    if fourth_wall_node:
        fourth_wall_node.transform.origin = Vector3(0, 0, z_point)
    
    $FirstColumn.transform.origin = Vector3(x_point, 0, -z_point)
    $SecondColumn.transform.origin = Vector3(-x_point, 0, -z_point)
    $ThirdColumn.transform.origin = Vector3(-x_point, 0, z_point)
    $FourthColumn.transform.origin = Vector3(x_point, 0, z_point)
    
    # Step 9: Rebuild those items!
    $FirstColumn.build_all()
    $SecondColumn.build_all()
    $ThirdColumn.build_all()
    $FourthColumn.build_all()
    
    $FirstWall.build_all()
    $SecondWall.build_all()
    $ThirdWall.build_all()
    if fourth_wall_node:
        fourth_wall_node.build_all()
