tool
extends Spatial

# What type of crop does this farm have?
enum CROP_TYPE {
    corn,
    cabbage,
    carrot,
    sunflower,
    barley
}

# Export the config variables to the editor so we can set them on the fly
export(Vector2) var _plot_size = Vector2(3, 3) setget set_plot_size
export(CROP_TYPE) var _crop_type = CROP_TYPE.barley setget set_crop_type

# What's the minimum size for each farm plot, on x and y? Use a Vector2 for
# flexibility.
const PLOT_SIZE_MINIMUM = Vector2(3, 3)

# Preload our selections for Crops - the (C)rop (S)cenes
const CS_BARLEY = preload("res://scenes/formation/terrain/crops/Barley.tscn")
const CS_CORN = preload("res://scenes/formation/terrain/crops/Corn.tscn")
const CS_CABBAGE = preload("res://scenes/formation/terrain/crops/Cabbage.tscn")
const CS_CARROT = preload("res://scenes/formation/terrain/crops/Carrot.tscn")
const CS_SUNFLOWER = preload("res://scenes/formation/terrain/crops/Sunflower.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
    _farm_refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Refreshes the farm to reflect our new settings - i.e. plot size, crop type
func _farm_refresh():
    
    # First off, if we don't have a plot or crop grid - which can happen (I
    # think it happens BEFORE the node enters the scene) - we need to back out
    if $PlotGrid == null or $Crops == null:
        return
    
    # Clear both of our grids
    $PlotGrid.clear()
    
    for c in $Crops.get_children():
        c.queue_free()
    
    # Okay, first thing we gotta do is build the farm plot - that patch of dirt
    # that sits below the crops. To determine which tile to place down as we
    # build the plot, we'll do some tests and make decisions based on these
    # variables
    var x_low_edge = false
    var x_high_edge = false
    
    var z_low_edge = false
    var z_high_edge = false
    
    var any_edge = false
    
    # Now, we need to get the tile to paint by name. We'll throw it into this
    # string here so we can get-and-set it later. We'll also stick the tile-ID
    # into here
    var tile = ""
    
    # Now, let's iterate over the size of the plot
    for x in range(_plot_size.x):
        for z in range(_plot_size.y):
            # Test where we are on each axis - are we at the base edge, or are
            # we at the far edge?
            x_low_edge = x == 0
            x_high_edge = x == (_plot_size.x - 1)
            z_low_edge = z == 0
            z_high_edge = z == (_plot_size.y - 1)
            
            # Test all of the edges - we'll use this later!
            any_edge = x_low_edge or x_high_edge or z_low_edge or z_high_edge
        
            # Now that we've done those tests, we can guess our vague area
            # without having to check. By mixing-and-matching those tests, we
            # can determine what type of tile to place - neat!
            # First, let's test out the corners.
            if x_low_edge and z_low_edge:
                tile = "NorthPlotCorner"
            elif x_high_edge and z_low_edge:
                tile = "EastPlotCorner"
            elif x_low_edge and z_high_edge:
                tile = "WestPlotCorner"
            elif x_high_edge and z_high_edge:
                tile = "SouthPlotCorner"
            # Well, that's the corners done. Now we'll take a look at the edges.
            # In the case of edges, only one test is true
            elif x_low_edge:
                tile = "NorthWestPlotSiding"
            elif x_high_edge:
                tile = "SouthEastPlotSiding"
            elif z_low_edge:
                tile = "NorthEastPlotSiding"
            elif z_high_edge:
                tile = "SouthWestPlotSiding"
            # Otherwise, we have to be in the middle somewhere - and that's just
            # dirt!
            else:
                tile = "DirtPadding"
            
            tile = $PlotGrid.mesh_library.find_item_by_name(tile)
            $PlotGrid.set_cell_item(x, 0, z, tile)

            # If this is an edge case, back out. We're done here
            if any_edge:
                continue

            # Now that we've set the ground tile, there's one other thing we can
            # do - since this isn't an edge tile, we can place a crop. Match the
            # crop type and instance the scene
            match _crop_type:
                CROP_TYPE.barley:
                    tile = CS_BARLEY.instance()
                CROP_TYPE.corn:
                    tile = CS_CORN.instance()
                CROP_TYPE.cabbage:
                    tile = CS_CABBAGE.instance() 
                CROP_TYPE.carrot:
                    tile = CS_CARROT.instance()  
                CROP_TYPE.sunflower:
                    tile = CS_SUNFLOWER.instance()
                # Any other type of Crop is invalid, so set it to an invalid
                # value
                _:
                    tile = null
            # If we have an invalid value, then we need to skip.
            if tile == null:
                continue
            
            # Set the name
            tile.set_name("crops[" + str(x) + "," + str(z) +"]")
            # Attach the crop tile to the Crops group
            $Crops.add_child(tile)
            # Move the crop over to the correct position
            tile.translate( Vector3(x + 0.5, 0, z + 0.5) )

func set_plot_size(new_plot_size):
    # Set the size restrictions for the plot; it needs to be AT LEAST EQUAL TO
    # the minimum size.
    if new_plot_size.x < PLOT_SIZE_MINIMUM.x:
        new_plot_size.x = PLOT_SIZE_MINIMUM.x
    if new_plot_size.y < PLOT_SIZE_MINIMUM.y:
        new_plot_size.y = PLOT_SIZE_MINIMUM.y
    
    _plot_size = new_plot_size
    _farm_refresh()
    
func set_crop_type(new_crop_type):
    _crop_type = new_crop_type
    _farm_refresh()
