extends Position3D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Constant Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This scene allows us to spawn little messages in the world, as needed. We'll
# use this to show damage values.
const float_away_text = preload("res://special_effects/FloatAwayText.tscn")
# Preload the rich particle emitter so we know where it's at
const SPE = preload("res://special_effects/particles/ScalableParticleEmitter.tscn")

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
var active_effects = {}

# This signal indicates that we've lost all our hitpoints 
signal object_died(final_damage_type)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func add_status_effect(sfx):
    # Each status effect comes with two array's worth of processing we need to
    # perform - one for modifiers, one for particles.
    var modifiers
    var particles
    
    # These are used in value modifier calculations.
    var target_value
    var add_value
    
    # A new particle effects node that we're gonna add to the scene tree.
    var particle_fx_node
    
    # If we already have this status effect, skip it!
    if sfx.keyname in active_effects:
        return
    
    # Okay, first we're gonna add in the status effect.
    active_effects[sfx.keyname] = sfx
    
    # Attach it as a child of this Stats Core node
    self.add_child(sfx)
    
    # Now we need to apply the modifiers.
    modifiers = sfx.get_modifiers()
    for mod in modifiers:
        match mod.operation:
            sfx.StatOp.FLAT_MOD:
                target_value = self.get( mod.target_var )
                add_value = mod.mod_value
                self.set( mod.target_var, target_value + add_value )
            sfx.StatOp.ADD_SCALE_MOD:
                target_value = self.get( mod.target_var )
                add_value = self.get( mod.scale_base_var )
                add_value *=  mod.mod_value
                self.set( mod.target_var, target_value + add_value )
            _:
                printerr("Invalid OP code: ", mod.operation)

    # Now we need to add the scalable/dynamic particle effects.
    particles = sfx.get_scalable_particles()
    for particle_item in particles:
        if particle_item is ScalableParticleBlueprint:
            particle_fx_node = SPE.instance()
            particle_fx_node.set_blueprint( particle_item )
            particle_fx_node.scale_emitter( Vector3(1, 1, 1) )
            sfx.add_child(particle_fx_node)
        else:
            pass
    
func remove_status_effect(status_effect):
    if not status_effect.keyname in status_effect:
        return
    pass

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
