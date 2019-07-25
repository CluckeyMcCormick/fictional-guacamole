extends "res://scenes/world/WorldBase.gd"

# To paint rounded rivers over lines and over a particular area, we'll need to
# make use of Bresenham functions. We have a library for that, which we'll keep
# on this node
# $HamFunc

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func generate():    
    # The function we'll paint our circle with
    var fr_water = funcref(self, "paint_water")
    var fr_sand = funcref(self, "paint_sand")

    $HamFunc.func_circle( Vector2(20, 14), 4, fr_water, true )
    $HamFunc.func_circle( Vector2(27, 7), 4, fr_sand, true )
    $HamFunc.func_circle( Vector2(27, 7), 3, fr_water, false )
    self._edge_pass(0, world_len_x)

func paint_water(xy : Vector2, arg_array : Array):
    $Primary.set_cell(xy.x, xy.y, $TileData.PRIME_WATER)

func paint_sand(xy : Vector2, arg_array : Array):
    $Primary.set_cell(xy.x, xy.y, $TileData.PRIME_SAND)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
