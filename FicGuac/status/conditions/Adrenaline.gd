extends "res://status/BaseStatusCondition.gd"

var modifiers = [
    STAT_MOD_BASE_SCALE_SCRIPT.new("eff_move_speed", "base_move_speed", .5),
]
var particles = []

func get_modifiers():
    return modifiers

func get_scalable_particles():
    return particles
