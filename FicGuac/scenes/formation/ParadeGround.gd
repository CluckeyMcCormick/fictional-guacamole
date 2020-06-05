extends Spatial

# When the user clicks on the screen, we need to project a ray into the world
# to determine what exactly got clicked - how long is that ray?
const MOUSE_RAY_LENGTH = 1000

# The user clicked the mouse - when we get to processing physics stuff, we'll
# need
var mouse_pending = false
# The two points that will make up our ray - an origin (from) and a destination
# (to)
var mouse_from
var mouse_to

# Called when the node enters the scene tree for the first time.
func _ready():
    $FloatBox/SpinTween.interpolate_property(
        $FloatBox, "rotation_degrees",
        Vector3(0, 0, 0), Vector3(0, 360, 0), 20,
        Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $FloatBox/SpinTween.start()
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Called every physics... frame? Cycle? Tick? Doesn't matter - 'delta' is the
# elapsed time since the previous frame.
func _physics_process(delta):
    if mouse_pending:
        # So, get the space state to query
        var space_state = get_world().direct_space_state
        # QUERY, QUERY, QUERY!
        var result = space_state.intersect_ray(
            mouse_from, mouse_to, # Ray origin, Ray destination
            [], # Node exclusion list; we exlude nothing!
            1 # Collision MASK - what to collide with. BIT 1 is terrain/environ
        )
        # If our query actually got somtething
        if result:
            # Order the unit to move
            $Unit.order_move(result.position)
            # We did it! Don't have any mouse stuff pending anymore!
            mouse_pending = false

# Process an input event. Intended for single-press input events, like the
# camera
func _input(event):
    if event.is_action_pressed("formation_order"):
        # Get the mouse position
        var mouse_pos = get_viewport().get_mouse_position()
        # Calculate the "from" vector (more of a point, really - the point our
        # raycast will project FROM)
        mouse_from = $Camera.project_ray_origin( mouse_pos )
        # Calculate a point to raycast "to" by adding elongated normal
        mouse_to = mouse_from + ( $Camera.project_ray_normal( mouse_pos ) * MOUSE_RAY_LENGTH )
        mouse_pending = true
