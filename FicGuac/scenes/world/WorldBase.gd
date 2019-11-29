extends Node2D

# In order to paint the world, we need a way to refer to the tiles. Just using
# an atlas to automatically break up our textures does not, unfortunately,
# allow you to name the tiles. You just have to know the Vector2 coordinates.
# So we'll instead name things through this Node
# $TileData


# TileMap seems to be set up such that it doesn't really have a fixed size. You
# can just keep expanding as you add tiles. However, we want our world to be
# limited in scope. These variables determine the size of the area (in tiles)
# that we'll be performing our algorithms on.
export(int) var world_len_x
export(int) var world_len_y

export(int) var world_seed

# Open Simplex Generator for determining soil composition
var soil_noise
# Open Simplex Generator for determining moisture levels
var moisture_noise

func _ready():
    pass

# This will be the function we call to generate the world. Every inheriting
# world should provide their own version of this.
func generate():
    # Step 1: Seed the randomatico!
    seed(world_seed)
    
    # Step 2: Make the generators
    soil_noise = OpenSimplexNoise.new()
    moisture_noise = OpenSimplexNoise.new()
    
    # Step 3: Set our variables!
    soil_noise.seed = randi()
    soil_noise.octaves = 4
    soil_noise.period = 20.0
    soil_noise.persistence = 0.8
    
    moisture_noise.seed = randi()
    moisture_noise.octaves = 4
    moisture_noise.period = 20.0
    moisture_noise.persistence = 0.8
    
    # Step 4: Generate the terrain!
    terrain_gen()
    
    # Step 5: Perform an edge pass over the fresh terrain
    _edge_pass(0, world_len_x)

# Performs the _edge_determine algorithm on every world tile in the specified
# range. Really just a range-enabled wrapper for _edge_determine.
func _edge_pass(start_x, end_x):
    for x in range(start_x, end_x):
        for y in range(world_len_y):
            _edge_determine(x, y)

