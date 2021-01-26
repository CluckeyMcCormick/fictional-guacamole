extends Spatial

# This script tests the UnitPawn's walking functionality by making it rub it's
# face against various obstacles to see if it behaves correctly. We do this by
# feeding it paths, which are made of points demarcated by MeshInstance objects
# that are just multicolored little boxes.

# We have two items that we're testing - how pawns move up a slope and how
# pawns do a "step up" when hitting a very slight ledge. However, sometimes we
# miiiiiight want to just skip doing a given step. So we'll have these external
# configurables so we can easily switch tests on and off.
export(bool) var do_step_test = true
export(bool) var do_ramp_test = true

# To determine what we're doing at any given time, we'll use these enums
enum {TO_START, IN_PROGRESS, SUCCESS_RETURN, FAIL_RETURN}
# And we'll use them in this variable!
var test_state = null

# Here's where we'll store the tests
var all_tests = []

# This is the index of our current test
var test_index = 0

# And this is the current test array that we're working on. We'll be using this
# as a stack
var current_test_path = null

# We, by default, use the default camera
var default_camera = true

# This function builds out the paths, more or less by hand. I don't recommend
# looking at it, it's awful.
func build_out_tests():
    # Temporary variable for assignments
    var temp
    
    # Each test will be defined by paths - but each category of path has a 
    # return path, so we'll store these categories ahead of time.
    var ramp_return_path = [ $Targets/PostRamp01, $Targets/Aisle01 ]
    var step_return_path = [ $Targets/PostStep00, $Targets/Aisle00 ]
    
    # First Three Steps
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep01)
        temp.push_front($Targets/Aisle01)
        all_tests.append(temp)

        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep02)
        temp.push_front($Targets/Aisle02)
        all_tests.append(temp)
        
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep03)
        temp.push_front($Targets/Aisle03)
        all_tests.append(temp)
    
    # First Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp02)
        temp.push_front($Targets/Aisle04)
        all_tests.append(temp)
      
    # Fourth Step
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep04)
        temp.push_front($Targets/Aisle04)
        all_tests.append(temp)
    
    # Second Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp03)
        temp.push_front($Targets/Aisle05)
        all_tests.append(temp)
    
    # Fifth Step
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep05)
        temp.push_front($Targets/Aisle05)
        all_tests.append(temp)
        
    # Third Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp04)
        temp.push_front($Targets/Aisle06)
        all_tests.append(temp)
    
    # Sixth Step
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep06)
        temp.push_front($Targets/Aisle06)
        all_tests.append(temp)
        
    # Fourth Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp05)
        temp.push_front($Targets/Aisle07)
        all_tests.append(temp)
    
    # Seventh Step
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep07)
        temp.push_front($Targets/Aisle07)
        all_tests.append(temp)
        
    # Fifth Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp06)
        temp.push_front($Targets/Aisle08)
        all_tests.append(temp)
    
    # Eighth Step
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep08)
        temp.push_front($Targets/Aisle08)
        all_tests.append(temp)
        
    # Sixth Ramp
    if do_ramp_test:
        temp = ramp_return_path.duplicate()
        temp.push_front($Targets/PostRamp07)
        temp.push_front($Targets/Aisle09)
        all_tests.append(temp)
    
    # Last Four Steps
    if do_step_test:
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep09)
        temp.push_front($Targets/Aisle09)
        all_tests.append(temp)

        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep10)
        temp.push_front($Targets/Aisle10)
        all_tests.append(temp)
        
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep11)
        temp.push_front($Targets/Aisle11)
        all_tests.append(temp)
        
        temp = step_return_path.duplicate()
        temp.push_front($Targets/PostStep12)
        temp.push_front($Targets/Aisle12)
        all_tests.append(temp)

# Called when the node enters the scene tree for the first time.
func _ready():
    # If both tests are set to off....
    if not do_step_test and not do_ramp_test:
        # That can't happen! Let's at least do the ramp test, that's shorter
        do_ramp_test = true
        
    # Build out our tests
    build_out_tests()
    
    # Set our test up for success by initializing our variables!
    test_state = TO_START
    current_test_path = all_tests[test_index].duplicate()
    set_pawn_target( current_test_path.pop_front() )

