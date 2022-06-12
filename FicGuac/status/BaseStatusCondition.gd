extends Spatial

# Load the StatMod class resources so all our deriving status conditions have
# access to it.
const STAT_MOD_SCRIPT = preload("res://status/StatMod.gd")
const STAT_MOD_BASE_SCALE_SCRIPT = preload("res://status/StatModBaseScale.gd")

# Preload the scalable particle emitter so we know where it's at
const SPE = preload("res://special_effects/particles/ScalableParticleEmitter.tscn")

# Does this status condition have a limited lifespan - i.e. does this status
# condition naturally dissipate after a set period of time?
export(bool) var limited_lifespan = true
# Does this status condition deal a set amount of damage at a regular interval -
# i.e. damage over time?
export(bool) var damage_over_time = false
# How much damage is dealt whenever the damage-over-time interval is tripped?
export(int) var dot_damage = 0

# What's the icon we use to represent this status effect?
export(Texture) var icon

# What's the keyname for this status effect - the "code side" unique identifier
# we use to differentiate this status effect from all other status effects? 
export(String) var keyname

# What's the name we actually display to users; i.e. what's the PROPER name for
# this status effect?
export(String) var human_name

# This signal indicates that the condition expired and should be removed.
signal condition_expired(condition)
# This signal indicates that the damage-over-time interval has fired and that
# the given amount of damage should be dealt.
signal dot_damaged(condition, damage)

# Safety/control variable: have we already spawned in our different particle
# effects? This will prevent us from accidentally spawning too many particle
# systems.
var particles_spawned = false

#
# Overload/Prototype Functions
#
# This function returns the modifiers for this status condition, as an array of
# StatMod class objects.
func get_modifiers():
    pass

# This function returns the particles for this status condition, as an array. It
# should be overloaded by any deriving status conditions. Each status condition
# can have many, or absolutely zero, particle systems. These must be loaded
# (via the preload() function) Scalable Particle Blueprints. If you wish to use
# a prebuilt particle system, simply place the prebuilt particle system under
# the deriving status condition's node.
func get_scalable_particles():
    pass

#
# Utility/Initializer Functions
#
# This function spawns particle systems, specified in ScalableParticleBlueprint
# format and given by the get_scalable_particles() function, under this status
# condition.
func spawn_particles( system_scale = Vector3(1, 1, 1) ):
    # A new particle effects node that we're gonna add to the scene tree.
    var fx_node
    
    # If we've already spawned our particles, back out
    if particles_spawned:
        return
    
    # Now we need to add the scalable/dynamic particle effects.
    for particle_item in get_scalable_particles():
        # If any of the scalable particle items are not Scalable Particle
        # Blueprints, skip it!
        if not particle_item is ScalableParticleBlueprint:
            continue
        # Create the Scalable Particle Emitter
        fx_node = SPE.instance()
        # Pass it the blueprint
        fx_node.set_blueprint( particle_item )
        # Scale the emitter
        fx_node.scale_emitter( system_scale )
        # Stick the new system under this status effect.
        add_child(fx_node)

    # We have now spawned the particle systems for this node
    particles_spawned = true
    
#
# Base Functions
#
func _ready():
    # First, let's ensure that none of the timers are running unnecessarily 
    $LifetimeTimer.autostart = false
    $DamageIntervalTimer.autostart = false
    
    # Alright - now, if this status condition has a lifetime, start the lifetime
    # timer.
    if limited_lifespan:
        $LifetimeTimer.start()
    # Otherwise, just make sure it's not running.
    else:
        $LifetimeTimer.stop()

    # If this status condition deals damage over time, start the timer.
    if damage_over_time:
        $DamageIntervalTimer.start()
    # Otherwise, just make sure it's not running.
    else:
        $DamageIntervalTimer.stop()

# When the lifetime timer expires, fire the "condition_expired" signal.
func _on_LifetimeTimer_timeout():
    # Stop the DamageIntervalTimer, so that we don't give damage after expiring
    $DamageIntervalTimer.stop()
    # Stop the LifetimeTimer too - this should only ever go off once.
    $LifetimeTimer.stop()
    # Fire the expiration signal
    emit_signal("condition_expired", self)

# When the dots timer expires, fire the "dot_damage" signal.
func _on_DamageIntervalTimer_timeout():
    # Fire the damage signal
    emit_signal("dot_damaged", self, dot_damage)
    # Start the timer over - no such thing as one-shot DOTS here.
    $DamageIntervalTimer.start()
