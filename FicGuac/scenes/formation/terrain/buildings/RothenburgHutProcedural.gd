tool
extends Spatial

# Fundamental size controls - wall thickness and house sizes
export(int, 5, 20) var x_size = 10 setget set_x_size
export(int, 5, 20) var z_size = 5 setget set_z_size
export(float, .05, 1, .05) var wall_thickness = .5 setget set_wall_thickness

# Door controls - how big a space should we leave for the door?
export(int, 2, 3) var door_width = 2 setget set_door_width
export(float, 2, 3, .25) var door_height = 2

# Heights for our various components - very important!
export(float,.05,1,.05) var foundation_height = .5 setget set_foundation_height
export(float, .25, 1, .25) var lower_wall_height =  .5
export(float,   2, 5, .25) var upper_wall_height = 2.5
export(float,   1, 8, .25) var roof_peak_height = 4 

# Called when the node enters the scene tree for the first time.
func _ready():
    if $RothFoundation:
        $RothFoundation.build_all(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func set_x_size(new_x):
    x_size = new_x
    if Engine.editor_hint:
        $RothFoundation.build_all(self)

func set_z_size(new_z):
    z_size = new_z
    if Engine.editor_hint:
        $RothFoundation.build_all(self)

func set_wall_thickness(new_thickness):
    wall_thickness = new_thickness
    if Engine.editor_hint:
        $RothFoundation.build_all(self)

func set_door_width(new_width):
    door_width = new_width
    if Engine.editor_hint:
        $RothFoundation.build_all(self)

func set_foundation_height(new_height):
    foundation_height = new_height
    if Engine.editor_hint:
        $RothFoundation.build_all(self)
