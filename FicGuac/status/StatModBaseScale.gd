class_name StatModBaseScale
extends "res://status/StatMod.gd"

# For this StatMod class, the mod_value field adds a scaled version of the
# secondary "base_value" back as a modification - i.e 1.5 or -0.7 or 200. For
# example, if the target_var is "max_hits", the base_var is "hit_potential" and
# the modifier is .10, then the result would be max_hits += hit_potential * .10.
# This is meant for percentage gains, like 23% gain or loss to some stat. It
# could be the same stat for both base and target, though this is discouraged.

# The string name of the field we derive scale-based calculations from; this
# could be the same as the target_var field though this is discouraged.
var base_var = ""

# Initializer function
func _init(targ_var, base, mod).(targ_var, mod):
    target_var = targ_var
    mod_value = mod
    base_var = base

# Apply this modifier to a given core. The scalar argument allows us to
# scale this modification up-or-down (i.e. for stacking effects).
func apply(core, scalar):
    var target_value = core.get( target_var )
    var add_value = core.get( base_var )
    add_value *= mod_value
    core.set( target_var, target_value - _applied_value + (add_value * scalar) )
    _applied_value = add_value * scalar
