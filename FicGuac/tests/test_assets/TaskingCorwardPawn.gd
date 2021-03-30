extends "res://motion_ai/pawn/BasePawn.gd"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _process(delta):
    sprite_update()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Order the machine to move an item to a specified position
func move_item(item, final_pos):
    $TaskingCowardMachine.move_item(item, final_pos)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Pawn specific functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func sprite_update():
    # First, update our current orientation 
    update_orient_enum($TaskingCowardMachine._curr_orient)
    
    # Our animation string is composed of an animation key - which indicates the
    # type of animation to play (i.e. idle, walk) - and a direction to for that
    # animation (i.e. east, southwest). The two are separated by a '_'.
    var anim_str = ""
    
    # First, get the animation key. For now, we'll base this off of the state
    # key.
    match $TaskingCowardMachine.physics_travel_key:
        "OnGround", "Idle":
            anim_str += "idle"
            
            # If we have an item, then we need to haul
            if $ItemManagementCore.has_an_item():
                anim_str += "_haul" 
            
        "Falling":
            anim_str += "fall"
            
        "Walk":
            # If we have an item, then we're hauling. No matter what!
            if $ItemManagementCore.has_an_item():
                anim_str += "haul"
            # Special case - if our current goal key is flee, we have a special
            # "flee" animation we can use.
            elif $TaskingCowardMachine.goal_key == "Flee":
                anim_str += "flee"
            # Otherwise, just use the walk.
            else:
                anim_str += "walk"
            
        _:
            print("Unrecognized State Key: ", $TaskingCowardMachine.physics_travel_key)
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
