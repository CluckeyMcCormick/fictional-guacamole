extends Camera

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const MOVE_RATE = 5

# To move forward, backward, left and right, we need to translate the camera -
# which we can do with these vectors. Neat!
var move_vector_FB = Vector3(-MOVE_RATE, 0, -MOVE_RATE)
var move_vector_LR = Vector3(MOVE_RATE, 0, MOVE_RATE).rotated( Vector3(0, 1, 0), PI / 2)

# When we recenter the camera, where does the camera move to? We'll have it
# reset to it's starting position, so we'll grab that
var recenter_point = self.translation

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var translator = Vector3.ZERO
    
    # Handle our camera movement
    if Input.is_action_pressed("camera_move_forward"):
        translator += delta * move_vector_FB
    if Input.is_action_pressed("camera_move_backward"):
        translator -= delta * move_vector_FB
    if Input.is_action_pressed("camera_move_right"):
        translator += delta * move_vector_LR
    if Input.is_action_pressed("camera_move_left"):
        translator -= delta * move_vector_LR
    
    self.global_translate( translator )

# Process an input event. Intended for single-press input events, like the
# camera
func _input(event):
    if event.is_action_pressed("camera_recenter"):
        self.translation = recenter_point
    if event.is_action_pressed("debug_print"):
        print(self.translation)