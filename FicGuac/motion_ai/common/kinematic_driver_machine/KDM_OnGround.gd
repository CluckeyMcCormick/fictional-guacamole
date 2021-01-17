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
func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Did we get a collision result from our most recent move attempt?
    var collision = null
    
    # Since we're currently on the ground, we're not going anywhere. Probably.
    MR._curr_orient.y = 0
    
    # Do a fake move downward just to determine if we're on the ground.
    collision = target.move_and_collide(
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
        # Then we're not on the floor. Start falling!
        change_state("Falling")
    # Alternatively, we actually managed to find the floor - but what if it's
    # outside our minimum fall height (and our floating offset)?
    elif collision.travel.length() > KC.MINIMUM_FALL_HEIGHT + KC.float_height:
        # Then we're not on the floor. Start falling!
        change_state("Falling")
    # Otherwise
    else:
        # Okay, so we're definitely on what we would consider the floor now.
        # Calculate our normal angle - effectively, what's the angle of the
        # slope we just collided with? Credit to Jeremy Bullock on YouTube for
        # this monster (he seems to have deleted his channel)
        var normal_angle = rad2deg(acos(collision.normal.dot(Vector3.UP)))
        # If the normal angle is GREATER than the max possible slope that we can
        # climb, then we're on slippery slope and should be sliding down!
        if normal_angle > KC.max_slope_degrees:
            # Then we're not on the floor. Start falling!
            change_state("Falling")
        # Otherwise, we're on stable ground. So, what if we're lower than the
        # height we're supposed to be floating at?
        elif collision.travel.length() < KC.float_height:
            # In that case, move up by however much we're down by
            target.move_and_collide(
                Vector3(0, KC.float_height - collision.travel.length(), 0)
            )
