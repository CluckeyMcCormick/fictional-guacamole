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

# Signal issued when this pawn is stuck and our other error resolution methods
# didn't work.
signal error_goal_stuck(pawn, target_position)

# Do we want to draw a line showing our projected movement vector?
export(bool) var draw_projected_movement = false

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _process(delta):
    sprite_update()
    
    # If we're drawing the projected movement...
    if draw_projected_movement:
        var debug_draw = get_node("/root/DebugDraw")
        debug_draw.draw_ray_3d(
            self.global_transform.origin,
            $KinematicDriverMachine._projected_movement, 1,
            Color.crimson
        )

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Kinematic Driver Machine functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_KinematicDriverMachine_path_complete(position):
    emit_signal("path_complete", self, position)

func _on_KinematicDriverMachine_error_goal_stuck(target_position):
    emit_signal("error_goal_stuck", self, target_position)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set the new target position for the Pawn. This allows you to bypass setting an
# entire path.
func move_to_point(new_target_position):
    # That's now our new target position
    $KinematicDriverMachine.move_to_point(new_target_position)

func clear_pathing():
    $KinematicDriverMachine.clear_pathing()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Pawn specific functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func sprite_update():
    # First, update our current orientation 
    update_orient_enum($KinematicDriverMachine._curr_orient)
    
    # Our animation string is composed of an animation key - which indicates the
    # type of animation to play (i.e. idle, walk) - and a direction to for that
    # animation (i.e. east, southwest). The two are separated by a '_'.
    var anim_str = ""
    
    # First, get the animation key. For now, we'll base this off of the state
    # key.
    match $KinematicDriverMachine.state_key:
        "OnGround", "Idle":
            anim_str += "idle"
            
        "Falling":
            anim_str += "fall"
            
        "Walk":
            anim_str += "walk"
            
        _:
            print("Unrecognized State Key: ", $KinematicDriverMachine.state_key)
            anim_str += "idle"
    
    # Add the "_"
    anim_str += "_"
    
    # Now, get the direction string
    match _orient_enum:
        SOU_EAST:
            anim_str += "southeast"
        EAST:
            anim_str += "east"
        NOR_EAST:
            anim_str += "northeast"
        NORTH:
            anim_str += "north"
        NOR_WEST:
            anim_str += "northwest"
        WEST:
            anim_str += "west"
        SOU_WEST:
            anim_str += "southwest"
        SOUTH:
            anim_str += "south"
    
    # We got everything we need - set that animation (but only if it's different)
    if $VisualSprite.animation != anim_str or $WeaponSprite.animation != anim_str:
        $VisualSprite.animation = anim_str
        $WeaponSprite.animation = anim_str
