extends Spatial

# When the user clicks on the screen, we need to project a ray into the world
# to determine what exactly got clicked - how long is that ray?
const MOUSE_RAY_LENGTH = 1000

var click_waiting = false
var yielded_click

# Called every physics... frame? Cycle? Tick? Doesn't matter - 'delta' is the
# elapsed time since the previous frame.
func _physics_process(delta):
    if click_waiting:
        yielded_click.resume()

# Process an input event. Intended for single-press input events (i.e. a button
# push/click).
func _input(event):
    if event.is_action_pressed("formation_order"):
        yielded_click = process_mouse_click()

func process_mouse_click():
    # Get the mouse position
    var mouse_pos = get_viewport().get_mouse_position()
    # Calculate the "from" vector (more of a point, really - the point our
    # raycast will project FROM)
    var mouse_from = $CoreCamera.project_ray_origin( mouse_pos )
    # Calculate a point to raycast "to" by adding elongated normal
    var mouse_to = $CoreCamera.project_ray_normal( mouse_pos ) * MOUSE_RAY_LENGTH
    mouse_to += mouse_from
    
    # Yield until we can query. Make note that we are waiting on a click
    click_waiting = true
    yield()
    
    # Get our detour mesh
    var detour_mesh = $DetourNavigation/DetourNavigationMesh
    
    # We're back! We should now be in the _physics_process, so we can query the
    # world using raycasts. First, let's get the space state.
    var space_state = get_world().direct_space_state
    # QUERY, QUERY, QUERY!
    var result = space_state.intersect_ray(
        mouse_from, mouse_to, # Ray origin, Ray destination
        [], # Node exclusion list; we exlude nothing!
        1 # Collision MASK - what to collide with. BIT 0 is terrain (floor/path)
    )
    
    # If our query actually got something...
    if result:
        # Get the path
        var path = detour_mesh.find_path($Pawn.get_translation(), result.position)
        # Set the path!
        $Pawn.current_path = Array(path["points"])
        
    # Either way, we're no longer waiting on a click
    click_waiting = false
