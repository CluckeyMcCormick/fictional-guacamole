extends Node

var primary_set = load("res://scenes/World/data/PrimaryTileSet.tres")
var detail_set = load("res://scenes/World/data/DetailTileSet.tres")

var PRIME_SNOW = primary_set.find_tile_by_name("snow")
var PRIME_GRASS = primary_set.find_tile_by_name("grass")
var PRIME_DIRT = primary_set.find_tile_by_name("dirt")
var PRIME_SAND = primary_set.find_tile_by_name("sand")
var PRIME_STONE = primary_set.find_tile_by_name("stone")
var PRIME_ICE = primary_set.find_tile_by_name("ice")
var PRIME_WATER = primary_set.find_tile_by_name("water")
var PRIME_LOW_STONE = primary_set.find_tile_by_name("low_stone")

# One of the... rougher aspects of how we do tiles is that we need to check the
# adjacency conditions to create our edge tiles. This cardinal enum specifies
# our different directions.
enum Cardinal {
    EAST = 0,  NORTH_EAST = 2, # Multiples of 2 because our flags have a 2 bit space
    NORTH = 4, NORTH_WEST = 6,
    WEST = 8,  SOUTH_WEST = 10,
    SOUTH = 12, SOUTH_EAST = 14
}

# To actually access the different cardinal directions more easily, this dict
# contains Vector2 shifts. Adding these to our current coordinates should net
# us the coordinates for a tile in that direction.
var CARDINAL_SHIFTS = {
    Cardinal.EAST:  Vector2(1,  0), Cardinal.NORTH_EAST: Vector2( 1, -1),
    Cardinal.NORTH: Vector2(0, -1), Cardinal.NORTH_WEST: Vector2(-1, -1),
    Cardinal.WEST:  Vector2(-1, 0), Cardinal.SOUTH_WEST: Vector2(-1,  1),
    Cardinal.SOUTH: Vector2(0,  1), Cardinal.SOUTH_EAST: Vector2( 1,  1),
}

# Adjacent tile is greater than this tile
const ADJ_GT = 0x10
# Some edge tiles have duplicates - this flag indicates to use the duplicate
const ADJ_ALT_FLAG = 0x01
# Since we often use "greater than" and the "alt" flag in conjuction, we'll
# just combine them for quick and easy reference.
const ADJ_GT_ALT = ADJ_GT | ADJ_ALT_FLAG

# A mask to access our flag bits
const FLAG_MASK = 0x3

# Masks for reading the above bits, shifted by direction
enum CardinalMask {
    MASK_EAST =  FLAG_MASK << Cardinal.EAST,
    MASK_NORTH = FLAG_MASK << Cardinal.NORTH,
    MASK_WEST =  FLAG_MASK << Cardinal.WEST,
    MASK_SOUTH = FLAG_MASK << Cardinal.SOUTH,
    
    MASK_NORTH_EAST = FLAG_MASK << Cardinal.NORTH_EAST,
    MASK_NORTH_WEST = FLAG_MASK << Cardinal.NORTH_WEST,
    MASK_SOUTH_WEST = FLAG_MASK << Cardinal.SOUTH_WEST,
    MASK_SOUTH_EAST = FLAG_MASK << Cardinal.SOUTH_EAST
}

