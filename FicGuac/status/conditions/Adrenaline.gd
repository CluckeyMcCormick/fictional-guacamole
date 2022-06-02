extends "res://status/BaseStatusCondition.gd"

var modifiers = [
    StatMod.new("eff_move_speed", "base_move_speed", StatOp.ADD_SCALE_MOD, .15),
]
var particles = [
    preload("res://special_effects/particles/scalable_blueprints/spb_fire.tres"),
]

func get_modifiers():
    return modifiers

func get_scalable_particles():
    return particles