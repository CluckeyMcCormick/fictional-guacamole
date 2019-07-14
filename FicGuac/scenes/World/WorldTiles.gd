extends Node

var primary_set = load("res://scenes/World/PrimaryTileSet.tres")
var detail_set = load("res://scenes/World/DetailTileSet.tres")

var PRIME_SNOW = primary_set.find_tile_by_name("snow")
var PRIME_GRASS = primary_set.find_tile_by_name("grass")
var PRIME_DIRT = primary_set.find_tile_by_name("dirt")
var PRIME_SAND = primary_set.find_tile_by_name("sand")
var PRIME_STONE = primary_set.find_tile_by_name("stone")
var PRIME_ICE = primary_set.find_tile_by_name("ice")
var PRIME_WATER = primary_set.find_tile_by_name("water")
var PRIME_LOW_STONE = primary_set.find_tile_by_name("low_stone")