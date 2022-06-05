extends Spatial

# Load the StatMod class resources so all our deriving status conditions have
# access to it.
const STAT_MOD_SCRIPT = preload("res://status/StatMod.gd")
const STAT_MOD_BASE_SCALE_SCRIPT = preload("res://status/StatModBaseScale.gd")

# This function returns the modifiers for this status condition, as an array of
# class StatMod objects.
func get_modifiers():
    pass

# This function returns the particles for this status condition, as an array. It
# should be overloaded by any deriving status conditions. Each status condition
# can have many, or absolutely zero, particle systems. These must be Scalable
# Particle Blueprints. If you wish to
func get_scalable_particles():
    pass

# How long does this status effect last for? <= 0 means never-ending. Note that
# this doesn't mean the status effect can't be reversed by other means, just
# that it doesn't naturally go away.
export(int) var lifetime = -1

# We also support damage over time for our different status effects.
# How much damage is inflicted at the DOT interval?
export(int) var dot_damage = 0
# How frequently do we deal damage via our damage over time? <= 0 means no DOT
export(int) var dot_interval = -1

# What's the icon we use to represent this status effect?
export(Texture) var icon

# What's the keyname for this status effect - the "code side" unique identifier
# we use to differentiate this status effect from all other status effects? 
export(String) var keyname

# What's the name we actually display to users; i.e. what's the PROPER name for
# this status effect?
export(String) var human_name
