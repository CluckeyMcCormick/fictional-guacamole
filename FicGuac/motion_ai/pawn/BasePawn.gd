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

# We'll preload all the weapon frames we need since we'll have to change them on
# the fly.
const short_sword_frames = preload("res://motion_ai/pawn/weapon_sprites/pawn_short_sword_frames.tres")

# To allow for easy configuration of the equipped weapon, we have this enum.
# Dropdown configuration - easy!
enum Equipment {
    NONE, # No Weapon
    SHORT_SWORD, # Short Sword
}

# Which of the above position algorithms will we use? Note that Navigation and
# Detour will be broken unless the appropriate navigation node is provided.
export(Equipment) var equipment = Equipment.NONE setget assert_equipment

# We may need a quick way to refer our current orientation/heading/direction
# (horizontally, at least) without having to derive from whatever variables
# we're looking at. We'll store that value here. 
var _orient_enum = SOUTH

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # Get the drive target node
    navigation_node = get_node(navigation)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# KinematicCore Coupling functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
# Setters & Util
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the equipment for the Pawn
func assert_equipment(new_equip):
    # Assign the enum
    equipment = new_equip
    
    # Set the appropriate frames
    match equipment:
        Equipment.NONE:
            $WeaponSprite.frames = null
        Equipment.SHORT_SWORD:
            $WeaponSprite.frames = short_sword_frames
    
    # The weapon sprite has to match the visual sprite, so let's just take the
    # animation and the current frame.
    $WeaponSprite.animation = $VisualSprite.animation
    $WeaponSprite.frame = $VisualSprite.frame

func update_orient_enum(orient_vec : Vector3):
    # Move the X and Z fields into a Vector2 so we can easily calculate the
    # sprite's current angular direction. Note that the Z is actually
    # inverted; This makes our angles operate on a CCW turn (like a unit
    # circle)
    var orient_angle = Vector2(orient_vec.x, -orient_vec.z).angle()
    # Angles are, by default, in radian form. Good for computers, bad for
    # humans. Since we're just going to check values, and not do any
    # calculations or manipulations, let's just convert it to degrees!
    orient_angle = rad2deg(orient_angle)
    # Both of our sprites start off at 45 degrees on y - so to calculate the
    # true movement angle, we need rotate BACK 45 degrees.
    orient_angle -= 45
    # Godot doesn't do angles as 0 to 360 degress, it does -180 to 180. This
    # makes case-checks harder, so let's just shift things forward by 360 if
    # we're negative.
    if orient_angle < 0:
        orient_angle += 360
    
    # Right! Now we've got an appropriate angle - we just need to set the
    # zones. Each eigth-cardinal is allotted 45 degrees, centered around 
    # increments of 45 - i.e. EAST is at 0, NOR_EAST at 45, NORTH at 90. The
    # periphery of the zone extends +- 45/2, or 22.5. Ergo, our zone checks
    # are values coming from 22.5 + (45 * i)
    if orient_angle < 22.5:
        _orient_enum = EAST
    elif orient_angle < 67.5:
        _orient_enum = NOR_EAST
    elif orient_angle < 112.5:
        _orient_enum = NORTH
    elif orient_angle < 157.5:
        _orient_enum = NOR_WEST
    elif orient_angle < 202.5:
        _orient_enum = WEST
    elif orient_angle < 247.5:
        _orient_enum = SOU_WEST
    elif orient_angle < 292.5:
        _orient_enum = SOUTH
    elif orient_angle < 337.5:
        _orient_enum = SOU_EAST
    else:
        _orient_enum = EAST
