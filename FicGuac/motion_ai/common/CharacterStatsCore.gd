extends Node

# How fast does our drive node move, horizontally? Units/second. This is the
# base measure that buffs/debuffs are applied to.
export(float) var base_move_speed = 10
# How many hitpoints/how much health do we have when this motion AI spawns in?
export(int) var base_hp = 50

# The effective move speed, after buffs and debuffs have been applied.
var eff_move_speed = base_move_speed
# The characters current hitpoints, after damage and the like.
var curr_hp = base_hp
# Is the character dead?
var dead = false

# This signal indicates that the character associated with this node is, in
# fact, dead.
signal character_dead(damage_type)

func take_damage(damage, damage_type=null):
    # If we're dead, we don't take damage. No coming back from that one.
    if dead:
        return
    
    # Set the HP
    curr_hp -= damage
    
    # Clamp it
    curr_hp = clamp(curr_hp, 0, base_hp)
    
    # If we don't have any health...
    if curr_hp == 0:
        # Then we're dead.
        dead = true
        # Tell the world that we're dead.
        emit_signal("character_dead", null)
