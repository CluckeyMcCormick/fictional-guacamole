tool
extends Spatial

# Export the config variables to the editor so we can set them on the fly
export(Vector2) var _woods_size = Vector2(3, 3) setget set_woods_size

# What's the minimum size for each farm plot, on x and y? Use a Vector2 for
# flexibility.
const WOODS_SIZE_MINIMUM = Vector2(3, 3)

# Preload our selections for the Trees - the (T)ree (S)cenes
const TS_PINE = preload("res://terrain/trees/PineTreeSimple.tscn") 

# Called when the node enters the scene tree for the first time.
func _ready():
    _woods_refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Refreshes the farm to reflect our new settings - i.e. plot size, crop type
func _woods_refresh():
    
    # First off, if we don't have a plot or crop grid - which can happen (I
    # think it happens BEFORE the node enters the scene) - we need to back out
    if $GrassGrid == null or $Trees == null:
        return
    
    # Clear both of our grids
    $GrassGrid.clear()
    
    for c in $Trees.get_children():
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
    for x in range(_woods_size.x):
        for z in range(_woods_size.y):
            # Test where we are on each axis - are we at the base edge, or are
            # we at the far edge?
            x_low_edge = x == 0
            x_high_edge = x == (_woods_size.x - 1)
            z_low_edge = z == 0
            z_high_edge = z == (_woods_size.y - 1)
            
            # Test all of the edges - we'll use this later!
            any_edge = x_low_edge or x_high_edge or z_low_edge or z_high_edge
        
            # Now that we've done those tests, we can guess our vague area
            # without having to check. By mixing-and-matching those tests, we
            # can determine what type of tile to place - neat!
            # First, let's test out the corners.
            if x_low_edge and z_low_edge:
                tile = "ZNegXNegCorner"
            elif x_high_edge and z_low_edge:
                tile = "ZNegXPosCorner"
            elif x_low_edge and z_high_edge:
                tile = "ZPosXNegCorner"
            elif x_high_edge and z_high_edge:
                tile = "ZPosXPosCorner"
            # Well, that's the corners done. Now we'll take a look at the edges.
            # In the case of edges, only one test is true
            elif x_low_edge:
                tile = "XNegSiding"
            elif x_high_edge:
                tile = "XPosSiding"
            elif z_low_edge:
                tile = "ZNegSiding"
            elif z_high_edge:
                tile = "ZPosSiding"
            # Otherwise, we have to be in the middle somewhere - and that's just
            # dirt!
            else:
                tile = "DarkGrassFill"
            
            tile = $GrassGrid.mesh_library.find_item_by_name(tile)
            $GrassGrid.set_cell_item(x, 0, z, tile)
            
            # If this is an edge case, back out. We're done here
            if any_edge:
                continue
            
            # Spawn in a pine tree for this tile
            tile = TS_PINE.instance()
            
            # Change the color on a dice roll
            tile._tree_type = randi() % 3
            
            # Set the name
            tile.set_name("trees[" + str(x) + "," + str(z) +"]")
            # Attach the crop tile to the Crops group
            $Trees.add_child(tile)
            # Move the crop over to the correct position
            tile.translate( Vector3(x + 0.5, 0, z + 0.5) )

func set_woods_size(new_woods_size):
    # Set the size restrictions for the plot; it needs to be AT LEAST EQUAL TO
    # the minimum size.
    if new_woods_size.x < WOODS_SIZE_MINIMUM.x:
        new_woods_size.x = WOODS_SIZE_MINIMUM.x
    if new_woods_size.y < WOODS_SIZE_MINIMUM.y:
        new_woods_size.y = WOODS_SIZE_MINIMUM.y
    
    _woods_size = new_woods_size
    _woods_refresh()
