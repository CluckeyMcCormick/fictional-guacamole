extends "res://common_mix/CommonStatsCore.gd"

# How fast does our drive node move, horizontally? Units/second. This is the
# base measure that buffs/debuffs are applied to.
export(float) var base_move_speed = 10

# The effective move speed, after buffs and debuffs have been applied.
var eff_move_speed = base_move_speed

