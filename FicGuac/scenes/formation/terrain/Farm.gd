tool
extends Spatial


# What size/form of this farm?
enum FARM_PLOT {
    small, tall, wide, large
}

export(FARM_PLOT) var _farm_plot = FARM_PLOT.small setget set_farm_plot

# Called when the node enters the scene tree for the first time.
func _ready():
    _farm_refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Refreshes the farm to reflect our new settings - i.e. plot size, crop type
func _farm_refresh():
    $SmallPlot.visible = false
    $WidePlot.visible = false
    $TallPlot.visible = false
    $LargePlot.visible = false
        
    match _farm_plot:
        FARM_PLOT.small:
            $SmallPlot.visible = true
        FARM_PLOT.tall:
            $TallPlot.visible = true
        FARM_PLOT.wide:
            $WidePlot.visible = true
        FARM_PLOT.large:
            $LargePlot.visible = true

func set_farm_plot(new_farm_plot):
    _farm_plot = new_farm_plot
    _farm_refresh()
