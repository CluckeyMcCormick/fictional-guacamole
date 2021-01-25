extends Spatial

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# We're gonna allocate a bunch of space here just for getting nodes, since the
# paths here are STUPID and LONG.

# Step Test Nodes
onready var step_node = $DetourNavigation/DetourNavigationMesh/DynamicStep/
onready var step_label = $DetourNavigation/DetourNavigationMesh/DynamicStep/QuadLabel
onready var step_target = $DetourNavigation/DetourNavigationMesh/DynamicStep/Target

# Step Test Nodes
onready var slope_node = $DetourNavigation/DetourNavigationMesh/DynamicSlope
onready var slope_mesh = $DetourNavigation/DetourNavigationMesh/DynamicSlope/Mesh
onready var slope_shape = $DetourNavigation/DetourNavigationMesh/DynamicSlope/Shape
onready var slope_landing = $DetourNavigation/DetourNavigationMesh/DynamicLanding
onready var slope_label = $DetourNavigation/DetourNavigationMesh/SlopeLabel
onready var slope_target = $DetourNavigation/DetourNavigationMesh/DynamicLanding/Target

# Fall Test Nodes
onready var fall_target = $DetourNavigation/DetourNavigationMesh/FallTarget

# Home Test
onready var home_target = $DetourNavigation/DetourNavigationMesh/HomeTarget

# What's the length of our prism mesh on x (and hence, the length of our
# theoretical triangle).
const SLOPE_LEN_X = 4
# What's the slope angle we default to? We have to set this at the start because
# we can't control it as easily as the dynamic step.
const DEFAULT_SLOPE_ANGLE = 45

# The currently yielded function objects. A 'null' value means we're not waiting
# on anything.
var yield_func = null

# Grab the default position of the Pawn so we can force the Pawn back here, if
# need be.
onready var pawn_default_pos = $KinematicPawn.global_transform.origin

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # Set the default slope angle
    $ControlContainer/SlopeSlider.value = DEFAULT_SLOPE_ANGLE

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# GUI Signals - Configuration Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Because baking the nav-mesh is a time intensive process, we purposefully delay
# it until the user has stopped messing with the sliders. The UpdateTimer is our
# delaying factor; this function calls the bake method.
func _on_UpdateTimer_timeout():
    # Bake it!
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()
    $UpdateTimer.stop()

# When the user changes the configured step height, we adjust the step
# accordingly.
func _on_StepSlider_value_changed(value):
    # Update the step label with our string
    step_label.label_text = "%0.3f" % [value]
    # Move our dynamic step downwards
    step_node.global_transform.origin.y = -1.0 + value
    
    # If we're about to do an update...
    if not $UpdateTimer.is_stopped():
        # Stop the timer. We'll put off the update for a hot second.
        $UpdateTimer.stop()
    # Start the update timer
    $UpdateTimer.start()

# When the user changes the configured slope angle, we adjust the slope
# accordingly.
func _on_SlopeSlider_value_changed(value):
    # Use MATH to determine our appropriate measures
    var hypotenuse = SLOPE_LEN_X / cos(deg2rad(value))
    var height = SLOPE_LEN_X * tan(deg2rad(value))
    
    # Set our prism and landing height
    slope_mesh.mesh.size.y = height
    slope_node.global_transform.origin.y = height / 2
    slope_landing.global_transform.origin.y = height
    
    # Make sure our collision model/mesh matches with the slope
    slope_shape.shape.extents.x = hypotenuse / 2
    slope_shape.rotation_degrees.z = -value
    
    # Set the label
    slope_label.label_text = "%d DEG" % value
    
    # If we're about to do an update...
    if not $UpdateTimer.is_stopped():
        # Stop the timer. We'll put off the update for a hot second.
        $UpdateTimer.stop()
    # Start the update timer
    $UpdateTimer.start()
    
func _on_FallSlider_value_changed(value):
    # Move the fall target to match the configured height
    $DetourNavigation/DetourNavigationMesh/FallTarget.global_transform.origin.y = value

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Test Signals
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_SlopeButton_pressed():
    yield_func = slope_test()

func _on_StepButton_pressed():
    yield_func = step_test()

func _on_FallButton_pressed():
    yield_func = fall_test()

func _on_CancelButton_pressed():
    # Break the update chain
    yield_func = null
    
    # Clear the Pawn's current targets
    $KinematicPawn.set_target_path([])
    $KinematicPawn.set_target_position(null)
    
    # Stop all timers
    $UpdateTimer.stop()
    $FallTestTimer.stop()
    
    # Reset test mode
    exit_test_mode()
    
    # Move the pawn "Back" to home
    $KinematicPawn.global_transform.origin = pawn_default_pos

func _on_KinematicPawn_path_complete(pawn, position):
    if yield_func:
        yield_func = yield_func.resume(true)

