extends "res://motion_ai/pawn/BasePawn.gd"

const short_sword_KMAD = preload("res://motion_ai/pawn/weapon_sprites/pawn_short_sword_frames_KMAD.tres")

# Are we currently playing a demand animation? What animation?
var animation_demanded = ""

# This signal fires when a task fails or succeeds.
signal task_complete()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _process(delta):
    # If we're currently performing a demand animation, back out.
    if animation_demanded != "":
        return
    sprite_update()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Order the machine to move an item to a specified position
func give_task(task):
    $TaskingCowardMachine.give_task(task)

# Set the equipment for the Pawn. Overrides underlying BasePawn animations with
# KMAD equivalents
func assert_equipment(new_equip):
    # Assign the enum
    equipment = new_equip
    
    # Set the appropriate frames
    match equipment:
        Equipment.NONE:
            $WeaponSprite.frames = null
        Equipment.SHORT_SWORD:
            $WeaponSprite.frames = short_sword_KMAD
    
    # The weapon sprite has to match the visual sprite, so let's just take the
    # animation and the current frame.
    $WeaponSprite.animation = $VisualSprite.animation
    $WeaponSprite.frame = $VisualSprite.frame

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Pawn specific functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func sprite_update():
    # First, update our current orientation 
    update_orient_enum($TaskingCowardMachine._curr_orient)
    
    # Okay, the animation string is broken up into sections, which acronyms as
    # KMAD. It goes: KEYWORD_MOVEMENT_ATTITUDE_DIRECTION.
    #   - KEYWORD is a special case, and is typically proceeded with "da" if
    #     it's a demand animation. For example, "da_chop".
    #   - MOVEMENT is the current move set/state, should be something like
    #     "charge", "move", "idle", "fall", etc.
    #   - ATTITUDE is the current temperment/attitude of the machine. This can
    #     be used to give a different flavor or feeling between animations, or
    #     make other visible changes to the Pawn.
    #   - DIRECTION is the animation's direction, this is important to correctly
    #     orient the sprite.
    var anim_str = ""
    
    # Now, the first thing to check is the keyword. However, the keyword is only
    # used by demand animations. So we we'll skip that part.
    
    # Okay, the next part of the string to parse is the MOVEMENT. So, let's
    # match the movement hint.
    match $TaskingCowardMachine.movement_hint:
        # If we're idle OR we're moving, then our handling should be the same,
        # SO...
        "idle", "move":
            # Then pass the movement hint into the animation string
            anim_str += $TaskingCowardMachine.movement_hint
            
            # Now we need to decide the ATTITUDE. However, if we have an item,
            # then our "attitude" is haul.
            if $ItemManagementCore.has_an_item():
                anim_str += "_haul"
            # Otherwise...
            else:
                # Just straight append the attitude hint
                anim_str += "_" + $TaskingCowardMachine.attitude_hint
        
        # If we're falling...
        "fall":
            # Pass that in to the animation string
            anim_str += "fall"
            
            # The FALL animation has no ATTITUDE. It's just falling.
        
        # If we've encountered an invalid movement hint...
        _:
            # Inform the user
            print("Unrecognized Movement Hint: ", $TaskingCowardMachine.movement_hint)
            
            # Defualt to IDLE MOVEMENT, NEUTRAL ATTITUDE
            anim_str += "idle_neutral"
    
    # Now, get the DIRECTION string
    match _orient_enum:
        SOU_EAST:
            anim_str += "_southeast"
        EAST:
            anim_str += "_east"
        NOR_EAST:
            anim_str += "_northeast"
        NORTH:
            anim_str += "_north"
        NOR_WEST:
            anim_str += "_northwest"
        WEST:
            anim_str += "_west"
        SOU_WEST:
            anim_str += "_southwest"
        SOUTH:
            anim_str += "_south"
    
    # We got everything we need - set that animation (but only if it's different)
    if $VisualSprite.animation != anim_str or $WeaponSprite.animation != anim_str:
        $VisualSprite.animation = anim_str
        $WeaponSprite.animation = anim_str

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_TaskingCowardMachine_task_complete_echo():
    emit_signal("task_complete")

func _on_TaskingCowardMachine_demand_animation(animation_key, target, use_direction):
    # This will be the animation string we pass in
    var anim_str = ""
    # This will be the orientation enum for the animation; exactly how we
    # determine this value will vary depending on our current state & inputs.
    var anim_orient
    
    # Real quick - is the animation key we got passed just an empty string? If
    # so, we should just back out. That's an invalid value.
    if animation_key == "":
        animation_demanded = ""
        return
    
    # Save the demanded animation key
    animation_demanded = animation_key
    
    # Store it in the animation string real quick
    anim_str += animation_demanded
    
    # If we're supposed to use direction, then we need to calculate the
    # direction to use.
    if use_direction:    
        # Otherwise, we need to get a direction. If we got handed a target, then
        # the direction-orientation is determined using some math.
        if target != null:
            # Subtract the target position from our current position and get the
            # direction enum from that value.
            anim_orient = calculate_orient_enum(
                target.global_transform.origin - self.global_transform.origin
            )
        # Otherwise, just use the existing orientation
        else:
            anim_orient = _orient_enum
            
        # Now, get the DIRECTION string
        match anim_orient:
            SOU_EAST:
                anim_str += "_southeast"
            EAST:
                anim_str += "_east"
            NOR_EAST:
                anim_str += "_northeast"
            NORTH:
                anim_str += "_north"
            NOR_WEST:
                anim_str += "_northwest"
            WEST:
                anim_str += "_west"
            SOU_WEST:
                anim_str += "_southwest"
            SOUTH:
                anim_str += "_south"

    # Set the animations!
    $VisualSprite.animation = anim_str
    $WeaponSprite.animation = anim_str

func _on_VisualSprite_animation_finished():
    # If we don't have an animation, then there's nothing to do here. Back out.
    if animation_demanded == "":
        return
    
    # Otherwise, we must have completed the animation. YAY! Complete the demand.
    $TaskingCowardMachine.complete_demand(animation_demanded)
    
    # And clear the demanded animation
    animation_demanded = ""
