extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# UnitPawns make use of directions. A LOT. So, here's an enum that we can use to
# easily refer to cardinal directions.
enum {
    # The Primary Cardinals
    EAST = 0, NORTH = 2, WEST = 4, SOUTH = 6,
    # The Intercardinals
    NOR_EAST = 1, NOR_WEST = 3, SOU_WEST = 5, SOU_EAST = 7
}

# What's our tolerance for meeting our goal
const GOAL_TOLERANCE = 0.1

# How fast do the UnitPawns move, horizontally? Units/second
const HORIZ_SPEED = 10

# How fast do the UnitPawns fall, when they do fall?
const FALL_SPEED = 9.8

# To test that we're on the ground, we need to do a collision-cast downward -
# what's the magnitude of that downward cast? In game-units
const FALL_CAST_LENGTH = 9.8

# We can only really measure the position of the UnitPawn from the center of the
# node. However, our destinations are always on the floor. So, we need a
# constant to calculate our distance to the floor. Even accounting for our
# initial y-transform, .001396 was the OBSERVED remainder. This was also
# observed as the typical distance between the floor an object is sitting on and
# it's downward raycast-collision. Not sure where that value is from or why that
# value is what it is, but it is. 
const FLOOR_DISTANCE_ADD = .001396

# Sometimes we run into a wall and we need to step up to the top of that wall -
# what is the maximum height that we'll be willing to step up?
const MAX_STEP_UP_HEIGHT = .25

# Everytime we cast downward, we'll usually get a collision value back - even if
# we're actually on what we'd consider the floor! So, to rectify that, we're
# only going to move downwards if the distance moved MEETS OR EXCEEDS this
# value. 
const MINIMUM_FALL_HEIGHT = .002

# What's the minimum and maximum angle for a slope that this UnitPawn can slide
# up?
const SLOPE_MIN_ANGLE = 0
const SLOPE_MAX_ANGLE = 45

# These values used to be constants, but needed to dynamically respond to
# changes in the how the UnitPawn is sized (and stuff like that).
# What's the total height of this UnitPawn?
var _TOTAL_HEIGHT = NAN
# How far is the floor from the origin of the UnitPawn?
var _FLOOR_DISTANCE = NAN

# What is our target position - where are we trying to go?
var target_position = null setget settarget_position

# What is this pawn's unit? Who's feeding it the orders? Who is determining
# where it should be to be "in formation"?
var control_unit = null

# What is this pawn's index in it's unit? The index is used to calculate where
# the pawn should come to rest relative to the Unit's "center".
var pawn_index = -1

# The current movement vector. This is set during movement (see _physics_process).
# It is purely for reading the current movement status (since kinematic bodies
# don't really report this.)
var _combined_velocity = Vector3.ZERO

# Likewise, we may need a quick way to refer our current movement direction
# (horizontally, at least) without having to derive from the _current_velocity.
# We'll store that value here. 
var _current_horiz_direction = SOUTH
# Are we currently moving?
var is_moving = false
# Are we currently on the floor?
var on_floor = true

# Signal issued when this pawn dies. Arguments passed include the specific Pawn,
# the assigned Unit, and the Unit Index.
signal pawn_died(pawn, unit, unit_index)

# Signal issued when this pawn reaches it's target. Includes the specific Pawn
# and the pawn's current position (which will be effectively the same as the
# previous target).
signal target_reached(pawn, position)

# Called when the node enters the scene tree for the first time.
func _ready():
    update_move_values()

# Certain variables are key to how we handle movement, but are derived from
# values that [we can't access / don't exist] before the UnitPawn spawns in.
# Ergo, we'll call this function to create those values.
func update_move_values():
    # Extract the shape from the
    var current_shape = $CollisionCapsule.shape
    
    # Floor distance is intial-local y offset, plus the additive we identified
    _FLOOR_DISTANCE = 0.85228# (current_shape.height / 2) + FLOOR_DISTANCE_ADD
    
    # Total Height is the extent of the shape, doubled
    _TOTAL_HEIGHT = current_shape.height
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    set_sprite_from_vector(_combined_velocity)

