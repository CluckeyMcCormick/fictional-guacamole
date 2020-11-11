extends Spatial

# Each driver needs a node to move around - what node will this drive move?
export(NodePath) var drive_body
# We resolve the node path into this variable.
var drive_body_node

# How fast does our drive node move, horizontally? Units/second
export(float) var move_speed = 10
# How fast does the drive node fall, when it does fall?
export(float) var fall_speed = 9.8
# What's our tolerance for meeting our goal?
export(float) var goal_toreance = 0.1
# How much do we float by?
export(float) var float_height = 0
# Sometimes, we'll encounter a slope. There has to be a demarcating line where a
# slope acts more like a wall than a true slope, so that whatever we're driving
# doesn't climb a stairway to heaven. What's the maximum angle for a slope we
# can climb, measured in degrees?
export(float) var max_slope_degrees = 45

# If we're not using a raycast to determine if we're on the ground, then we'll
# test by simulating a downward move. Everytime we do that, we'll usually get a
# collision value back - even if we're actually on what we'd consider the floor!
# So, to rectify that, we're only going to move downwards if the distance moved
# MEETS OR EXCEEDS this value.  
const MINIMUM_FALL_HEIGHT = .002

# Signal issued when this driver reaches it's target. Sends back the Vector3
# position value that was just reached.
signal target_reached(position)

# Signal issued when this driver requires a position update. Determining our
# current position is the responsibility of whatever node we are driving - there
# are just too many possible variations of how we would want to determine our
# "current" point. Using a signal to request a status update isn't exactly
# kosher but I just don't see a better way.
signal request_position(kinematic_driver, old_position)

# The current movement vector. This is set during movement (see
# _physics_process). It is purely for reading the current movement status (since
# kinematic bodies don't really report this.) Really meant only for reading,
# not sure what the effects of setting this outside of the script would be.
var _combined_velocity = Vector3.ZERO

# What is our target position - where are we trying to go?
var target_position = null

# What is the current position of our drive target, adjuted to align with our
# target position? This is the value that should set when the request_position
# signal is sent out.
var adj_position = Vector3.ZERO setget set_adj_position

# Are we currently moving?
var _is_moving = false
# Are we currently on the floor?
var _on_floor = true

func set_adj_position(new_position):
    adj_position = new_position
    assert(adj_position != null)

# Called when the node enters the scene tree for the first time.
func _ready():
    # Get the drive target node
    drive_body_node = get_node(drive_body)

func _physics_process(delta):
    # What's the vector for our new movement? Each value is a measure in
    # units/sec
    var new_move = Vector3.ZERO
    # At several points, we construct
    var normal_angle = 0
    # Did we get a collision result from our most recent move attempt?
    var collision = null
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 1: Check if we're on the ground / if we need to fall
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Do a fake move downward just to determine if we're on the ground. How we
    # do that changes depending on whether or not we have a floor raycast
    collision = drive_body_node.move_and_collide(
        # Move vector (straight down). We need to at least check our fall speed,
        # our minimum fall height, and our float height.
        Vector3(0, -fall_speed - MINIMUM_FALL_HEIGHT - float_height, 0),
        true, # Infinite intertia
        true, # Exclude Raycast Shapes
        true # Test Only - just report IF a collisions happens, don't
                # actually move at all!
    )
    
    # Now that we've queried the world, we have several possibilities we need
    # to check out. First, what if we didn't get a collision at all?
    if not collision:
        _on_floor = false
    # Alternatively, we actually managed to find the floor - but what if it's
    # outside our minimum fall height (and our floating offset)?
    elif collision.travel.length() >= MINIMUM_FALL_HEIGHT + float_height:
        _on_floor = false
    # Otherwise
    else:
        # Okay, so we're definitely on what we would consider the floor now.
        _on_floor = true
        # Calculate our normal angle - effectively, what's the angle of the
        # slope we just collided with? Credit to Jeremy Bullock for this monster
        normal_angle = rad2deg(acos(collision.normal.dot(Vector3(0,1,0))))
        # If the normal angle is GREATER than the max possible slope that we can
        # climb, then we're on slippery slope and should be sliding down!
        if normal_angle > max_slope_degrees:
            # Ergo, we ain't on the floor at all!
            _on_floor = false
        # Otherwise, we're on stable grounf. So, what if we're lower than the
        # height we're supposed to be floating at?
        elif collision.travel.length() < float_height:
            # In that case, move up by however much we're down by
            drive_body_node.move_and_collide(
                Vector3(0, float_height - collision.travel.length(), 0)
            )
        
    # If we're NOT on the floor, then we need to move downward!
    if not self._on_floor:
        new_move.y = -fall_speed
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 2: If we have a target position, then move towards that target
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # If we have a target, we need to move towards the target.
    if self.target_position:
        # We need our adj_position value updated.
        emit_signal("request_position", self, adj_position)
        
        # How far are we from our target position?
        var distance_to = target_position - adj_position
        # We really only care about the X and Z, so we're gonna re-package them
        # into a Vector2. Normalizing reduces the Vector such that we can easily
        # scale it - it's basically just the direction now.
        var normal_dist = Vector2(distance_to.x, distance_to.z).normalized()
        
        # Now for something a bit more wacky - we don't want to overshoot our
        # target, so we'll fine-tune our values.
        # First, let's calculate how far we'll move on x and z in total.
        var projected_travel = normal_dist.length() * move_speed * delta
        
        # If we're projected to move straight past the goal...
        if projected_travel > distance_to.length():
            # In that case, we only want to move an exact amount. Since our
            # movement is always multiplied by (move_speed * delta), we can
            # calculate the exact values we'll need for normal_dist by dividing
            # out that factor from the remaining distance.
            normal_dist.x = distance_to.x / (move_speed * delta)
            normal_dist.y = distance_to.z / (move_speed * delta)
            
        # Finally, set our final x & z values
        new_move.x = normal_dist.x * move_speed
        new_move.z = normal_dist.y * move_speed
    
        # If we're visible, the let's update our debug arrow using the x/z angle
        if self.visible:
            # Set the rotation using the x and z. Invert X because it's
            # essentially Y in this situation but is opposite in direction to
            # how Y is normally oriented.
            $Arrow.rotation.y = Vector2(-distance_to.x, distance_to.z).angle()
            # The arrow is 90 degrees (PI/2) out-of-phase with where it should
            # be (which is because the arrow doesn't start point out at 0
            # degrees). Adjust it!
            $Arrow.rotation.y += PI / 2
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 3: Do the move!
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if new_move != Vector3.ZERO:
        
        collision = drive_body_node.move_and_collide(new_move * delta)

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
            drive_body_node.move_and_collide(next_movement)
            # Finally, the next movement is technically our "new move"
            new_move = next_movement

        # Update our "watch" stats
        _is_moving = true
        _combined_velocity = new_move
    else:
        # Update our "watch" stats
        _is_moving= false
        _combined_velocity = new_move
        
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 4: Reset target position if necessary
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # If we have a target position...
    if target_position:
        # Update the adjusted position
        emit_signal("request_position", self, adj_position)
        # ...AND we're close enough to that target position...
        if (target_position - adj_position).length() <= goal_toreance:
            # ...then we're done here! Save the target position
            var pos_save = target_position
            # Clear the target
            target_position = null
            # Now emit the "target reached" signal using the position we saved.
            # It's important we do it this way, since anything receiving the
            # signal could change the variable out from under us.
            emit_signal("target_reached", pos_save)