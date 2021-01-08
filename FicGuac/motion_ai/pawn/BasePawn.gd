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
# node. However, sometimes our destinations are always on the floor. So, we need
# a constant to calculate our distance to the floor. This value, .742972, was
# the OBSERVED value.
const FLOOR_DISTANCE = .742972#.747353

# Pos[ition] Algo[rithm]. In order to path, the Pawn needs to know where it is.
# There are different ways to calculate that. It's always centered, but the Z
# value (height) changes.
enum PosAlgo {
    FLOOR, # Z is at feet, the floor, whatever you want to call it
    NAVIGATION, # Pos is given by Navigation's get_closest_point function
    DETOUR_MESH # Pos is given via some trickery with DetourNavigation
}
# Which of the above position algorithms will we use? Note that Navigation and
# Detour will be broken unless the appropriate navigation node is provided.
export(PosAlgo) var position_algorithm = PosAlgo.FLOOR

# Each driver needs a node to move around - what node will this drive move?
export(NodePath) var navigation
# We resolve the node path into this variable.
var navigation_node

# Likewise, we may need a quick way to refer our current movement direction
# (horizontally, at least) without having to derive from the _current_velocity.
# We'll store that value here. 
var _current_horiz_direction = SOUTH

# Signal issued when this pawn reaches it's target. Includes the specific Pawn
# and the pawn's current position (which will be effectively the same as the
# previous target).
signal path_complete(pawn, position)

# This is the pawn's current path
var current_path setget set_path

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # Get the drive target node
    navigation_node = get_node(navigation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Reassess our current sprite and update if necessary
    set_sprite_from_vector()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_KinematicDriver_target_reached(position):
    # If we still have a path...
    if not current_path.empty():
        # The first/next position in the path is now our target position.
        $KinematicDriver.target_position = current_path.pop_front()
    else:
        # We're done following the path! Tell anyone who's listening
        emit_signal("path_complete", self, self.get_adjusted_position())

func _on_KinematicDriver_error_microposition_loop(target_position):
    # The KinematicDriver is trapped in a loop. Let's just fake a "target
    # reached" call and hope that fixes it, eh?
    # First, null out the target position
    $KinematicDriver.target_position = null
    # Now, emit the signal
    $KinematicDriver.emit_signal("target_reached")

# Get the "algorithmic" position. This is most often used for goal checking -
# i.e. seeing where we are from a world-mesh perspective
func get_adjusted_position():
    # Get our current position
    var curr_pos = self.global_transform.origin
    # What's our adjusted vector?
    var adjusted = Vector3.ZERO
    
    # How we calculate the "current position" is a configurable, so switch!
    match position_algorithm:
        PosAlgo.FLOOR:
            # Floor - just our current position, down to the feet. Neat!
            adjusted = curr_pos - Vector3(0, FLOOR_DISTANCE, 0)
        PosAlgo.NAVIGATION:
            # Navigation Mesh - we can just use get_closest_point. Easy!
            adjusted = navigation_node.get_closest_point(curr_pos)
        PosAlgo.DETOUR_MESH:
            # DetourNavigationMesh. This mesh doesn't actually give us a method
            # to easily access where we are on the mesh. So, we'll cheat. We'll
            # just path FROM our current position TO our current position. I
            # don't know the performance ramifications of this, but HOPEFULLY
            # its small. Or some update saves us from this madness...
            adjusted = navigation_node.find_path(curr_pos, curr_pos)
            # Unpack what we got back, since we want the first value of a
            # PoolVector3 array stored in a dict.
            adjusted = Array(adjusted["points"])[0]
    
    return adjusted

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the new path for the unit pawn
func set_path(new_path):
    # Set the path
    current_path = new_path
    # The first position in the path is now our target position.
    $KinematicDriver.target_position = current_path.pop_front()

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
        # sprite's current angular direction. Note that the Z is actually
        # inverted; This makes our angles operate on a CCW turn (like a unit
        # circle)
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
        var animation_string
        var direction_string
        # Then we need to set the sprite to idle; match the current direction:
        match _current_horiz_direction:
            SOU_EAST:
                direction_string = "southeast"
            EAST:
                direction_string = "east"
            NOR_EAST:
                direction_string = "northeast"
            NORTH:
                direction_string = "north"
            NOR_WEST:
                direction_string = "northwest"
            WEST:
                direction_string = "west"
            SOU_WEST:
                direction_string = "southwest"
            SOUTH:
                direction_string = "south"
                
        if $KinematicDriver._is_moving:
            animation_string = "move_"
        else:
            animation_string = "idle_"
        $VisualSprite.animation = animation_string + direction_string
        $WeaponSprite.animation = animation_string + direction_string