func _physics_process(delta):
    # What's the vector for our new movement? Each value is a measure in
    # units/sec
    var new_move = Vector3.ZERO
    # Did we get a collision result from our most recent move attempt?
    var collision = null
    # What's our position, measured from the MIDDLE of the BASE of the UnitPawn?
    var floor_pos = self.global_transform.origin - Vector3(0, _FLOOR_DISTANCE, 0)   
    # Get the space state so we can raycast query
    var space_state = get_world().direct_space_state
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 1: Check if we're on the ground / if we need to fall
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # If we aren't on the ground, we need to move down!
    # Do a fake move downward just to determine if we're on the ground. We do
    # this instead of a raycast because this counts the whole collision model.
    collision = move_and_collide(
        Vector3(0, -FALL_CAST_LENGTH, 0), true, true, true
    )
    # If we didn't collide, then we're not on the floor. MOVE DOWN!
    if not collision:
        new_move.y = -FALL_SPEED
        on_floor = false
    # Alternatively, we did actually find the floor; in that case, we need to
    # move down if the floor is MEETS OR EXCEEDS our minimum fall height
    elif collision.travel.length() >= MINIMUM_FALL_HEIGHT:
        new_move.y = -FALL_SPEED
        on_floor = false
    else:
        on_floor = true
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 2: If we have a target position, then move towards that target
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # If we have a target, we need to move towards the target.
    if self.target_position:
        # How far are we from our target position?
        var distance_to = target_position - floor_pos
        # We really only care about the X and Z, so we're gonna re-package them
        # into a Vector2.
        var normal_dist = Vector2(distance_to.x, distance_to.z).normalized()
        
        # Now for something a bit more wacky - we don't want to overshoot our
        # target, so we'll fine-tune our values
        var projected_travel = normal_dist.length() * HORIZ_SPEED * delta
        
        # If we're projected to move straight past the goal...
        if projected_travel > distance_to.length():
            # In that case, we'll use the horizontal speed and delta to
            normal_dist.x = distance_to.x / (HORIZ_SPEED * delta)
            normal_dist.y = distance_to.z / (HORIZ_SPEED * delta)
            
        # Finally, set our final x & z values
        new_move.x = normal_dist.x * HORIZ_SPEED
        new_move.z = normal_dist.y * HORIZ_SPEED
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 3: Do the move!
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if new_move != Vector3.ZERO:
        #collision = move_and_slide(new_move)
        # Now that we've built a move vector - MOVE!
        collision = move_and_collide(new_move * delta)
        
        # If we collided with something, and we still have a ways to go...
        if collision and collision.remainder.length() != 0:
            # Get the remaining movement
            var next_movement = collision.remainder

            # To determine what type of surface this is, we need to calculate
            # the angle from the origin - this is the best tool we have for
            # determining what kind of slope we have
            var normal_at_level = Vector3.ZERO
            normal_at_level.x = collision.normal.x
            normal_at_level.z = collision.normal.z
            
            # Calculate the angle
            var normal_angle = normal_at_level.angle_to(collision.normal)

            # Test if the angle is in range
            var in_angle = SLOPE_MIN_ANGLE <= rad2deg(normal_angle)
            in_angle = in_angle and rad2deg(normal_angle) <= SLOPE_MAX_ANGLE

            # If we're in the golden zone, or we can't step up, then we gotta
            # slide!
            if in_angle:
                # Slide along the normal
                next_movement = next_movement.slide( collision.normal )
                # Normalize it
                next_movement = next_movement.normalized()
                # Scale it to the length of the previous remaining movement
                next_movement = next_movement * collision.remainder.length()
            
                # Now we need to slide - divide out our delta from the remainder
                # and then slide on up
                move_and_collide(next_movement)
                # Finally, the next movement is technically our "new move"
                new_move = next_movement
                
            # Otherwise, step up
            else:
                pass
        
        # Update our "watch" stats
        self.is_moving = true
        _combined_velocity = new_move
    else:
        # Update our "watch" stats
        self.is_moving = false
        _combined_velocity = new_move
        
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Step 4: Reset target position if necessary
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Update the floor position
    floor_pos = self.global_transform.origin - Vector3(0, _FLOOR_DISTANCE, 0)
    # If we have a target position...
    if target_position:
        # ...AND we're close enough to that target position...
        if (target_position - floor_pos).length() <= GOAL_TOLERANCE:
            # ...then we're done here! Save the target position
            var pos_save = target_position
            # Clear the target
            target_position = null
            # Now emit the "target reached" signal using the position we saved.
            # It's important we do it this way, since anything receiving the
            # signal could change the variable out from under us.
            emit_signal("target_reached", self, target_position)

# Registers this UnitPawn to a Unit node. Assigns the provided index to this
# UnitPawn
func register_to_unit(unit_node, unit_index):
    # Assign the controlling unit
    control_unit = unit_node
    # Assign the unit index
    pawn_index = unit_index
    # Register the move_order_callback with our current object (so we can get
    # move orders hand delivered)
    control_unit.connect("move_ordered", self, "_on_Unit_move_ordered")
    # Register the pawn_died signal with our current object (so we can get
    # move orders hand delivered)
    self.connect("pawn_died", unit_node, "_on_UnitPawn_pawn_died")

