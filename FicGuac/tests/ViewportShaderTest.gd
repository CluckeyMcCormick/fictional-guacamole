extends Spatial

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Current Pawn we're testing.
var test_pawn

# The currently yielded function objects. A 'null' value means we need to
# move on to the next test!
var yield_func = null

# The list of test functions that we're gonna call
var test_list = [
    funcref(self, "test_hut"), funcref(self, "test_farm"),
    funcref(self, "test_woods"), funcref(self, "test_opaque"),
    funcref(self, "test_transperancy"), funcref(self, "test_xray_alpha"),
    funcref(self, "test_xray_default"), funcref(self, "test_xray_nodepth"),
    funcref(self, "test_multiply"), funcref(self, "test_fill"),
    funcref(self, "test_normal")
]

# Our list of pawns to test, in the order we want to test them
onready var pawn_list = [
    $XrayPawnAlpha, $XrayPawnDefault, $XrayPawnNoDepth,
    $MultiplyPawn, $FillPawn, $NormalPawn
]

var pawn_names = [
    "X-Ray (Alpha)", "X-Ray (Default)", "X-Ray (No Depth)",
    "Multiply", "Fill", "Normal (With Modulate)"
]

var test_index
var pawn_index

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _ready(): 
    # Test index is -1, since we're about to increment over to the first test
    # (which resides at index 0)
    test_index = -1
    # Start at the first pawn
    pawn_index = 0
    test_pawn = $XrayPawnAlpha
    # Kick off the first test!
    next_test()

func _process(delta):
    # If we have a valid yielded func, then back out. There's nothing here for
    # us.
    if yield_func != null and yield_func.is_valid():
        return
        
    # Otherwise - NEXT TEST!
    next_test()

# Special clean up function - we have to reset the time scale when we exit.
func _exit_tree():
    Engine.set_time_scale(1)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Handlers
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_Slider_value_changed(value):
    $TimeGUI/TimeScale/Value.text = str(value)
    Engine.set_time_scale(value)

func _on_SkipButton_pressed():
    # If we've been told to skip, then skip!
    next_test()

# Generic "path-complete" signal capture function. Just calls our current yield
# function (if we have one).
func _on_test_pawn_path_complete(pawn, position):
    # If we don't have a valid yield func, ensure we're null and back out!
    if yield_func == null or not yield_func.is_valid():
        yield_func = null
        return
    # Otherwise, call the yield func!
    yield_func = yield_func.resume()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Return all of the pawns to their starting position.
func all_return():
    # The currently targeted Pawn
    var targ_pawn
    # The target position node
    var targ_node
    # The created path
    var new_path
    
    # XRAY - Alpha
    targ_pawn = $XrayPawnAlpha
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/A
    targ_pawn.move_to_point(targ_node.global_transform.origin)
    
    # XRAY - Default
    targ_pawn = $XrayPawnDefault
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/B
    targ_pawn.move_to_point(targ_node.global_transform.origin)
    
    # XRAY - No Depth
    targ_pawn = $XrayPawnNoDepth
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/C
    targ_pawn.move_to_point(targ_node.global_transform.origin)

    # Multiply
    targ_pawn = $MultiplyPawn
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/D
    targ_pawn.move_to_point(targ_node.global_transform.origin)
    
    # Fill
    targ_pawn = $FillPawn
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/E
    targ_pawn.move_to_point(targ_node.global_transform.origin)

    # Normal
    targ_pawn = $NormalPawn
    targ_node = $Navigation/NavigationMeshInstance/HomePlinth/F
    targ_pawn.move_to_point(targ_node.global_transform.origin)

# Does the processing to set us onto the next test. Isolated in a function so
# that it can be called from multiple locations.
func next_test():
    # Otherwise, we need to start a test! Increment our test index...
    test_index += 1
        
    # If we've run out of tests...
    if test_index >= test_list.size():
        # Then we need to switch to the next pawn!
        pawn_index = (pawn_index + 1) % pawn_list.size()
        
        # Get that brand-new pawn!
        test_pawn = pawn_list[pawn_index]
        
        # Set back to test 0
        test_index = 0
    
    # Always set the pawn text
    $TestGUI/CurrentPawn/Value.text = pawn_names[pawn_index]
    
    # Return any elements out of place. We have to do this here in case a skip
    # was ordered.
    all_return()
    
    # Get the new test function
    yield_func = test_list[test_index]
    # Call it!
    yield_func = yield_func.call_func()
    # Now the test functions and signal functions will handle the rest!

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Standardized Test Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# A general test for a given Pawn involves circling a given obstacle, then
# crossing through it so as to form an X. We need 5 nodes - the back, left,
# right, front, and center.
func general_test_pattern(back, left, right, front, center):
    # Connect to the test pawn
    test_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    
    # Path around the object, yielding each time
    test_pawn.move_to_point(left.global_transform.origin)
    yield()
    test_pawn.move_to_point(back.global_transform.origin)
    yield()
    test_pawn.move_to_point(right.global_transform.origin)
    yield()
    test_pawn.move_to_point(front.global_transform.origin)
    yield()
    test_pawn.move_to_point(left.global_transform.origin)
    yield()

    # Criss-cross A
    test_pawn.move_to_point(front.global_transform.origin)
    yield()
    test_pawn.move_to_point(center.global_transform.origin)
    yield()
    test_pawn.move_to_point(back.global_transform.origin)
    yield()
    
    # Criss-cross B
    test_pawn.move_to_point(left.global_transform.origin)
    yield()
    test_pawn.move_to_point(center.global_transform.origin)
    yield()
    test_pawn.move_to_point(right.global_transform.origin)
    yield()
    
    # Test done! Disconnect the path_complete signal!
    test_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    # Return null to indicate we're done
    return null

