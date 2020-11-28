tool
extends Spatial

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# The basic, unmodified move rate for the camera - expressed in units/sec. Used
# to calculate our movement vector. 
export(int, 5, 2000, 5) var basic_move_rate = 100 setget set_move_rate

# For orthographic cameras - which all of our cameras in this rig ARE - what we
# would term the "zoom" or possibly "FOV" is controlled by the "size" variable.
# All of these variables relate to controlling the camera size. There's a whole
# lot to controlling the camera - we don't want to go in too close, nor too far.
# We also want to start at a fixed size that is consistent for all of our
# cameras, and step in-and-out at a consistent rate. These all cover that.
export(int) var max_camera_size = 150 setget set_max_camera_size
export(int) var min_camera_size = 15 setget set_min_camera_size
export(int) var camera_size = 150 setget set_camera_size
export(int) var zoom_step = 15

# Sometimes, we might want the camera to just sit there - no zooming in or out,
# no moving around. These configurables allow users to enable/disable these
# behaviors.
export(bool) var move_enabled = true
export(bool) var zoom_enabled = true

export(Vector2) var move_clamping_extents = Vector2(-1, -1)

# To move forward, backward, left and right, we need to translate the camera -
# which we can do with these vectors. Neat!
var move_vector_FB = Vector3.ZERO
var move_vector_LR = Vector3.ZERO

# When we recenter the camera, where does the camera move to? We'll have it
# reset to it's starting position, so we'll grab that
onready var recenter_point = self.translation

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func set_move_rate(new_rate):
    # Set the basic move rate.
    basic_move_rate = clamp(new_rate, 5, INF)
    # Do all the necessary move rate updates
    update_move_rate()

func set_max_camera_size(new_size):
    max_camera_size = new_size
    # If we're in the editor, update those visual values
    if Engine.editor_hint:
        update_configuration_warning()
    
func set_min_camera_size(new_size):
    min_camera_size = new_size
    # If we're in the editor, update those visual values
    if Engine.editor_hint:
        update_configuration_warning()

func set_camera_size(new_size):
    # Set the camera size appropriately
    camera_size = clamp(new_size, min_camera_size, max_camera_size)
    # Update the camera to match these new constraints
    update_cameras()

    # If we're in the editor, update those visual values
    if Engine.editor_hint:
        update_configuration_warning()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signals
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# When the root viewport changes, our viewports on the camera rig don't change
# with it! We need to size up those viewports appropriately! We'll connect this
# function with the root viewport's resize event, and resize as appropriate.
func _on_root_viewport_size_changed():
    # First, get the root viewport
    var root_viewport = get_tree().get_root()
    # Now, trickle those sizes down to our rig's sub-viewports
    $XrayWorld.size = root_viewport.size
    $SilhouetteWorld.size = root_viewport.size

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Camera Rig specific functions and utilities
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Updates all our cameras to be the same size. Then, recalculate the move rate
# using the new camera size.
func update_cameras():
    # Assert camera size for the core camera
    if has_node("CoreCamera"):
        $CoreCamera.size = camera_size
    # Assert camera size and position for all other nodes
    if has_node("XrayWorld/Camera"):
        $XrayWorld/Camera.size = camera_size
    if has_node("SilhouetteWorld/Camera"):
        $SilhouetteWorld/Camera.size = camera_size
    # Since the move rate derives from the camera size, we need to update the
    # move rate as well
    update_move_rate()

# Updates the camera move rate proportional to our total zoom
func update_move_rate():
    # First, update our move vectors. Start by creating simple vectors in the 
    # correct directions.
    move_vector_FB = Vector3(-1, 0, -1)
    move_vector_LR = Vector3( 1, 0,  1).rotated(Vector3(0, 1, 0), PI / 2)
    # Next, calculate the current move rate. This is just the basic move rate
    # scaled by the camera size.
    var curr_move_rate = basic_move_rate * (camera_size / float(max_camera_size))
    # Now, we normalize and scale by the basic move rate. That creates move
    # vectors with the appropriate lengths.
    move_vector_FB = move_vector_FB.normalized() * curr_move_rate
    move_vector_LR = move_vector_LR.normalized() * curr_move_rate

# Get the viewport texture for XRay World
func get_xray_texture():
    return $XrayWorld.get_texture()

# Get the viewport texture for Silhouette World
func get_silhouette_texture():
    return $SilhouetteWorld.get_texture()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # Assert Status
    update_cameras()
    
    # If we're in the editor, back out. We don't want to mess with this next
    # step.
    if Engine.editor_hint:
        return
    
    # When the root viewport changes, our viewports on the camera rig don't
    # change with it! We need to size up those viewports appropriately! We'll
    # connect a function with the root viewport's resize event, and resize as
    # appropriate.
    get_tree().get_root().connect(
        "size_changed", self, "_on_root_viewport_size_changed"
    )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # If we're in the editor, or movement is disabled, back out!
    if Engine.editor_hint or not move_enabled:
        return
    # We moved THIIIIS much!
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
    
    self.translate( translator )
    
    if move_clamping_extents.x > 0:
        translation.x = clamp(
            translation.x,
            recenter_point.x - move_clamping_extents.x,
            recenter_point.x + move_clamping_extents.x
        )
    if move_clamping_extents.y > 0:
        translation.z = clamp(
            translation.z,
            recenter_point.z - move_clamping_extents.y,
            recenter_point.z + move_clamping_extents.y
        )

# Process an input event. Intended for single-press input events, like the
# camera
func _input(event):
    # If we're in the editor, or zoom is disabled, back out!
    if Engine.editor_hint or not zoom_enabled:
        return
    
    # Did we zoom in-or-out? If so, we need to update the cameras!
    var zoom_change = false
    
    if event.is_action_pressed("camera_recenter"):
        self.translation = recenter_point
        
    if event.is_action_pressed("camera_zoom_in"):
        camera_size = clamp(camera_size - zoom_step, min_camera_size, max_camera_size)
        zoom_change = true
        
    if event.is_action_pressed("camera_zoom_out"):
        camera_size = clamp(camera_size + zoom_step, min_camera_size, max_camera_size)
        zoom_change = true
        
    if event.is_action_pressed("debug_print"):
        print(self.size)
        
    # If we zoomed in or out, we need to change the cameras.
    if zoom_change:
        update_cameras()

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the CameraRig is misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Test 1: are the constraints sane?
    if not min_camera_size < max_camera_size:
        wrnstr += "Minium camera size exceeds or meets max camera size!\n"

    # Test 2: is the maximum camera size zero?
    if max_camera_size == 0:
        wrnstr += "Maximum camera size of 0 WILL CRASH!\n"

    # Test 3: is the minimum camera size at or below zero?
    if min_camera_size <= 0:
        wrnstr += "Camera movement at size 0 is 0! Increase the minimum size!\n"

    # Test 4: is the camera size actually in range?
    if camera_size != clamp(camera_size, min_camera_size, max_camera_size):
        wrnstr += "Camera movement at size 0 is 0! Increase the minimum size!\n"

    # Test 5: Is zoom step negative?
    if zoom_step < 0:
        wrnstr += "Zoom step is negative! Control behavior will be inverted!\n"
        
    # Test 6: Is zoom step zero?
    if zoom_step == 0:
        wrnstr += "Zoom step is zero! Zoom will not function!\n"
        
    return wrnstr
