tool
extends Spatial

# What size/form of this farm?
enum FARM_PLOT {
    small, tall, wide, large
}

# What type of crop does this farm have?
enum CROP_TYPE {
    wheat
}

# Export the config variables to the editor so we can set them on the fly
export(FARM_PLOT) var _farm_plot = FARM_PLOT.small setget set_farm_plot
export(CROP_TYPE) var _crop_type = CROP_TYPE.wheat setget set_crop_type

# We don't want crops that go on the 3D grid to start at (0, 0) - so what's the
# offset, in grid units?
const CROP_GRID_OFFSET = Vector2(1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
    _farm_refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Refreshes the farm to reflect our new settings - i.e. plot size, crop type
func _farm_refresh():
    
    # First, ensure that we have all the pre-requisite nodes, since it's very
    # possible this function could be called before the scene is ready. That's
    # what happens when you have a setter function in Godot
    if( !has_node("SmallPlot") ):
        return
    if( !has_node("LargePlot") ):
        return
    if( !has_node("TallPlot") ):
        return
    if( !has_node("WidePlot") ):
        return
    if( !has_node("CropGrid") ):
        return
    
    $SmallPlot.visible = false
    $WidePlot.visible = false
    $TallPlot.visible = false
    $LargePlot.visible = false
    
    var field_size = null
        
    match _farm_plot:
        FARM_PLOT.small:
            $SmallPlot.visible = true
            field_size = Vector2(3, 3)
        FARM_PLOT.tall:
            $TallPlot.visible = true
            field_size = Vector2(3, 8)
        FARM_PLOT.wide:
            $WidePlot.visible = true
            field_size = Vector2(8, 3)
        FARM_PLOT.large:
            $LargePlot.visible = true
            field_size = Vector2(8, 8)

    # Build the crops
    _build_crops_grid(field_size)    

# Utility function for building a field of crops on the CropGrid of the given
# size. Uses the built-in offset and crop type:
func _build_crops_grid(field_size):
    var new_x = 0
    var new_z = 0
    
    # Pre-emptively clear the grid
    $CropGrid.clear()
    
    # Iterate over our field - the whole size
    for fs_x in range(field_size.x):
        for fs_z in range(field_size.y):
            # Calculate the new X and Z values
            new_x = CROP_GRID_OFFSET.x + fs_x
            new_z = CROP_GRID_OFFSET.y + fs_z
            
            # Change the crop type
            match _crop_type:
                CROP_TYPE.wheat:
                    # Set the Crop-grid to wheat
                    $CropGrid.set_cell_item(new_x, 0, new_z, 0)
                # Any other type of Crop is invalid, so return
                _:
                    return
    # We did it! We're done. No more crops to set.
    pass

func set_farm_plot(new_farm_plot):
    _farm_plot = new_farm_plot
    _farm_refresh()
    
func set_crop_type(new_crop_type):
    _crop_type = new_crop_type
    _farm_refresh()
