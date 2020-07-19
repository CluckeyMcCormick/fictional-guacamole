extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# UnitPawns make use of directions. A LOT. So, here's an enum that we can use to
# easily refer to cardinal directions.
enum {
    # The Primary Cardinals
    EAST = 0, NORTH = 2, WEST = 4, SOUTH = 6,
    # The Intercardinals (currently unused)
    NOR_EAST = 1, NOR_WEST = 3, SOU_WEST = 5, SOU_EAST = 7
}

# What's our tolerance for meeting our goal
const GOAL_TOLERANCE = 0.01
# What's our tolerance for straying/overshooting on our path to the goal
const PATHING_TOLERANCE = 0.001
# How tall is this UnitPawn? Might not seem like it but this can actually be a
# pretty big deal - if this is set incorrectly UnitPawns might measure their
# distance-to-target wrong!
const HEIGHT = 0.10

# What's the minimum horizontal speed our units will move at? (Excluding when
# they come to a full stop). Units/second
const MIN_HORIZ_SPEED = 0.5

# What's the maximum horizontal speed our units will move at? Units/second
const MAX_HORIZ_SPEED = 1.5

# What is our target position - where are we trying to go?
var _target_position = null

# What is this pawn's unit? Who's feeding it the orders? Who is determining
# where it should be to be "in formation"?
var control_unit = null

# What is this pawn's index in it's unit? The index is used to calculate where
# the pawn should come to rest relative to the Unit's "center".
var pawn_index = -1

# The current movement vector. This is set during movement (see _physics_process).
# It is purely for reading the current movement status (since kinematic bodies
# don't really report this.)
var _current_velocity = Vector3.ZERO
# Likewise, we may need a quick way to refer our current movement direction
# (horizontally, at least) without having to derive from the _current_velocity.
# We'll store that value here. 
var _current_horiz_direction = SOUTH
# Are we currently moving?
var is_moving = false

# Signal issued when this pawn dies. Arguments passed include the specific Pawn,
# the assigned Unit, and the Unit Index.
signal pawn_died(pawn, unit, unit_index)

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    set_sprite_from_vector(_current_velocity)
    pass

# 
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

func _physics_process(body_state):   
    var dirs = Vector3.ZERO
    
    if not self.is_on_floor():
        dirs.y = -0.05
    
    # Our current position (the global_transform) measures where the CENTER of
    # the UnitPawn is. However, we need to measure the position from the "feet".
    # To do that, we shift the origin down by half the height
    var floor_aligned_position = self.global_transform.origin
    floor_aligned_position.y -= HEIGHT / 2
    
    if _target_position != null and floor_aligned_position.distance_to(_target_position) > GOAL_TOLERANCE:
        # Calculate the distance from our current global position
        dirs = _target_position - floor_aligned_position

    dirs.x = clamp(abs(dirs.x), 0, MAX_HORIZ_SPEED) * sign(dirs.x)
    dirs.z = clamp(abs(dirs.z), 0, MAX_HORIZ_SPEED) * sign(dirs.z)

    # Set the current velocity
    _current_velocity = dirs
    # Only call move and slide if we HAVE to move; not sure what happens if
    # called with Vector Zero and it just FEELS safer
    if dirs != Vector3.ZERO:
        # Move (with snap on the Y-axis)
        self.move_and_slide_with_snap(dirs, Vector3(0, 1, 0)) 

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

func _on_Unit_move_ordered(unit_target):
    # Calculate the individual position based on the unit_position, and set the
    # target position using that calculated value
    var new_target = self.control_unit.get_pawn_index_pos(self.pawn_index)
    new_target.x += unit_target.x
    new_target.z += unit_target.z
    set_target_position(new_target)

# Set the target position for this UnitPawn. This exists so that we have a
# standardized way of setting the target position. Currently we only need to do
# this one line - makes this function a bit weird, but we can expand it if we
# need to.
func set_target_position(position):
    _target_position = position
