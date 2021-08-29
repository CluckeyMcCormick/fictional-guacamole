tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("..")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    MR.state_key = "Falling"

func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Did we get a collision result from our most recent move attempt?
    var collision
    
    # Do the move!
    collision = target.move_and_collide(Vector3.DOWN * KC.fall_speed * delta)
    
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
        target.move_and_collide(rem_move)

func _after_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Do a fake move downward just to determine if we're on the ground.
    var collision = target.move_and_collide(
        # Move vector (straight down). We need to at least check our fall speed,
        # our minimum fall height, and our float height.
        Vector3(0, -KC.fall_speed - KC.MINIMUM_FALL_HEIGHT - KC.float_height, 0),
        true, # Infinite intertia
        true, # Exclude Raycast Shapes
        true # Test Only - just report IF a collisions happens, don't
             # actually move at all!
    )

    # Let's assume we're moving downward. Add that to the projected movement.
    MR._projected_movement += Vector3(0, -KC.fall_speed, 0)
    
    # Now that we've queried the world, we have several possibilities we need
    # to check out. First, what if we didn't get a collision at all?
    if not collision:
        # Then just back out. Nothing to do here.
        return
    
    # Alternatively, we actually managed to find the floor. If it's in the right
    # range for our floating...
    elif collision.travel.length() <= KC.MINIMUM_FALL_HEIGHT + KC.float_height:
        # Then we're not falling anymore, extract out the projected movement we
        # just added.
        MR._projected_movement -= Vector3(0, -KC.fall_speed, 0)
        # Transition to the Idle State, we'll decide what to do from there.
        change_state("Idle")