# Sets this UnitPawn to not collide with all of the nodes in the provided list.
# Intended for making sure a UnitPawn doesn't collide with the other UnitPawns
# in it's fellow unit.
func no_collide_with_list(node_list):
    # For each node in the provided node list...
    for node in node_list:
        # If the current node in our list is NOT this UnitPawn...
        if node != self:
            # Then don't collide this UnitPawn with this other node
            self.add_collision_exception_with( node )

# Sets the UnitPawn's VisualSprite, given a movement vector. We treat the vector
# like a projection from the origin - in that form it gives us a direction (and
# a magnitude but we don't care about that). Using that, we can determine which
# way the VisualSprite SHOULD be looking and set it from there.
func set_sprite_from_vector(move_vector: Vector3):
    # We need to update the sprite to match the UnitPawn's movement direction.
    # Direction is treated as a compass, relative to the camera. So away from
    # the camera is north, towards is south, right and left become east and
    # west, etc...
    is_moving = (move_vector.x != 0) or (move_vector.z != 0)
    
    # If this vector is moving horizontally...
    if is_moving:
        # Move the X and Z fields into a Vector2 so we can easily calculate the
        # sprite's current angular direction. Note that the Z is actually inverted;
        # This makes our angles operate on a CCW turn (like a unit circle)
        var move_angle = Vector2(move_vector.x, -move_vector.z).angle()
        # Angles are, by default, in radian form. Good for computers, bad for
        # humans. Since we're just going to check values, and not do any
        # calculations or manipulations, let's just convert it to degrees!
        move_angle = rad2deg(move_angle)
        # Both of our sprites start off at 45 degrees on y - so to calculate the
        # true movement angle, we need rotate BACK 45 degrees.
        move_angle -= 45
        # Godot doesn't do angles as 0 to 360 degress, it does -180 to 180. This
        # makes case-checks harder, so let's just shift things forward by 360 if
        # we're negative.
        if move_angle < 0:
            move_angle += 360
        
        # Right! Now we've got an appropriate angle - we just need to set the
        # zones. Each eigth-cardinal is allotted 45 degrees, centered around 
        # increments of 45 - i.e. EAST is at 0, NOR_EAST at 45, NORTH at 90. The
        # periphery of the zone extends +- 45/2, or 22.5. Ergo, our zone checks
        # are values coming from 22.5 + (45 * i)
        if move_angle < 22.5:
            _current_horiz_direction = EAST
        elif move_angle < 67.5:
            _current_horiz_direction = NOR_EAST
        elif move_angle < 112.5:
            _current_horiz_direction = NORTH
        elif move_angle < 157.5:
            _current_horiz_direction = NOR_WEST
        elif move_angle < 202.5:
            _current_horiz_direction = WEST
        elif move_angle < 247.5:
            _current_horiz_direction = SOU_WEST
        elif move_angle < 292.5:
            _current_horiz_direction = SOUTH
        elif move_angle < 337.5:
            _current_horiz_direction = SOU_EAST
        else:
            _current_horiz_direction = EAST
            
    # Update the sprite state - regardless of whether 
    _update_sprite_from_direction_state(is_moving)
    pass

func _update_sprite_from_direction_state(moving: bool):
        var anim_string
        # Then we need to set the sprite to idle; match the current direction:
        match _current_horiz_direction:
            # Unfortunately, we don't have any "east" facing animations, so we
            # have to just flip the west-facing ones
            SOU_EAST:
                anim_string = "southwest"
                $VisualSprite.flip_h = true
                pass
            EAST:
                anim_string = "west"
                $VisualSprite.flip_h = true
            NOR_EAST:
                anim_string = "northwest"
                $VisualSprite.flip_h = true
            # End East Block
            NORTH:
                anim_string = "north"
                $VisualSprite.flip_h = false
            NOR_WEST:
                anim_string = "northwest"
                $VisualSprite.flip_h = false
            WEST:
                anim_string = "west"
                $VisualSprite.flip_h = false
            SOU_WEST:
                anim_string = "southwest"
                $VisualSprite.flip_h = false
            SOUTH:
                anim_string = "south"
                $VisualSprite.flip_h = false
                
        if is_moving:
            anim_string += "_move"
        else:
            anim_string += "_idle"
        $VisualSprite.animation = anim_string

func _on_Unit_move_ordered(unit_target):
    # Calculate the individual position based on the unit_position, and set the
    # target position using that calculated value
    var new_target = self.control_unit.get_pawn_index_pos(self.pawn_index)
    new_target.x += unit_target.x
    new_target.z += unit_target.z
    settarget_position(new_target)

# Set the target position for this UnitPawn. This exists so that we have a
# standardized way of setting the target position. Currently we only need to do
# this one line - makes this function a bit weird, but we can expand it if we
# need to.
func settarget_position(position):
    target_position = position
