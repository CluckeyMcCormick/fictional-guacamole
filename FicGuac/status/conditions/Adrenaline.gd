extends "res://status/BaseStatusCondition.gd"

var modifiers = [
    [ "eff_move_speed", "base_move_speed", StatOp.ADD_SCALE_MOD, .15],
]
var particles = [
    preload("res://special_effects/particles/RichParticleMat_Poison.tres"),
]

func get_modifiers():
    return modifiers

func get_particles():
    return particles
