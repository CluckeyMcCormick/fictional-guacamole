extends Spatial

# When the user clicks on the screen, we need to project a ray into the world
# to determine what exactly got clicked - how long is that ray?
const MOUSE_RAY_LENGTH = 1000

var click_waiting = false
var yielded_click

# Preload the hut so we can spawn it in at will
const HUT_SCENE = preload("res://buildings/Hut.tscn")

# Grab our current huts, once we're ready.
onready var east_hut = $DetourNavigation/EastHut
onready var north_hut = $DetourNavigation/NorthHut
onready var west_hut = $DetourNavigation/WestHut
onready var south_hut = $DetourNavigation/SouthHut

# Also, grab the transforms
onready var east_transform = $DetourNavigation/EastHut.global_transform
onready var north_transform = $DetourNavigation/NorthHut.global_transform
onready var west_transform = $DetourNavigation/WestHut.global_transform
onready var south_transform = $DetourNavigation/SouthHut.global_transform

# When the mouse is inspecting the GUI, we don't want to send out a raycast for
# pathing. So, we'll track the status using this variable.
var mouse_ignore = false

# Called every physics... frame? Cycle? Tick? Doesn't matter - 'delta' is the
# elapsed time since the previous frame.
func _physics_process(delta):
    if click_waiting:
        yielded_click.resume()
    
    return

# Process an input event. Intended for single-press input events (i.e. a button
# push/click).
func _input(event):
    if event.is_action_pressed("formation_order") and not mouse_ignore:
        yielded_click = process_mouse_click()

func process_mouse_click():
    # Get the mouse position
    var mouse_pos = get_viewport().get_mouse_position()
    # Calculate the "from" vector (more of a point, really - the point our
    # raycast will project FROM)
    var mouse_from = $CameraRig/CoreCamera.project_ray_origin( mouse_pos )
    # Calculate a point to raycast "to" by adding elongated normal
    var mouse_to = $CameraRig/CoreCamera.project_ray_normal( mouse_pos ) * MOUSE_RAY_LENGTH
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
        $Pawn.set_target_path( Array(path["points"]) )
        
    # Either way, we're no longer waiting on a click
    click_waiting = false

func _on_EastButton_toggled(button_pressed):
    # If we just turned the button on...
    if button_pressed:
        east_hut = HUT_SCENE.instance()
        east_hut.transform = east_transform
        east_hut.hiding_corner = east_hut.Corners.FRONT_LEFT
        $DetourNavigation.add_child(east_hut)
        east_hut.set_owner($DetourNavigation)
    # Otherwise, we must have turned the button off...
    else:
        # So, remove the east hut
        east_hut.queue_free()
        east_hut = null
    
    # Stop the update timer, regardless of whether it's running or not
    $NavUpdateTimer.stop()
    
    # Rebake that mesh!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

func _on_NorthButton_toggled(button_pressed):
    # If we just turned the button on...
    if button_pressed:
        north_hut = HUT_SCENE.instance()
        north_hut.transform = north_transform
        north_hut.hiding_corner = north_hut.Corners.BACK_LEFT
        $DetourNavigation.add_child(north_hut)
        north_hut.set_owner($DetourNavigation)
    # Otherwise, we must have turned the button off...
    else:
        # So, remove the east hut
        north_hut.queue_free()
        north_hut = null

    # Stop the update timer, regardless of whether it's running or not
    $NavUpdateTimer.stop()

    # Rebake that mesh!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

func _on_WestButton_toggled(button_pressed):
    # If we just turned the button on...
    if button_pressed:
        west_hut = HUT_SCENE.instance()
        west_hut.transform = west_transform
        west_hut.hiding_corner = west_hut.Corners.BACK_RIGHT
        $DetourNavigation.add_child(west_hut)
        west_hut.set_owner($DetourNavigation)
    # Otherwise, we must have turned the button off...
    else:
        # So, remove the east hut
        west_hut.queue_free()
        west_hut = null

    # Stop the update timer, regardless of whether it's running or not
    $NavUpdateTimer.stop()
        
    # Rebake that mesh!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

func _on_SouthButton_toggled(button_pressed):
    # If we just turned the button on...
    if button_pressed:
        south_hut = HUT_SCENE.instance()
        south_hut.transform = south_transform
        south_hut.hiding_corner = south_hut.Corners.FRONT_RIGHT
        $DetourNavigation.add_child(south_hut)
        south_hut.set_owner($DetourNavigation)
    # Otherwise, we must have turned the button off...
    else:
        # So, remove the east hut
        south_hut.queue_free()
        south_hut = null
    # Stop the update timer, regardless of whether it's running or not
    $NavUpdateTimer.stop()
    # Rebake that mesh!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

func _on_TowerSlider_value_changed(value):
    $DetourNavigation/FallTower.global_transform.origin.y = value
    
    # Since the user can just hold the slider and move it up and down, we delay
    # the updating until the user hasn't touched it for a set amount of time.
    # So, (re)start the timer
    $NavUpdateTimer.start()

func _on_NavUpdateTimer_timeout():
    # Rebake that mesh!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

# These signals disable the mouse when it hovers over one of our interactable
# GUI elements
func _on_TowerSlider_mouse_entered():
    mouse_ignore = true
func _on_EastButton_mouse_entered():
    mouse_ignore = true
func _on_NorthButton_mouse_entered():
    mouse_ignore = true
func _on_WestButton_mouse_entered():
    mouse_ignore = true
func _on_SouthButton_mouse_entered():
    mouse_ignore = true

# These signals enable the mouse once we move off of our GUI elements.
func _on_TowerSlider_mouse_exited():
    mouse_ignore = false
func _on_EastButton_mouse_exited():
    mouse_ignore = false
func _on_NorthButton_mouse_exited():
    mouse_ignore = false
func _on_WestButton_mouse_exited():
    mouse_ignore = false
func _on_SouthButton_mouse_exited():
    mouse_ignore = false