# All the edge tiles are the same for each of the primary types. They'll even
# have the same names - the only difference will be their location (and even
# then, only on the y axis). Therefore, we'll generate the necessary dictionary
# using this nifty function.
# Takes in the coordinates for the upper left most edge tile - should be the
# coordinate for the NW_INT corner tile.
func generate_edges(ul_coords):
    
    # The dict follow a certain formula, so we'll just return it right away
    return {
        # First, the easiest coordinates: the sides
        ADJ_GT << Cardinal.NORTH : ul_coords + Vector2(1, 0),
        ADJ_GT << Cardinal.WEST  : ul_coords + Vector2(0, 1),
        ADJ_GT << Cardinal.EAST  : ul_coords + Vector2(3, 1),
        ADJ_GT << Cardinal.SOUTH : ul_coords + Vector2(1, 3),

        # Next, the alts for those side tiles
        ADJ_GT_ALT << Cardinal.NORTH : ul_coords + Vector2(2, 0),
        ADJ_GT_ALT << Cardinal.WEST : ul_coords + Vector2(0, 2),
        ADJ_GT_ALT << Cardinal.EAST : ul_coords + Vector2(3, 2),
        (ADJ_GT | ADJ_ALT_FLAG ) << Cardinal.SOUTH : ul_coords + Vector2(2, 3),
        
        # Now, the interior corner tiles
        (ADJ_GT << Cardinal.WEST) | (ADJ_GT << Cardinal.NORTH): ul_coords,
        (ADJ_GT << Cardinal.EAST) | (ADJ_GT << Cardinal.NORTH): ul_coords + Vector2(3, 0),
        (ADJ_GT << Cardinal.WEST) | (ADJ_GT << Cardinal.SOUTH): ul_coords + Vector2(0, 3),
        (ADJ_GT << Cardinal.EAST) | (ADJ_GT << Cardinal.SOUTH): ul_coords + Vector2(3, 3),
        
        # Finally, the exterior corner tiles
        ADJ_GT << Cardinal.NORTH_WEST : ul_coords + Vector2(1, 1),
        ADJ_GT << Cardinal.NORTH_EAST : ul_coords + Vector2(2, 1),
        ADJ_GT << Cardinal.SOUTH_WEST : ul_coords + Vector2(1, 2),
        ADJ_GT << Cardinal.SOUTH_EAST : ul_coords + Vector2(2, 2),
        
        # 
        # Now then, what if we have an alt side, but we actually want a corner?
        # Let's make some 'aliases', as it were, so we can handle those exceptions
        #
              
        # East and west is alt
        (ADJ_GT_ALT << Cardinal.WEST) | (ADJ_GT << Cardinal.NORTH): ul_coords,
        (ADJ_GT_ALT << Cardinal.EAST) | (ADJ_GT << Cardinal.NORTH): ul_coords + Vector2(3, 0),
        (ADJ_GT_ALT << Cardinal.WEST) | (ADJ_GT << Cardinal.SOUTH): ul_coords + Vector2(0, 3),
        (ADJ_GT_ALT << Cardinal.EAST) | (ADJ_GT << Cardinal.SOUTH): ul_coords + Vector2(3, 3),
        # North and south is alt
        (ADJ_GT << Cardinal.WEST) | (ADJ_GT_ALT << Cardinal.NORTH): ul_coords,
        (ADJ_GT << Cardinal.EAST) | (ADJ_GT_ALT << Cardinal.NORTH): ul_coords + Vector2(3, 0),
        (ADJ_GT << Cardinal.WEST) | (ADJ_GT_ALT << Cardinal.SOUTH): ul_coords + Vector2(0, 3),
        (ADJ_GT << Cardinal.EAST) | (ADJ_GT_ALT << Cardinal.SOUTH): ul_coords + Vector2(3, 3),
        # All sides are alt
        (ADJ_GT_ALT << Cardinal.WEST) | (ADJ_GT_ALT << Cardinal.NORTH): ul_coords,
        (ADJ_GT_ALT << Cardinal.EAST) | (ADJ_GT_ALT << Cardinal.NORTH): ul_coords + Vector2(3, 0),
        (ADJ_GT_ALT << Cardinal.WEST) | (ADJ_GT_ALT << Cardinal.SOUTH): ul_coords + Vector2(0, 3),
        (ADJ_GT_ALT << Cardinal.EAST) | (ADJ_GT_ALT << Cardinal.SOUTH): ul_coords + Vector2(3, 3),
    }