# Update the GUI so we know what's up
func _process(delta):
    # Set the test text
    $Items/Labels/TestLabel/Info.text = str(test_index)
    # Set the progress bar to reflect the passage of  T I M E
    $Items/Labels/TimerLabel/ProgressBar.value = $Timer.wait_time - $Timer.time_left
    # Set the target label to the target vector
    $Items/Labels/TargetLabel/Info.text = str( $Pawn/KinematicDriverMachine.target_position )
    # Set the position label to the position vector
    $Items/Labels/MachineStateLabel/Info.text = str( $Pawn/KinematicDriverMachine.state_key )
    # Set the distance to the target vector
    if $Pawn/KinematicDriverMachine.target_position:
        $Items/Labels/DistanceLabel/Info.text = str(
            $Pawn.global_transform.origin.distance_to(
                $Pawn/KinematicDriverMachine.target_position
            )
        )
    else:
        $Items/Labels/DistanceLabel/Info.text = "NAN"
        
    # Set the State bar to the current state
    if test_state == TO_START:
        $Items/Labels/StateLabel/Info.text = "TO START!"
    elif test_state == IN_PROGRESS:
        $Items/Labels/StateLabel/Info.text = "IN PROGRESS!"
    elif test_state == SUCCESS_RETURN:
        $Items/Labels/StateLabel/Info.text = "SUCCESSFUL, RETURNING!"
    elif test_state == FAIL_RETURN:
        $Items/Labels/StateLabel/Info.text = "FAILURE, RETURNING!"
    else:
        $Items/Labels/StateLabel/Info.text = "INVALID STATE!"

# Utility function for telling the pawn to go somewhere, given a node
func set_pawn_target(target_node : Spatial):
    var position = target_node.global_transform.origin
    $Pawn.set_target_position(position)

# This is the real bread and butter of our tests - most of the path-following
# happens in this particular function, which gets called in response to the Pawn
# reaching it's target position.
func _on_Pawn_path_complete(pawn, position):
    # Different states, different responses - MATCH! THAT! STATE!
    match test_state:
        # If we were trying to reach the start...
        TO_START:
            # Then we have to be at the start - neat! So we just have to start
            # the test!          
            # Start by setting the target to the next one on the path
            set_pawn_target( current_test_path.pop_front() )
            # The test is now in progress!
            test_state = IN_PROGRESS
            # Start the test timer - if we don't finish before this thing, then
            # the test fails!
            $Timer.start()
            
        # If we were doing the test...
        IN_PROGRESS:
            # Then we have to be at our end point, meaning we succeeded - all
            # right!
            # print("Test Success!")
            # Start by setting the target to the next one on the path
            set_pawn_target( current_test_path.pop_front() )
            # The test is now a success! We just have to return...
            test_state = SUCCESS_RETURN
            # Stop the time so we don't get a false failure
            $Timer.stop()
            
        # If we were returning from a success...
        SUCCESS_RETURN:
            # If we still have nodes, then we're not done returning yet
            if not current_test_path.empty():
                set_pawn_target( current_test_path.pop_front() )
            # Otherwise, we must be done returning. Set up the next test
            else:
                #print("Moving to start! (Post-success)")
                test_index = (test_index + 1) % all_tests.size()
                current_test_path = all_tests[test_index].duplicate()
                set_pawn_target( current_test_path.pop_front() )
                test_state = TO_START
                            
        # If we were returning from a failure...
        FAIL_RETURN:
            # Then we've returned to where we started. Now we need to get the
            # next test.
            # print("Moving to start! (Post-failure)")
            test_index = (test_index + 1) % all_tests.size()
            current_test_path = all_tests[test_index].duplicate()
            set_pawn_target( current_test_path.pop_front() )
            test_state = TO_START

func _on_Timer_timeout():
    # Looks like we failed - set to failure state and go back to the start
    # print("Test Failed!")
    set_pawn_target( all_tests[test_index][0] )
    test_state = FAIL_RETURN
    # Also, just in case, make sure we stop the timer
    $Timer.stop()


func _on_Button_pressed():
    if default_camera:
        $WorldCamera.current = false
        $Pawn/PawnCamera.current = true
        default_camera = false
    else:
        $WorldCamera.current = true
        $Pawn/PawnCamera.current = false
        default_camera = true
