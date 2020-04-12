extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(bool) var randomize_movement
export(float, 0, 1, 0.05) var engine_speed = 1

# Called when the node enters the scene tree for the first time.
func _ready():
    # If we're trying to randomize the simulation, randomize the seed
    if(randomize_movement):
        randomize()
    Engine.time_scale = engine_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
