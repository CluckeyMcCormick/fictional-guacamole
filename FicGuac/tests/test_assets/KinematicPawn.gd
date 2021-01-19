extends "res://motion_ai/pawn/BasePawn.gd"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Signal issued when this pawn reaches it's target. Includes the specific Pawn
# and the pawn's current position (which will be effectively the same as the
# previous target).
signal path_complete(pawn, position)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver Machine functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_KinematicDriverMachine_path_complete(position):
    emit_signal("path_complete", self, self.get_adjusted_position())

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set the new target position for the Pawn. This allows you to bypass setting an
# entire path.
func set_target_postion(new_target_position):
    # That's now our new target position
    $KinematicDriverMachine.target_position = new_target_position
    
# Set the new target position path for the Pawn. The Pawn will dutifully follow
# these points to reach wherever it's going.
func set_target_path(new_target_path):
    # That's now our new target position
    $KinematicDriverMachine.target_path = new_target_path

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Pawn specific functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_KinematicDriverMachine_visual_update(animation_key, curr_orientation):
    # First, update our current orientation 
    update_orient_enum(curr_orientation)
    
    # Our animation string is composed of an animation key - which indicates the
    # type of animation to play (i.e. idle, walk) - and a direction to for that
    # animation (i.e. east, southwest). The two are separated by a '_'.
    var direction_string
    match _orient_enum:
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
    
    # We got everything we need - set that animation!
    $VisualSprite.animation = animation_key + '_' + direction_string
    $WeaponSprite.animation = animation_key + '_' + direction_string
