extends KinematicBody

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# UnitPawns make use of directions. A LOT. So, here's an enum that we can use to
# easily refer to cardinal directions.
enum {
    # The Primary Cardinals
    EAST = 0, NORTH = 2, WEST = 4, SOUTH = 6,
    # The Intercardinals
    NOR_EAST = 1, NOR_WEST = 3, SOU_WEST = 5, SOU_EAST = 7
}

# We can only really measure the position of the UnitPawn from the center of the
# node. However, our destinations are always on the floor. So, we need a
# constant to calculate our distance to the floor. This value, .747353 was the
# OBSERVED value.
const FLOOR_DISTANCE_ADD = .747353

# What is this pawn's unit? Who's feeding it the orders? Who is determining
# where it should be to be "in formation"?
var control_unit = null

# What is this pawn's index in it's unit? The index is used to calculate where
# the pawn should come to rest relative to the Unit's "center".
var pawn_index = -1

# Likewise, we may need a quick way to refer our current movement direction
# (horizontally, at least) without having to derive from the _current_velocity.
# We'll store that value here. 
var _current_horiz_direction = SOUTH

# Signal issued when this pawn dies. Arguments passed include the specific Pawn,
# the assigned Unit, and the Unit Index.
signal pawn_died(pawn, unit, unit_index)

# Signal issued when this pawn reaches it's target. Includes the specific Pawn
# and the pawn's current position (which will be effectively the same as the
# previous target).
signal target_reached(pawn, position)

# This is the destination, which we update when set_destination is called
var destination setget set_destination

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Reassess our current sprite and update if necessary
    set_sprite_from_vector()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the destination position for this UnitPawn, then pass that value down to
# the KinematicDrive
func set_destination(position):
    # Shift the floor position so it will align with this node's origin. By
    # making the specific to each sub/scene, we can ensure modularity
    var adjusted_pos = position + Vector3(0, FLOOR_DISTANCE_ADD, 0)
    $KinematicDriver.target_position = adjusted_pos
    destination = adjusted_pos

func _on_KinematicDriver_target_reached(position):
    # Save the destination so we can emit it after destroying it
    var sav_dest = destination
    # We no longer have a destination!
    destination = null
    # Send the signal up the line - echo it, in other words. Use sav_dest
    # because the position value we got handed is the adjusted value
    emit_signal("target_reached", self, sav_dest)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Pawn specific functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Sets the UnitPawn's VisualSprite, given a movement vector. We treat the vector
# like a projection from the origin - in that form it gives us a direction (and
# a magnitude but we don't care about that). Using that, we can determine which
# way the VisualSprite SHOULD be looking and set it from there.
func set_sprite_from_vector():
    # We need to update the sprite to match the UnitPawn's movement direction.
    # Direction is treated as a compass, relative to the camera. So away from
    # the camera is north, towards is south, right and left become east and
    # west, etc...
    
    # Quick, dereference/copy our driver's move stat. We do this to help compact
    # the code.
    var move_vector = $KinematicDriver._combined_velocity
    
    # If we are moving...
    if $KinematicDriver._is_moving:
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
            
    # Update the sprite state
    _update_sprite_from_direction_state()

func _update_sprite_from_direction_state():
        var anim_string
        # Then we need to set the sprite to idle; match the current direction:
        match _current_horiz_direction:
            # Unfortunately, we don't have any "east" facing animations, so we
            # have to just flip the west-facing ones
            SOU_EAST:
                anim_string = "southwest"
                $VisualSprite.flip_h = true
            EAST:
                anim_string = "west"
                $VisualSprite.flip_h = true
            NOR_EAST:
                anim_string = "northwest"
                $VisualSprite.flip_h = true
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
                
        if $KinematicDriver._is_moving:
            anim_string += "_move"
        else:
            anim_string += "_idle"
        $VisualSprite.animation = anim_string

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
    set_destination(new_target)
