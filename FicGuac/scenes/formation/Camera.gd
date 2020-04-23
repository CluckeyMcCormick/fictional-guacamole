extends Camera

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# The (B)asic (M)ove (R)ate for the camera - expressed in units/sec. I guess
# that's technically rate per each axis, since we technically move on two axes
# and that probably comes out to something else BUT I DON'T CARE
#
# Used to calculate our movement vector. 
const BMR = 5

# In orthographic cameras, the scope/scale of visibility is expressed as it's
# "size". By manipulating the size of the camera, we can approximate zooming in
# and zooming out. Neat-o! But - what's the minimum and maximum size we can
# scale to?
const MIN_SIZE = 1
const MAX_SIZE = 7

# To move forward, backward, left and right, we need to translate the camera -
# which we can do with these vectors. Neat!
var move_vector_FB = Vector3(-BMR, 0, -BMR)
var move_vector_LR = Vector3(BMR, 0, BMR).rotated( Vector3(0, 1, 0), PI / 2)

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
    var zoom_change = false
    
    if event.is_action_pressed("camera_recenter"):
        self.translation = recenter_point
        
    if event.is_action_pressed("camera_zoom_in"):
        self.size = clamp( self.size - 1, MIN_SIZE, MAX_SIZE)
        zoom_change = true
        
    if event.is_action_pressed("camera_zoom_out"):
        self.size = clamp( self.size + 1, MIN_SIZE, MAX_SIZE)
        zoom_change = true
        
    if event.is_action_pressed("debug_print"):
        print(self.translation)
        
    if zoom_change:
        # Calculate the (N)ew (M)ove (R)ate - the basic move rate scaled to our
        # current size/zoom level.
        var nmr = BMR * ( self.size / MAX_SIZE )
        # Now that we have a new move rate, we need to recalculate our move 
        # vectors
        move_vector_FB = Vector3(-nmr, 0, -nmr)
        move_vector_LR = Vector3(nmr, 0, nmr).rotated( Vector3(0, 1, 0), PI / 2)