# Each primary type of tile has has two types of detail tiles: decorations, and
# edges. Decorations are retrieved by string name; the values for the edges are
# determined using the above bit-packing formula.
var snow_detail = {
    "deco" : {
        "BUMP01" : Vector2(2, 28),
        "BUMP02" : Vector2(2, 29),
        "ROCK01" : Vector2(2, 30),
        "ROCK02" : Vector2(2, 31),
        "ROCK03" : Vector2(3, 29),
        "ROCK04" : Vector2(3, 30),
    },
    "edge" : generate_edges( Vector2(4, 28) )
}

var grass_detail = {
    "deco" : {
        "FLOWER01" : Vector2(0, 24),
        "FLOWER02" : Vector2(1, 24),
        "FLOWER03" : Vector2(2, 24),
        "FLOWER04" : Vector2(3, 24),
        "FLOWER05" : Vector2(3, 27),
        "GRASS01" : Vector2(0, 25),
        "GRASS02" : Vector2(1, 25),
        "GRASS03" : Vector2(0, 26),
        "GRASS04" : Vector2(1, 26),
        "PLANT01" : Vector2(0, 27),
        "PLANT02" : Vector2(1, 27),
        "PLANT03" : Vector2(2, 27),
        "STUMP01" : Vector2(2, 25),
        "STUMP02" : Vector2(2, 26),
        "ROCK01" : Vector2(3, 25),
        "ROCK02" : Vector2(3, 26),
    },
    "edge" : generate_edges( Vector2(4, 24) )
}

var dirt_detail = {
    "deco" : {
        "BUMP01" : Vector2(0, 23),
        "BUMP02" : Vector2(1, 23),
        "TEXTURE01" : Vector2(0, 22),
        "TEXTURE02" : Vector2(1, 22),
        "TEXTURE03" : Vector2(2, 22),
        "TEXTURE04" : Vector2(1, 21),
        "PLANT01" : Vector2(2, 21),
        "ROCK01" : Vector2(3, 21),
        "ROCK02" : Vector2(3, 22),
    },
    "edge" : generate_edges( Vector2(4, 20) )
}

var sand_detail = {
    "deco" : {
        "BUMP01" : Vector2(0, 19),
        "BUMP02" : Vector2(1, 19),
        "TEXTURE01" : Vector2(0, 18),
        "TEXTURE02" : Vector2(1, 18),
        "TEXTURE03" : Vector2(2, 18),
        "TEXTURE04" : Vector2(1, 17),
        "PLANT01" : Vector2(2, 17),
        "ROCK01" : Vector2(3, 17),
        "ROCK02" : Vector2(3, 18),
    },
    "edge" : generate_edges( Vector2(4, 16) )
}

var stone_detail = {
    "deco" : {
        "TEXTURE01" : Vector2(0, 14),
        "TEXTURE02" : Vector2(1, 14),
        "TEXTURE04" : Vector2(1, 13),
        "ROCK01" : Vector2(3, 13),
        "ROCK02" : Vector2(3, 14),
    },
    "edge" : generate_edges( Vector2(4, 12) )
}

var ice_detail = {
    "deco" : {
        "SHINE" : Vector2(0, 8),
        "CRACK" : Vector2(0, 9),
    },
    "edge" : generate_edges( Vector2(4, 8) )
}

var water_detail = {
    "deco" : {
    },
    "edge" : generate_edges( Vector2(4, 4) )
}

var low_stone_detail = {
    "deco" : {
        "TEXTURE01" : Vector2(0, 2),
        "TEXTURE02" : Vector2(1, 2),
        "TEXTURE04" : Vector2(1, 1),
        "ROCK01" : Vector2(3, 1),
        "ROCK02" : Vector2(3, 2),
    },
    "edge" : generate_edges( Vector2(4, 0) )
}

# For easy access by the ID of each primary type of terrain, the above detail
# dicts are organized into this dictionary.
var detail_dict = {
    PRIME_SNOW : snow_detail,
    PRIME_GRASS : grass_detail,
    PRIME_DIRT : dirt_detail,
    PRIME_SAND : sand_detail,
    PRIME_STONE : stone_detail,
    PRIME_ICE : ice_detail,
    PRIME_WATER : water_detail,
    PRIME_LOW_STONE : low_stone_detail
}