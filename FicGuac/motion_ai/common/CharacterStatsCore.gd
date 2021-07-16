extends Node

# How fast does our drive node move, horizontally? Units/second. This is the
# base measure that buffs/debuffs are applied to.
export(float) var base_move_speed = 10
# How many hitpoints/how much health do we have when this motion AI spawns in?
export(int) var base_hp = 50

# The effective move speed, after buffs and debuffs have been applied.
var eff_move_speed = base_move_speed
# The characters current hitpoints, after damage and the like.
var curr_hp = base_move_speed
