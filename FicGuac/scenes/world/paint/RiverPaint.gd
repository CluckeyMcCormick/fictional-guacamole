extends Node

# To paint rounded rivers over lines and over a particular area, we'll need to
# make use of Bresenham functions. We have a library for that, which we'll keep
# on this node
# $HamFunc

# To help simulate the flow of a river, we'll use open simplex noise to provide
# us with a pseudo-heightmap. Our rivers will then naturally (try) to approximate
# the course of the map's canyons. These variables allow us to easily set these
# values using Godot's GUI.
export(int) var flow_octaves
export(float) var flow_period
export(float) var flow_persistence

# We'll stick our Open Simplex Noise generator into this variable.
var noise_gen

func _ready():
    noise_gen = OpenSimplexNoise.new()
    noise_gen.octaves = flow_octaves
    noise_gen.period = flow_period
    noise_gen.persistence = flow_persistence
    noise_gen.seed = randi()

func paint_river(start : Vector2, end : Vector2):
    var prs = funcref(self, "_paint_river_segment")
    $HamFunc.func_line( start, end, prs, [3] )

func _paint_river_segment(xy : Vector2, arg_array : Array):
    # The function we'll paint our circle with
    var fr_water = funcref(self, "_paint_water")
    var fr_sand = funcref(self, "_paint_sand")
    
    var size = arg_array[0]
    $HamFunc.func_circle( xy, size, fr_sand, true )    
    $HamFunc.func_circle( xy, size - 1, fr_water, true )

func _paint_water(xy : Vector2, arg_array : Array):
    $Primary.set_cell(xy.x, xy.y, $TileData.PRIME_WATER)

func _paint_sand(xy : Vector2, arg_array : Array):
    $Primary.set_cell(xy.x, xy.y, $TileData.PRIME_SAND)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
