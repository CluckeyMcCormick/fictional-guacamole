class_name StatMod

# Each status condition has any number of modifiers, each of which modify a
# single stat. This class, and it's inheriting classes, describe a single
# modification operation against a single target stat. There may be more
# dependencies or extra stats involved, but the final product of the operation
# is always added against a single stat.

# The string name of the field we're targeting. In other words, it's the
# actual field that is BEING dynamically modified. Using a string allows us
# to dynamically apply the modifiers.
var target_var = ""
# The actual modifying value - this should be an int or a float of some sort.
# Exactly how this value is used will depend on the StatMod class. In the base
# class, this stands for a flat modification: +10, -7, etc.
var mod_value = 0
# The value that was previously applied to target_var. This allows each StatMod
# to clean up after itself.
var _applied_value = 0

# Initializer function
func _init(targ_var, mod):
    target_var = targ_var
    mod_value = mod

# Apply this modifier to a given core. The scalar argument allows us to scale
# this modification up-or-down (i.e. for stacking effects).
func apply(core, scalar):
    var target_value = core.get( target_var )
    core.set( target_var, target_value - _applied_value + (mod_value * scalar) )
    _applied_value = mod_value * scalar
    
# Remove this modifier from a given core.
func unapply(core):
    var target_value = core.get( target_var )
    core.set( target_var, target_value - _applied_value )
    _applied_value = 0