# So our world is just a series of 32 x 32 squares. How dow we make the
# transitions between these tiles look nice? By using our 16 x 16 detail layers
# to add transition tiles. However, the process for actually deciding what tiles
# go where is rather complex (lots of nested for loops), and we'll want to do it
# for every world type, so it has been provided here in the base world.
# Currently NOT thread-safe.
func _edge_determine(prime_x, prime_y):
    # To decide our current "detail" quadrant, we'll test the parity of the x
    # and y components. These masks will help with that.
    var DET_X_MASK = 0x1 # 0b01
    var DET_Y_MASK = 0x2 # 0b10
    
    # Cardinal is an enum that we'll be using throughout this algorithm. We'll
    # grab it here so we don't have to continually reference the chain
    var CARD = $TileData.Cardinal
    # Ditto for above, but with the xy shift vectors
    var CARD_SHIFT = $TileData.CARDINAL_SHIFTS
    
    # Our priority properties can't be stored in the tiles, so we have to store
    # them in an external dictionary in tile_codes. We'll use this var for easy
    # reference and access.
    var PRIME_PRI = $TileData.PRIME_PRIORITY
    
    # Since our "current" detail tile is marked as being a 0-3, we need to know
    # which directions to check, depending on our current quadrant.
    var direction_dict = {
        0: [ CARD.NORTH, CARD.NORTH_WEST, CARD.WEST ],
        1: [ CARD.EAST, CARD.NORTH_EAST, CARD.NORTH ],
        2: [ CARD.WEST, CARD.SOUTH_WEST, CARD.SOUTH ],
        3: [ CARD.SOUTH, CARD.SOUTH_EAST, CARD.EAST ]
    }

    # Our "Current" detail layer - either Alpha, Beta, or Delta
    var detail_layers = [$DetailAlpha, $DetailBeta, $DetailDelta]

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  
    # Save our x and y position on the "Primary" layer.
    var prime_xy = Vector2( prime_x, prime_y ) 
    # Get the value for this tile - we'll make good use of it
    var current_val = $Primary.get_cellv(prime_xy)
    
    """
    Step 1: For each detail tile...
    """ 
    # Now, for each detail tile (ennumerated 0 to 3)...
    for current_det in range(4):
        
        # Calculate our BASE detail xy         
        var detail_xy = prime_xy * 2
        
        # If the x bit actually has something, then increment x
        if (current_det & DET_X_MASK) != 0:
            detail_xy.x += 1
        # If the y bit actually has something, then increment y
        if (current_det & DET_Y_MASK) != 0:
            detail_xy.y += 1
            
        # Next, get the direction set we'll be working with.    
        var directs = direction_dict[ current_det ]
        
        # We'll need an array to store the type ids of our neighbors
        var nghb_arr = []
        
        # Our neighbor coordinates. Should always be a Vector2
        var nghb_coords
        # Our neighbor value.
        var nghb_val
        
        """
        Step 2: Get the neighbors, organized by priority, least to greatest
        """             
        # For each direction...
        for dir in directs:
            # Calculate our coordinates, then grab the value for that space
            nghb_coords = prime_xy + CARD_SHIFT[dir]
            
            # If the tile is NOT in our world space, skip it.
            if 0 > nghb_coords.x or world_len_x < nghb_coords.x:
                continue
            if 0 > nghb_coords.y or world_len_y < nghb_coords.y:
                continue   
                 
            # Get the tile ID value
            nghb_val = $Primary.get_cellv(nghb_coords) 
        
            # If this is an invalid tile, let's skip
            if not (nghb_val in PRIME_PRI and nghb_val in $TileData.detail_dict):
                continue
         
            # If this tile has less priority than our current tile,
            # then it CAN'T produce an edge over this tile. Skip it!
            if PRIME_PRI[nghb_val] <= PRIME_PRI[current_val]:
                continue
            
            # If a neighbor of this type is already in the array, then
            # skip it! We only need to do one edge pass per type
            if nghb_val in nghb_arr:
                continue
            
            # Our nghb_arr will be the tiles, sorted by priority (least
            # to greatest). That way, the lowest edges will appear on
            # the lowest detail layers and be covered by edges on the
            # upper layers.
            if len(nghb_arr) == 0:
                nghb_arr.append(nghb_val)
                
            elif len(nghb_arr) == 1:
                if PRIME_PRI[nghb_val] > PRIME_PRI[ nghb_arr[0] ]:
                    nghb_arr.push_back(nghb_val)
                else:
                    nghb_arr.push_front(nghb_val)
            else:
                if PRIME_PRI[nghb_val] > PRIME_PRI[ nghb_arr[1] ]:
                    nghb_arr.push_back(nghb_val)
                elif PRIME_PRI[nghb_val] > PRIME_PRI[ nghb_arr[0] ]:
                    nghb_arr.insert(1, nghb_val)
                else:
                    nghb_arr.push_front(nghb_val)
        """
        Step 3: For each of our neighbor types, decide what kind of edge
                tile is required.
        """
        # For each index in our (sorted) neighbor type array
        for i in range( len(nghb_arr) ):
            # This is the tile code we're looking to paint. We'll
            # bit-pack our test results into here.
            var tile = 0
            # A dereference to our edge dictionary
            var edge_dict = $TileData.detail_dict[ nghb_arr[i] ]["edge"]
            
            # Test each of our CARDINAL directions, (elements 0 and 2), 
            # make a note if we pass 
            for dir in [ directs[0], directs[2] ]:
                nghb_coords = prime_xy + CARD_SHIFT[ dir ]
                if $Primary.get_cellv(nghb_coords) == nghb_arr[i]:
                    tile = tile | ($TileData.ADJ_GT << dir)
                
            # If we have a tile, paint it
            if tile in edge_dict:
                # Unfortunaetly, the option to provide an autotile
                # coord is past a series of useless optinonal args and
                # is ONLY available with set_cell, not set_cellv
                detail_layers[i].set_cell(
                    detail_xy.x, detail_xy.y, 0, false, false, false,
                    edge_dict[tile] # The edge dict will have the position
                )
            else:
                # Otherwise, test the corner
                tile = 0
                nghb_coords = prime_xy + CARD_SHIFT[ directs[1] ]
                if $Primary.get_cellv(nghb_coords) == nghb_arr[i]:
                    tile = tile | ($TileData.ADJ_GT << directs[1])
                
                # If we have a tile, paint it
                if tile in edge_dict:
                    detail_layers[i].set_cell(
                        detail_xy.x, detail_xy.y, 0, false, false, false,
                        edge_dict[tile]
                    )

func terrain_gen():
    var moisture
    var soil
    var tile
    
    # For each tile in our map... 
    for x in range(world_len_x):
        for y in range(world_len_y):
            # Get the moisture and soil values
            moisture = moisture_noise.get_noise_2d(x, y)
            soil = soil_noise.get_noise_2d(x, y)
            # Pass those values onto our "Terrain Decision" function
            # This will change depending on our world type
            tile = terrain_decision(moisture, soil)
            # Paint that tile into the world
            $Primary.set_cell(x, y, tile)

func terrain_decision(moisture, soil):
    var tile
    
    # Moisture Category/Cutoff 1: WATER
    if moisture >= 0.3:
        tile = $TileData.PRIME_WATER
        
    # Moisture Category/Cutoff 2: LUSH
    elif moisture >= -0.50:
        # Only STONE can't have grass on it
        if soil >= -0.4:
            tile = $TileData.PRIME_GRASS
        else:
            tile = $TileData.PRIME_STONE
            
    # Moisture Category/Cutoff 3: BARREN
    else:
        # Soil Category/Cutoff 1: DIRT
        if soil >= -0.4:
            tile = $TileData.PRIME_DIRT
        # Soil Category/Cutoff 2: STONE
        else:
            tile = $TileData.PRIME_STONE
            
    return tile

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
#    pass
