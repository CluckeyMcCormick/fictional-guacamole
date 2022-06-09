extends Spatial

# Preload the kinematic pawn so we can instance it on demand
const KPAWN_PRELOAD = preload("res://tests/test_assets/KinematicPawn.tscn")
# Preload the kinematic pawn so we can instance it on demand
const TCPAWN_PRELOAD = preload("res://tests/test_assets/TaskingCowardPawn.tscn")

# When the user clicks on the screen, we need to project a ray into the world
# to determine what exactly got clicked - how long is that ray?
const MOUSE_RAY_LENGTH = 1000

# The circling pawn moves in a circle - what's the radius of this circle, in
# world units?
const CIRCLING_RADIUS = 15

# To make the circling pawn go around in a circle, we calculate each target
# position using angles - it's the unit circle. But we need to sample by only a
# certain amount of degrees, which is this. To put it another way: if this was
# set to 15, then the angles we use to produce points would be 15, 30, 45, 60,
# 75, 90, and so on.
const CIRCLING_ANGLE_STEP = 10

# Our global manifest node that holds all of the tests paths in a dictionary.
onready var MANIFEST = get_node("/root/Manifest")

# What's the angle for the pawn that's walking in a circle?
var current_angle = 0

# Since our different pawns can and will die in this test, we need variables to
# refer to the pawn node - using the NodePath operator would be too unreliable.
var circling_pawn
var wandering_pawn

# Since we need to load the conditions manually, we'll cache them in this
# dictionary for easy instancing.
var condition_cache = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    
    # We need to update the Item List using our Status Condition List
    for status_condition in MANIFEST.STATUS_CONDITIONS.keys():
        $ControlGUI/ItemList.add_item(status_condition)
    
    # Get our first set of pawns.
    circling_pawn = $CirclingPawn
    wandering_pawn = $WanderingPawn
    
    # Make the Pawn path to itself. This should trigger the path_complete
    # signal, kicking off our processing loop.
    circling_pawn.move_to_point(circling_pawn.global_transform.origin)

func _on_CirclingPawn_path_complete(pawn, position):
    # Increment the angle
    current_angle += CIRCLING_ANGLE_STEP
    # Make sure the angle is greater-than-or-equal-to 0 and less-than 360
    current_angle = fmod(current_angle, 360.0)
    
    # Calculate the new target position using MATH
    var new_target = Vector3(
        cos( deg2rad(current_angle) ) * CIRCLING_RADIUS,
        0,
        sin( deg2rad(current_angle) ) * CIRCLING_RADIUS   
    )
    
    # Pass it to the target pawn
    circling_pawn.move_to_point( new_target )

func _on_CirclingPawn_pawn_died():
    # Spawn in a new target pawn
    circling_pawn = KPAWN_PRELOAD.instance()
    
    # Connect ourselves to it's inner workings
    circling_pawn.connect("path_complete", self, "_on_CirclingPawn_path_complete")
    circling_pawn.connect("pawn_died", self, "_on_CirclingPawn_pawn_died")
    # Pass it the navigation node-path
    circling_pawn.navigation = $Floor.get_path_to($Navigation)
    # Add it to the scene. This will call all the _ready functions and stuff
    self.add_child(circling_pawn)
    
    # Make the Pawn path to itself. This should trigger the path_complete
    # signal, kicking off our processing loop.
    circling_pawn.move_to_point(circling_pawn.global_transform.origin)

func _on_CirclingPawn_input_event(camera, event, position, normal, shape_idx):
    if !event.is_action_pressed("formation_order"):
        return
    apply_modifiers(circling_pawn)

func _on_WanderingPawn_pawn_died():
    # Spawn in a new target pawn
    circling_pawn = TCPAWN_PRELOAD.instance()
    
    # Connect ourselves to it's inner workings
    wandering_pawn.connect("pawn_died", self, "_on_WanderingPawn_pawn_died")
    # Pass it the navigation node-path
    wandering_pawn.navigation = $Floor.get_path_to($Navigation)
    # Add it to the scene. This will call all the _ready functions and stuff
    self.add_child(circling_pawn)

func _on_WanderingPawn_input_event(camera, event, position, normal, shape_idx):
    if !event.is_action_pressed("formation_order"):
        return
    apply_modifiers(wandering_pawn)

func apply_modifiers(agent : KinematicBody):
    var condition_list = []
    var selected = []
    
    var temp
    
    # If we're in clear mode...
    if $ControlGUI/ClearMode.pressed:
        # Clear the status effects
        agent.get_node("CharacterStatsCore").clear_status_effects()
        # Back out!
        return
    
    # Get the selected modifiers
    selected = $ControlGUI/ItemList.get_selected_items()
    
    # If we don't have any, tell the user and back out.
    if selected.empty():
        print("No conditions selected!")
        return
    
    # For each Status Condition, ensure that it is cached, and then instance it.
    for index in selected:
        temp = $ControlGUI/ItemList.get_item_text(index)
        if not temp in condition_cache:
            condition_cache[temp] = load(MANIFEST.STATUS_CONDITIONS[temp])
        agent.get_node("CharacterStatsCore").add_status_effect(
            condition_cache[temp].instance()
        )
