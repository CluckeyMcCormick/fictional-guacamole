extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# The team name that we'll pass down to the BoidFaction
export(String) var faction_name = "TEAM NAME HERE!"

# Our boid scene; we need to load this so we can instance it
var MICRO_BOID_SCENE = load("res://scenes/proto/boid/BoidMicro.tscn")
# The bouncy ball scene
var BOUNCY_BALL_SCENE = load("res://scenes/proto/BounceBall.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _input(event):
    if event.is_action_pressed("spawn_boid"):
         # Create a new boid
        var boid_node = MICRO_BOID_SCENE.instance()
        # Set the position
        boid_node.position = event.position
        # Set the faction
        boid_node.set_faction($BoidFaction)
        # Set it lose!
        add_child(boid_node) # Add it as a child of this node.
    if event.is_action_pressed("spawn_death_ball"):
         # Create a new boid
        var ball_node = BOUNCY_BALL_SCENE.instance()
        # Set the position
        ball_node.position = event.position
        # Set it lose!
        add_child(ball_node) # Add it as a child of this node.
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
