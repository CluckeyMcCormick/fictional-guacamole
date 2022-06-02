extends Spatial

# This enum defines the different types of stat operations that each
# modification can do. That way, we know how to modify the stats in question.
enum StatOp {
    # This is just a flat modification: +10, -7, etc.
    FLAT_MOD,
    # This adds a scaled version of the base value back as a modification -
    # i.e 1.5 or -0.7 or 200.
    ADD_SCALE_MOD
}

# Each status condition has any number of modifiers, each of which behave in a
# different way. These modifiers are described by this class.
class StatMod:
    # The string name of the field we're targeting. In other words, it's the
    # actual field that is BEING dynamically modified. Using a string allows us
    # to dynamically apply the modifiers.
    var target_var = ""
    # The string name of the field we derive scale-based calculations from; this
    # is the field that gets used by ADD_SCALE_MOD type operations. It is
    # effectively ignored for FLAT_MOD type operations.
    var scale_base_var = ""
    # This determines what kind of operation we're performing with the modifier.
    # Check the StatOp enum for more.
    var operation = StatOp.FLAT_MOD
    # The actual modifying value - This should be an int or a float of some
    # sort.
    var mod_value = 0
    
    func _init(targ_var, scale_var, op, mod):
        target_var = targ_var
        scale_base_var = scale_var
        operation = op
        mod_value = mod

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
