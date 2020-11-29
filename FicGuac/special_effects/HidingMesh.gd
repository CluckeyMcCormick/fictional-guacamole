extends MeshInstance

# The default beahvior for the HidingMesh is to show when hidden and hide when
# visible - this configurable allows us to invert this behavior if need be. 
export(bool) var show_on_hidden = true
# Is this mesh currently hidden from the camera?
var _cam_hide

# In order to check whether the hiding mesh is visible, we need to do constant
# raycasts to a camera node. If we hit something, it's not visible. If we don't,
# then it's visible. What's the node path for the camera we're casting to? Note
# that this doesn't HAVE to be a camera but it really SHOULD be a camera.
export(NodePath) var target_camera
# We resolve the node path into this variable.
var target_camera_node

# As explained above, we need to use a physics raycast to determine visibility.
# What layers does that raycast collide with?
export(int, LAYERS_3D_PHYSICS) var occlusion_layers

export(float) var animation_length = -1

enum { SHRINKING, GROWING, HIDDEN, SHOWING}
var _hide_state = SHOWING

func _ready():
    # Resolve the target camera path
    target_camera_node = get_node(target_camera)
    # By default, set the HidingMesh to visible. This will help load the frame
    # dips up front.
    self.visible = true

func _physics_process(delta):
    # If we don't have a camera to raycast to, BACK OUT!
    if target_camera_node == null:
        return
    
    # First, let's get the space state.
    var space_state = get_world().direct_space_state
    # Now, cast from this mesh to that camera
    var result = space_state.intersect_ray(
        self.global_transform.origin, # Ray origin
        target_camera_node.global_transform.origin, # Ray destination
        [], # Node exclusion list; we exlude nothing!
        occlusion_layers # Collision MASK - what to collide with
    )
    
    # Evaluate: did we get a result back? If we did, then the camera is hidden.
    # We'll stick the evaluation in our camera_hidden variable.
    _cam_hide = not result.empty()
    
    # If we have to show ourselves...
    if (show_on_hidden and _cam_hide) or (not show_on_hidden and not _cam_hide):
        # And we aren't already grown or growing...
        if _hide_state == SHRINKING or _hide_state == HIDDEN:
            # Then show the mesh. Or grow the mesh. One of the two, this
            # function will handle it.
            _start_showing_process()
    # Otherwise, we need to hide ourselves...
    else:
        # BUT, we should only hide ourselves if we're already showing.
        if _hide_state == GROWING or _hide_state == SHOWING:
            # Then hide the mesh. Or shrink the mesh. One of the two, this
            # function will handle it.
            _start_hiding_process()

func _start_showing_process():
    # Need to make sure we're visible.
    self.visible = true
    
    # If we don't have an animation length...
    if animation_length <= 0:
        # Assert scale (just in case)
        self.scale = Vector3(1, 1, 1)
        # Current state is now showing
        _hide_state = SHOWING
        # and back out
        return
    
    # Otherwise, we're definitely going to animate. The state is now GROWING
    _hide_state = GROWING
    
    #print("GROWING!")
    
    # Stop any tweens in progress.
    $Tween.stop_all()
    
    # Set the tween up to grow the mesh
    $Tween.interpolate_property(
        self, # Target node
        "scale", # Property to tween
        self.scale, # Initial value - use the current scale so it seems fluid
        Vector3(1, 1, 1), # Target value - we grow to default size
        animation_length, # Time period - configurable!
        Tween.TRANS_LINEAR, # Transition type - control how the values flow
        Tween.EASE_IN_OUT # Easing type, for more fine control on the above
    )
    # Start that tween!
    $Tween.start()

func _start_hiding_process():
    
    # If we don't have an animation length...
    if animation_length <= 0:
        # Just hide the thing then, I guess.
        self.visible = false
        # Current state is now hidden
        _hide_state = HIDDEN
        # Back out.
        return
        
    # Otherwise, we're definitely going to animate. The state is now SHRINKING
    _hide_state = SHRINKING
    
    #print("SHRINKING!")
    
    # Stop any tweens in progress.
    $Tween.stop_all()
    
    # Set the tween up to shrink the mesh
    $Tween.interpolate_property(
        self, "scale",
        self.scale, Vector3(0, 0, 0), animation_length,
        Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
    )
    
    # START THE SHRINK!
    $Tween.start()

func _on_Tween_tween_completed(object, key):
    # If we were growing, we're now showing
    if _hide_state == GROWING:
        _hide_state = SHOWING
        #print("Grown!")
    
    # If we were shrinking, we're now hidden
    elif _hide_state == SHRINKING:
        _hide_state = HIDDEN
        #print("Shrank!")
        # Hide the mesh, to save processing
        self.visible = false

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the HidingMesh is misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Test 1: Did we actually get handed a camera node?
    if target_camera == "":
        wrnstr += "User MUST provide a Target Camera node!\n"

    # Test 2: is the camera node real? Does it exist?
    if get_node(target_camera) == null:
        wrnstr += "Provided Target Camera node doesn't exist!\n"

    # Test 3: is the camera node the right type? It doesn't have to be
    if typeof(get_node(target_camera)) != typeof(Camera):
        wrnstr += "Target Camera is not actually a camera!\n"
        wrnstr += "It NEEDS to be a spatial, but it SHOULD be a Camera!\n"
        
    return wrnstr
