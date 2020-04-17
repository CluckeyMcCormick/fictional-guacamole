extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Our three core scalars, for the boid's three core algorithmic components
var alignment = 1
var avoidance = 1
var cohesion = 1

# How quickly do the above scalars change?
const CHANGE_RATE = 0.5

# What's the minimum and maximum value for these scalars?
const SCALAR_MIN = 0
const SCALAR_MAX = 10

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Handle alignment - decrease, increase, clamp
    if Input.is_action_pressed("scalar_algn_decrease"):
        alignment -= delta * CHANGE_RATE
    if Input.is_action_pressed("scalar_algn_increase"):
        alignment += delta * CHANGE_RATE
    alignment = clamp(alignment, SCALAR_MIN, SCALAR_MAX)
    
    # Handle avoidance - decrease, increase, clamp
    if Input.is_action_pressed("scalar_avid_decrease"):
        avoidance -= delta * CHANGE_RATE
    if Input.is_action_pressed("scalar_avid_increase"):
        avoidance += delta * CHANGE_RATE
    avoidance = clamp(avoidance, SCALAR_MIN, SCALAR_MAX)
    
    # Handle cohesion - decrease, increase, clamp
    if Input.is_action_pressed("scalar_cohe_decrease"):
        cohesion -= delta * CHANGE_RATE
    if Input.is_action_pressed("scalar_cohe_increase"):
        cohesion += delta * CHANGE_RATE
    cohesion = clamp(cohesion, SCALAR_MIN, SCALAR_MAX)