func _on_KinematicPawn_error_goal_stuck(pawn, target_position):
    if yield_func:
        yield_func = yield_func.resume(false)

func _on_FallTestTimer_timeout():
    if yield_func:
        yield_func = yield_func.resume()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Test Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Enter
func enter_test_mode():
    $ControlContainer/SlopeSlider.editable = false
    $ControlContainer/StepSlider.editable = false
    
    $ControlContainer/ButtonContainer/SlopeButton.disabled = true
    $ControlContainer/ButtonContainer/StepButton.disabled = true
    $ControlContainer/ButtonContainer/FallButton.disabled = true
    
     # If we're about to do an update...
    if not $UpdateTimer.is_stopped():
        # Stop it
        $UpdateTimer.stop()
        
    # Force bake the navmesh
    $DetourNavigation/DetourNavigationMesh.bake_navmesh()

func exit_test_mode():
    $ControlContainer/SlopeSlider.editable = true
    $ControlContainer/StepSlider.editable = true
    
    $ControlContainer/ButtonContainer/SlopeButton.disabled = false
    $ControlContainer/ButtonContainer/StepButton.disabled = false
    $ControlContainer/ButtonContainer/FallButton.disabled = false

func slope_test():
    # Enter test mode
    enter_test_mode()
    
    # Get the path
    var path = $DetourNavigation/DetourNavigationMesh.find_path(
        $KinematicPawn.get_translation(), 
        slope_target.global_transform.origin
    )

    # If we didn't actually get a path (it can happen!) report to the user and
    # dismantle the test
    if Array(path["points"]).empty():
        # Inform the user
        print("No Path! Slope too steep!")
        # Exit test mode
        exit_test_mode()
        # Return null to break the test chain
        return null
    
    # Set the path!
    $KinematicPawn.set_target_path( Array(path["points"]) )
    
    var result = yield()
    
    if result:
        print("Test Success!")
    else:
        print("Test Failed!")
    
    # Clear the Pawn's current targets
    $KinematicPawn.set_target_path([])
    $KinematicPawn.set_target_position(null)
    
    # Path home!
    path = $DetourNavigation/DetourNavigationMesh.find_path(
        $KinematicPawn.get_translation(), 
        home_target.global_transform.origin
    )
    
    # Set the path!
    $KinematicPawn.set_target_path( Array(path["points"]) )

    # Yield until the Pawn is back home. Ignore the result
    yield()

    # Exit test mode
    exit_test_mode()
    
    # Return null so whatever called the yield is cleared
    return null

func step_test():
    # Enter test mode
    enter_test_mode()
    
    # Get the path
    var path = $DetourNavigation/DetourNavigationMesh.find_path(
        $KinematicPawn.get_translation(), 
        step_target.global_transform.origin
    )
    
    # If we didn't actually get a path (it can happen!) report to the user and
    # dismantle the test
    if Array(path["points"]).empty():
        # Inform the user
        print("No Path! Step too high!")
        # Exit test mode
        exit_test_mode()
        # Return null to break the test chain
        return null
    
    # Set the path!
    $KinematicPawn.set_target_path( Array(path["points"]) )
    
    var result = yield()
    
    if result:
        print("Test Success!")
    else:
        print("Test Failed!")
    
    # Clear the Pawn's current targets
    $KinematicPawn.set_target_path([])
    $KinematicPawn.set_target_position(null)
    
    # Path home!
    path = $DetourNavigation/DetourNavigationMesh.find_path(
        $KinematicPawn.get_translation(), 
        home_target.global_transform.origin
    )
    
    # Set the path!
    $KinematicPawn.set_target_path( Array(path["points"]) )

    # Yield until the Pawn is back home. Ignore the result
    yield()

    # Exit test mode
    exit_test_mode()
    
    # Return null so whatever called the yield is cleared
    return null

func fall_test():
    # Enter test mode
    enter_test_mode()
    
    # Create a point beneath the fall target to fall onto
    var fall_landing_zone = fall_target.global_transform.origin
    fall_landing_zone.y = 0
    
    # Get the path from t
    var path = $DetourNavigation/DetourNavigationMesh.find_path(
        fall_landing_zone, 
        home_target.global_transform.origin
    )

    # If we didn't actually get a path (it can happen!) report to the user and
    # dismantle the test
    if Array(path["points"]).empty():
        # Inform the user
        print("No Path! Slope too steep!")
        # Exit test mode
        exit_test_mode()
        # Return null to break the test chain
        return null
    
    # Set the path!
    $KinematicPawn.set_target_path( Array(path["points"]) )
    
    # Now: teleport to the fall position and FALL
    $KinematicPawn.global_transform.origin = fall_target.global_transform.origin
    
    # Yield until we've returned to the home position
    var result = yield()
    
    if result:
        print("Test Success!")
    else:
        print("Test Failed!")

    # Exit test mode
    exit_test_mode()
    
    # Return null so whatever called the yield is cleared
    return null
