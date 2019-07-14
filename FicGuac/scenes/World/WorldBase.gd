extends Node2D

# In order to paint the world, we need a way to refer to the tiles. Just using
# an atlas to automatically break up our textures does not, unfortunately,
# allow you to name the tiles. So we'll do it through a singular.
var tile_codes

# TileMap seems to be set up such that it doesn't really have a fixed size. You
# can just keep expanding as you add tiles. However, we want our world to be
# limited in scope. 
export(int) var world_len_x
export(int) var world_len_y

func _ready():
    # Get our tile constants
    tile_codes = get_node("/root/WorldTiles")
    print( tile_codes.detail_set.get_tiles_ids() )
    print( tile_codes.primary_set.tile_get_name(tile_codes.PRIME_GRASS) )
    
    $Detail.set_cell( 0, 0, 0, false, false, false, Vector2( 4, 0 )) 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
