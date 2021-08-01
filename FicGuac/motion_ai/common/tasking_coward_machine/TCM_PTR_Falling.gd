tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

# We keep several variables pertinent to the move state in the MoveRegion state,
# so grab that real quick
onready var PTR = get_node("..")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # If our machine root hasn't been configured (it happens unfortunately
    # often), then force the configuration
    if not MR._machine_configured:
        MR._force_configure()

    # Set the physics travel key
    MR.physics_travel_key = "Falling"

    # Set the movement hint
    MR.movement_hint = "fall"

func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Get our current integrating body
    var itgr_body = MR.integrating_body_node
    # Did we get a collision result from our most recent move attempt?
    var collision
    
    # Do the move!
    collision = itgr_body.move_and_collide(Vector3.DOWN * KC.fall_speed * delta)
    
    # We're definitely falling!
    MR._curr_orient.y = -KC.fall_speed
    
    # If we collided with something, and we still have a ways to go...
    if collision and collision.remainder.length() != 0:
        # Get the remaining movement
        var rem_move = collision.remainder
        # Slide along the normal
        rem_move = rem_move.slide( collision.normal )
        # Normalize it
        rem_move = rem_move.normalized()
        # Scale it to the length of the previous remaining movement
        rem_move = rem_move * collision.remainder.length()
        # Now move and colide along that scaled angle
        itgr_body.move_and_collide(rem_move)

func _after_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Get our current integrating body
    var itgr_body = MR.integrating_body_node
    # Do a fake move downward just to determine if we're on the ground.
    var collision = itgr_body.move_and_collide(
        # Move vector (straight down). We need to at least check our fall speed,
        # our minimum fall height, and our float height.
        Vector3(0, -KC.fall_speed - KC.MINIMUM_FALL_HEIGHT - KC.float_height, 0),
        true, # Infinite intertia
        true, # Exclude Raycast Shapes
        true # Test Only - just report IF a collisions happens, don't
             # actually move at all!
    )
    
    # Now that we've queried the world, we have several possibilities we need
    # to check out. First, what if we didn't get a collision at all?
    if not collision:
        # Then just back out. Nothing to do here.
        return
    
    # Alternatively, we actually managed to find the floor. If it's in the right
    # range for our floating...
    elif collision.travel.length() <= KC.MINIMUM_FALL_HEIGHT + KC.float_height:
        # Then we're not falling anymore. Transition to the Idle State, we'll
        # decide what to do from there.
        change_state("Idle")