# In order to test how shaders interact with each other, we need to move a
# given pawn as well as a the pawn we're currently testing. We move them in,
# out, and around a variety of surfaces.
func multiple_pawn_test_pattern(alt_pawn):

    # Opaque test points
    var opaque_back = $Navigation/NavigationMeshInstance/OpaquePlinth/Back
    var opaque_left = $Navigation/NavigationMeshInstance/OpaquePlinth/Left
    var opaque_right = $Navigation/NavigationMeshInstance/OpaquePlinth/Right
    var opaque_front = $Navigation/NavigationMeshInstance/OpaquePlinth/Front
    var opaque_center = $Navigation/NavigationMeshInstance/OpaquePlinth/Center

    # Transperancy test points
    var trans_back = $Navigation/NavigationMeshInstance/TransparentPlinth/Back
    var trans_left = $Navigation/NavigationMeshInstance/TransparentPlinth/Left
    var trans_right = $Navigation/NavigationMeshInstance/TransparentPlinth/Right
    var trans_front = $Navigation/NavigationMeshInstance/TransparentPlinth/Front
    var trans_center = $Navigation/NavigationMeshInstance/TransparentPlinth/Center

    # Partial Test Points
    var part_back = $Navigation/NavigationMeshInstance/PartialPlinth/Back
    var part_left = $Navigation/NavigationMeshInstance/PartialPlinth/Left
    var part_right = $Navigation/NavigationMeshInstance/PartialPlinth/Right
    var part_front = $Navigation/NavigationMeshInstance/PartialPlinth/Front
    var part_center = $Navigation/NavigationMeshInstance/PartialPlinth/Center

    # Woods Test Points
    var woods_back = $Navigation/NavigationMeshInstance/Woods/Back
    var woods_left = $Navigation/NavigationMeshInstance/Woods/Left
    var woods_right = $Navigation/NavigationMeshInstance/Woods/Right
    var woods_front = $Navigation/NavigationMeshInstance/Woods/Front
    var woods_center = $Navigation/NavigationMeshInstance/Woods/Center
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Subtest A - Opaque
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Test how the shaders interact when embedded in an opaque object
    
    # Move the alternate pawn to the opaque object
    alt_pawn.move_to_point(opaque_center.global_transform.origin)
    alt_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    yield()
    alt_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    test_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    # Cycle around the object
    test_pawn.move_to_point(opaque_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_back.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_right.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_left.global_transform.origin)
    yield()
    # Criss-cross A
    test_pawn.move_to_point(opaque_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_back.global_transform.origin)
    yield()
    # Criss-cross B
    test_pawn.move_to_point(opaque_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(opaque_right.global_transform.origin)
    yield()
    # Connect
    test_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Subtest B - Transparent
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Test how the shaders interact when embedded in a transparent object set to
    # "Always" Depth draw

    # Move the alternate pawn to the transparent object
    alt_pawn.move_to_point(trans_center.global_transform.origin)
    alt_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    yield()
    alt_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")

    test_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    # Cycle around the object
    test_pawn.move_to_point(trans_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_back.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_right.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_left.global_transform.origin)
    yield()
    # Criss-cross A
    test_pawn.move_to_point(trans_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_back.global_transform.origin)
    yield()
    # Criss-cross B
    test_pawn.move_to_point(trans_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(trans_right.global_transform.origin)
    yield()
    # Connect
    test_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Subtest C - Partial
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Test how the shaders interact when one pawn is exposed and the other is
    # hidden

    # Move the alternate pawn to the partial object
    alt_pawn.move_to_point(part_center.global_transform.origin)
    alt_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    yield()
    alt_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    test_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    # Cycle around the object
    test_pawn.move_to_point(part_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_back.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_right.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_left.global_transform.origin)
    yield()
    # Criss-cross A
    test_pawn.move_to_point(part_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_back.global_transform.origin)
    yield()
    # Criss-cross B
    test_pawn.move_to_point(part_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(part_right.global_transform.origin)
    yield()
    # Connect
    test_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
 
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # Subtest D - Woods
    #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Test how the shaders interact with each other when also interacting with 
    # sprites set to opaque-prepass Depth Draw

    # Move the alternate pawn to the partial object
    alt_pawn.move_to_point(woods_center.global_transform.origin)
    alt_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    yield()
    alt_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    test_pawn.connect("path_complete", self, "_on_test_pawn_path_complete")
    # Cycle around the object
    test_pawn.move_to_point(woods_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_back.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_right.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_left.global_transform.origin)
    yield()
    # Criss-cross A
    test_pawn.move_to_point(woods_front.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_back.global_transform.origin)
    yield()
    # Criss-cross B
    test_pawn.move_to_point(woods_left.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_center.global_transform.origin)
    yield()
    test_pawn.move_to_point(woods_right.global_transform.origin)
    yield()
    # Connect
    test_pawn.disconnect("path_complete", self, "_on_test_pawn_path_complete")
    
    # Return null to indicate we're done
    return null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# The TESTS!!!!!!
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func test_hut():
    var back = $Navigation/NavigationMeshInstance/Hut/Back
    var left = $Navigation/NavigationMeshInstance/Hut/Left
    var right = $Navigation/NavigationMeshInstance/Hut/Right
    var front = $Navigation/NavigationMeshInstance/Hut/Front
    var center = $Navigation/NavigationMeshInstance/Hut/Center
    
    $TestGUI/CurrentTest/Value.text = "Hut Test"
    
    return general_test_pattern(back, left, right, front, center)

func test_farm():
    var back = $Navigation/NavigationMeshInstance/Farm/Back
    var left = $Navigation/NavigationMeshInstance/Farm/Left
    var right = $Navigation/NavigationMeshInstance/Farm/Right
    var front = $Navigation/NavigationMeshInstance/Farm/Front
    var center = $Navigation/NavigationMeshInstance/Farm/Center
    
    $TestGUI/CurrentTest/Value.text = "Farm Test"
    
    return general_test_pattern(back, left, right, front, center)

func test_woods():
    var back = $Navigation/NavigationMeshInstance/Woods/Back
    var left = $Navigation/NavigationMeshInstance/Woods/Left
    var right = $Navigation/NavigationMeshInstance/Woods/Right
    var front = $Navigation/NavigationMeshInstance/Woods/Front
    var center = $Navigation/NavigationMeshInstance/Woods/Center
    
    $TestGUI/CurrentTest/Value.text = "Woods Test"
    
    return general_test_pattern(back, left, right, front, center)

func test_opaque():
    var back = $Navigation/NavigationMeshInstance/OpaquePlinth/Back
    var left = $Navigation/NavigationMeshInstance/OpaquePlinth/Left
    var right = $Navigation/NavigationMeshInstance/OpaquePlinth/Right
    var front = $Navigation/NavigationMeshInstance/OpaquePlinth/Front
    var center = $Navigation/NavigationMeshInstance/OpaquePlinth/Center
    
    $TestGUI/CurrentTest/Value.text = "Opaque Surface Test"
    
    return general_test_pattern(back, left, right, front, center)

func test_transperancy():
    var back = $Navigation/NavigationMeshInstance/TransparentPlinth/Back
    var left = $Navigation/NavigationMeshInstance/TransparentPlinth/Left
    var right = $Navigation/NavigationMeshInstance/TransparentPlinth/Right
    var front = $Navigation/NavigationMeshInstance/TransparentPlinth/Front
    var center = $Navigation/NavigationMeshInstance/TransparentPlinth/Center
    
    $TestGUI/CurrentTest/Value.text = "Transperant Surface Test (Always)"
    
    return general_test_pattern(back, left, right, front, center)

func test_xray_alpha():
    if test_pawn == $XrayPawnAlpha:
        return null
    
    $TestGUI/CurrentTest/Value.text = "X-Ray Alpha Crossover Test"
        
    return multiple_pawn_test_pattern($XrayPawnAlpha)

func test_xray_default():
    if test_pawn == $XrayPawnDefault:
        return null
    
    $TestGUI/CurrentTest/Value.text = "X-Ray Default Crossover Test"
        
    return multiple_pawn_test_pattern($XrayPawnDefault)

func test_xray_nodepth():
    if test_pawn == $XrayPawnNoDepth:
        return null
        
    $TestGUI/CurrentTest/Value.text = "X-Ray No Depth Crossover Test"
        
    return multiple_pawn_test_pattern($XrayPawnNoDepth)

func test_multiply():
    if test_pawn == $MultiplyPawn:
        return null
        
    $TestGUI/CurrentTest/Value.text = "Multiply Crossover Test"
        
    return multiple_pawn_test_pattern($MultiplyPawn)

func test_fill():
    if test_pawn == $FillPawn:
        return null
        
    $TestGUI/CurrentTest/Value.text = "Fill Crossover Test"
        
    return multiple_pawn_test_pattern($FillPawn)

func test_normal():
    if test_pawn == $NormalPawn:
        return null
        
    $TestGUI/CurrentTest/Value.text = "Normal Crossover Test"
        
    return multiple_pawn_test_pattern($NormalPawn)
