tool
extends Spatial

# Fundamental size controls - wall thickness and house sizes
export(int, 5, 20) var x_size = 10 setget set_x_size
export(int, 5, 20) var z_size = 5 setget set_z_size
export(float, .05, 1, .05) var wall_thickness = .5 setget set_wall_thickness

# Door controls - how big a space should we leave for the door?
export(int, 2, 5) var door_width = 2 setget set_door_width
export(float, 2, 3, .25) var door_height = 2

# Stair controls - how big a space should the stairs be? Should we have stairs?
export(bool) var generate_stairs = true setget set_generate_stairs
export(float, 1, 5, .25) var stair_x_length = 2 setget set_stair_x_length
export(float, 1, 5, .25) var stair_z_length = 2 setget set_stair_z_length
export(int, 1, 4) var stair_steps = 4 setget set_stair_steps 

# Heights for our various components - very important!
export(float,.05,1,.05) var foundation_height = .5 setget set_foundation_height
export(float, .25, 1, .25) var lower_wall_height =  .5
export(float,   2, 5, .25) var upper_wall_height = 2.5
export(float,   1, 8, .25) var roof_peak_height = 4 

# Called when the node enters the scene tree for the first time.
func _ready():
    # Rebuild on entering the scene. If we don't do this, the building defaults
    # to the default template (which is fine but might not be what we want)
    rebuild()

# Rebuild function - orders all of the individual components to rebuild
# themselves. Only meant to be called once to initially build the house.
func rebuild():
    if $RothFoundation:
        $RothFoundation.build_all(self)
    if $RothStairs:
        $RothStairs.build_all(self)

func set_x_size(new_x):
    x_size = new_x
    if Engine.editor_hint:
        rebuild()

func set_z_size(new_z):
    z_size = new_z
    if Engine.editor_hint:
        rebuild()

func set_wall_thickness(new_thickness):
    wall_thickness = new_thickness
    if Engine.editor_hint:
        rebuild()

func set_door_width(new_width):
    if self.x_size - new_width >= 2:
        door_width = new_width
        if Engine.editor_hint:
            rebuild()

func set_generate_stairs(new_generate_bool):
    generate_stairs = new_generate_bool
    if Engine.editor_hint:
        rebuild()
        
func set_stair_x_length(new_stair_length):
    stair_x_length = new_stair_length
    if Engine.editor_hint:
        rebuild()
    
func set_stair_z_length(new_stair_length):
    stair_z_length = new_stair_length
    if Engine.editor_hint:
        rebuild()
    
func set_stair_steps(new_step_count):
    stair_steps = new_step_count
    if Engine.editor_hint:
        rebuild()

func set_foundation_height(new_height):
    foundation_height = new_height
    if Engine.editor_hint:
        rebuild()
