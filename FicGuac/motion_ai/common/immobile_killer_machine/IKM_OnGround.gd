tool
extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Need to use get_node instead of the $ notation because
# the $ doesn't accept ..
onready var MR = get_node("../..")

const FALL_TIMER_NAME = "FallDelay"
var fall_timer_active = false

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Extended State Machine Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_enter(var arg) -> void:
    # Set the state key. Might seem weird since we have substates, but those
    # will overwrite as appropriate.
    MR.state_key = "OnGround"
    # Assert the timer is inactive
    fall_timer_active = false
    
func _on_update(delta) -> void:
    # Get our KinematicCore
    var KC = MR.kinematic_core_node
    # Did we get a collision result from our most recent move attempt?
    var collision = null
    
    # Are we on the floor? If not, we're gonna have to do some processing at the
    # end of this.
    var on_floor = false
    
    # Do a fake move downward just to determine if we're on the ground. How we
    # do that changes depending on whether or not we have a floor raycast
    collision = target.move_and_collide(
        # Move vector (straight down). We need to at least check our fall speed,
        # our minimum fall height, and our float height.
        Vector3.DOWN * (KC.fall_speed + KC.MINIMUM_FALL_HEIGHT + KC.float_height),
        true, # Infinite intertia
        true, # Exclude Raycast Shapes
        true # Test Only - just report IF a collisions happens, don't
             # actually move at all!
    )
    
    # Now that we've queried the world, we have several possibilities we need
    # to check out. First, what if we didn't get a collision at all?
    if not collision:
        on_floor = false
    # Alternatively, we actually managed to find the floor - but what if it's
    # outside our minimum fall height (and our floating offset)?
    elif collision.travel.length() >= KC.MINIMUM_FALL_HEIGHT + KC.float_height:
        on_floor = false
    # Otherwise
    else:
        # Okay, so we're definitely on what we would consider the floor now.
        on_floor = true
        # Calculate the normal angle of whatever we hit - effectively, what's
        # the angle of the slope we just collided with? Credit to Jeremy Bullock
        # on YouTube for this monster (he seems to have deleted his channel)
        var normal_angle = rad2deg(acos(collision.normal.dot(Vector3.UP)))
        # If the normal angle is GREATER than the max possible slope that we can
        # climb, then we're on slippery slope and should be sliding down!
        if normal_angle > KC.max_slope_degrees:
            # Ergo, we ain't on the floor at all!
            on_floor = false
        # Otherwise, we're on stable grounf. So, what if we're lower than the
        # height we're supposed to be floating at?
        elif collision.travel.length() < KC.float_height:
            # In that case, move up by however much we're down by
            target.move_and_collide(
                Vector3.UP * (KC.float_height - collision.travel.length())
            )
    
    # If we're on the floor
    if on_floor:
        # ... oh! Huh. Guess we don't need that fall timer. Remove it if we have
        # it.
        if fall_timer_active:
            self.del_timer(FALL_TIMER_NAME)
            fall_timer_active = false
    # Otherwise...
    else:
        # We're not on the floor. First thing we should do is move downwards.
        collision = target.move_and_collide(Vector3.DOWN * (KC.fall_speed * delta))
        
        # If we collided with something, and we still have a ways to go...
        if collision and collision.remainder.length() != 0:
            # Get the remaining movement
            var next_movement = collision.remainder

            # Slide along the normal
            next_movement = next_movement.slide( collision.normal )
            # Normalize it
            next_movement = next_movement.normalized()
            # Scale it to the length of the previous remaining movement
            next_movement = next_movement * collision.remainder.length()
            # Now move and colide along that scaled angle
            target.move_and_collide(next_movement)
            
        # If we don't have a fall timer ongoing, start one
        if not fall_timer_active:
            self.add_timer(FALL_TIMER_NAME, KC.fall_state_delay_time)
            fall_timer_active = true

func _on_timeout(name) -> void:
    # If the timer ends, then items time to start falling!
    match name:
        FALL_TIMER_NAME:
            change_state("Falling")
