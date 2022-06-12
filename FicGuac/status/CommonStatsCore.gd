extends Position3D

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
# and structures to be "dead". Dead is, generally, considered an unrecoverable
# state.
var dead = false

# Our different, ongoing status effects; the keys are each ongoing status
# condition's keyname, while the values are the effect nodes themselves.
var _active_effects = {}

# This signal indicates that we've lost all our hitpoints 
signal object_died(final_damage_type)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func add_status_effect(status_effect):
    # These are used in value modifier calculations.
    var target_value
    var add_value
    
    # If we already have this status effect, skip it!
    if status_effect.keyname in _active_effects:
        return
    
    # Okay, first we're gonna add in the status effect.
    _active_effects[status_effect.keyname] = status_effect
    
    # Connect the status effect's expiration and damage-over-time signals to the
    # common core's functions.
    status_effect.connect("condition_expired", self, "_on_condition_expire")
    status_effect.connect("dot_damaged", self, "_on_condition_dot_damaged")
    
    # Spawn in the particle effects
    status_effect.spawn_particles()
    
    # Now we need to apply the modifiers.
    for mod in status_effect.get_modifiers():
        mod.apply( self, 1 )
    
    # Finally, attach it as a child of this Stats Core node
    self.add_child(status_effect)
    
func remove_status_effect(status_keyname):
    # What's the status effect we retrieved?
    var sfx
    
    # If this status effect is not present, back out!
    if not status_keyname in _active_effects:
        return
    
    # Get the status effect
    sfx = _active_effects[status_keyname]
    # Remove the status effect from the array.
    _active_effects.erase(status_keyname)
    # Remove the status effect from the scene
    self.remove_child(sfx)
    # For each modifier in this status effect, unapply it
    for mod in sfx.get_modifiers():
        mod.unapply( self )
    # Finally, delete the status effect
    sfx.queue_free()

func clear_status_effects():
    # What's the status effect we retrieved?
    var sfx
    
    # For each keyname, remove the associated status effect.
    for keyname in _active_effects.keys():
        # Get the status effect
        sfx = _active_effects[keyname]
        # Remove the status effect from the array.
        _active_effects.erase(keyname)
        # Remove the status effect from the scene
        self.remove_child(sfx)
        # For each modifier in this status effect, unapply it
        for mod in sfx.get_modifiers():
            mod.unapply( self )
        # Finally, delete the status effect
        sfx.queue_free()

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

func _on_condition_expire(condition):
    remove_status_effect(condition.keyname)

func _on_condition_dot_damaged(_condition, damage):
    take_damage(damage)
