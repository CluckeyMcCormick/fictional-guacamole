extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Constant Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This scene allows us to spawn little messages in the world, as needed. We'll
# use this to show damage values.
const float_away_text = preload("res://special_effects/FloatAwayText.tscn")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# How many hitpoints/how much health do we have when this object spawns in?
export(int) var base_hp = 50
# When we get hit, do we spawn damage floats?
export(bool) var damage_floats = true

# The object's current hitpoints, after damage and the like.
var curr_hp = base_hp
# Have our hitpoints dipped below zero? Are we dead? Yes, we even consider items
# and structures to be "dead".
var dead = false

# This signal indicates that we've lost all our hitpoints 
signal object_died(final_damage_type)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func take_damage(damage, damage_type=null):
    # If we're dead, we don't take damage. No coming back from that one.
    if dead:
        return
    
    # Set the HP
    curr_hp -= damage
    
    # If we're showing damage floats, then 
    if damage_floats:
        var damage_text = float_away_text.instance()
        damage_text.display_string = str(damage)
        # We'll assume that this core is always attached to a parent and,
        # furthermore, that parent is underneath a relatively constant node.
        get_parent().get_parent().add_child(damage_text)
        # We will also assume our parent is some sort of Spatial (3D) node
        damage_text.global_transform.origin = get_parent().global_transform.origin
    
    # Clamp it
    curr_hp = clamp(curr_hp, 0, base_hp)
    
    # If we don't have any health...
    if curr_hp == 0:
        # Then we're dead.
        dead = true
        # Tell the world that we're dead.
        emit_signal("object_died", damage_type)

func heal_damage(damage_healed):
    # If we're dead, we don't heal damage. No coming back from that one.
    if dead:
        return
        
    # Set the HP
    curr_hp += damage_healed
    
    # Clamp it
    curr_hp = clamp(curr_hp, 0, base_hp)
