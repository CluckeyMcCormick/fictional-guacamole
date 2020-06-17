extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const UNIT_INITIAL_STRENGTH = 25

# Preload our selections for UnitPawns
const UP_DEFAULT = preload("res://scenes/formation/UnitPawn.tscn")
const UP_BLOB = preload("res://scenes/formation/unit_pawn_subs/UnitPawnBlob.tscn")
const UP_DREAD_KNIGHT = preload("res://scenes/formation/unit_pawn_subs/UnitPawnDreadKnight.tscn")
const UP_MAGE = preload("res://scenes/formation/unit_pawn_subs/UnitPawnMage.tscn")
const UP_SHROOM = preload("res://scenes/formation/unit_pawn_subs/UnitPawnShroom.tscn")
const UP_SKELETON = preload("res://scenes/formation/unit_pawn_subs/UnitPawnSkeleton.tscn")
const UP_SNAKE = preload("res://scenes/formation/unit_pawn_subs/UnitPawnSnake.tscn")
const UP_SURT = preload("res://scenes/formation/unit_pawn_subs/UnitPawnSurt.tscn")
const UP_TRUS = preload("res://scenes/formation/unit_pawn_subs/UnitPawnTrus.tscn")

# Should we have UnitPawns in this unit colliding with each other?
export(bool) var intra_unit_collision = false
# The unit aligns with an invisible grid of squares - what's the offset of that
# grid?
export(float, -0.5, 0.5, 0.05) var grid_snap_offset
# That invisible grid - how big are the units?
export(float, 0, 2, 0.05) var grid_snap_size

# The current count of pawns in the unit
var pawn_count
# What is considered to be the Unit's "current" position?
var unit_target_pos

# Signal issued whenever a move order is recieved. Argument passed is the
# Vector3 position of the move order - it is the "target" if you will.
signal move_ordered(target_position)

# Called when the node enters the scene tree for the first time.
func _ready():
    
    # Total count of pawns in this unit
    pawn_count = 0
    
    # Round-robin UnitPawn list.
    var rr_up_list = [
        UP_DEFAULT, UP_BLOB, UP_DREAD_KNIGHT, UP_MAGE, UP_SHROOM, UP_SKELETON,
        UP_SNAKE, UP_SURT, UP_TRUS
    ]
    # Shuffle the round robin list
    rr_up_list.shuffle()
    
    # For each child (which we'll assume is a UnitPawn)
    for i in range(UNIT_INITIAL_STRENGTH):
        # Instance this pawn into existence
        var pawn = rr_up_list.pop_back()
        # If we weren't able to get a PackedScene...
        if pawn == null:
            # Then the round-robin UnitPawn scene list is empty. Restock it!
            rr_up_list = [
                UP_DEFAULT, UP_BLOB, UP_DREAD_KNIGHT, UP_MAGE, UP_SHROOM,
                UP_SKELETON, UP_SNAKE, UP_SURT, UP_TRUS
            ]
            pawn = rr_up_list.pop_back()
        # Pawn should now be a packed scene - so instance that scene
        pawn = pawn.instance()
        # Set the name
        pawn.set_name("unitpawn" + str(pawn_count))
        # Attach the pawn to the pawn group
        $PawnGroup.add_child(pawn)
        # Register it to the unit
        pawn.register_to_unit(self, pawn_count)
        # Move it up by half of it's height (so it's not in the ground)
        pawn.translate( Vector3(0, pawn.HEIGHT / 2, 0) )
        # Move the pawn over to the correct position (as determined by index)
        pawn.translate( get_pawn_index_pos(pawn_count) )
        # Increment the count
        pawn_count += 1
    # If we're NOT colliding the UnitPawns in this unit together...
    if not intra_unit_collision:
        # Now that all the pawns have been created, we can iterate over all of
        # them easily - so get that list!
        var pawn_list = $PawnGroup.get_children()
        # No collide all the fellows with this unit. This might be a bit
        # inefficient since it's an N x N (matching every node with every
        # node), but it seems the best solution for us right now
        for pawn in pawn_list:
            pawn.no_collide_with_list(pawn_list)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Orders the unit to move to the specified position 
func order_move(position):
    unit_target_pos = position
    # Subtract out the offset (since offset is technically added into the pos)
    unit_target_pos.x -= grid_snap_offset
    unit_target_pos.z -= grid_snap_offset
    # Divide it by our snap grid-size
    unit_target_pos.x /= grid_snap_size
    unit_target_pos.z /= grid_snap_size
    # We are now looking at this position purely in grid units - so if we round
    # the values, we'll snap to the nearest full grid positions
    unit_target_pos.x = round(unit_target_pos.x)
    unit_target_pos.z = round(unit_target_pos.z)
    # Now, we need to convert it back to in-game distance units
    unit_target_pos.x *= grid_snap_size
    unit_target_pos.z *= grid_snap_size
    # And redo the offset
    unit_target_pos.x += grid_snap_offset
    unit_target_pos.z += grid_snap_offset  
    
    # Now, move TargetGroup node to reflect
    $TargetGroup.global_transform.origin.x = unit_target_pos.x
    $TargetGroup.global_transform.origin.z = unit_target_pos.z
    
    emit_signal("move_ordered", unit_target_pos)

# The position of each and every Pawn is decided according to a mathematical
# formula. Given the index of the pawn, we can calculate where exactly it should
# go. Returns a Vector3 indicating relative position/offset, localized to the
# Unit node and as determined from the Unit's center. 
func get_pawn_index_pos(pawn_index):
    # How many pawns make up one "line" of the Unit? We want to arrange the unit
    # in a square/box formation, so we'll round up to the next square root.
    var UNIT_SIZE = int( ceil( sqrt(UNIT_INITIAL_STRENGTH) ) )
    
    # The x-wise slot for this index
    var unit_x = pawn_index % UNIT_SIZE
    # The z-wise slot for this index
    var unit_z = floor( pawn_index / UNIT_SIZE )
    
    # The two lengths of our unit
    var x_len = 0.5
    var z_len = 0.5
    
    # Every unit is spaced THIS much apart from - we call this the unit place
    # increment ratio, or UPIR
    var UPIR = (1.0 / UNIT_SIZE)
    
    # We measure the position of the unit from the center. That means that, the
    # range of values to be "inside" the unit given a length l is:
    #                            [-l/2, l/2]
    # We can calculate the exact position later; for now we only need to
    # calculate the ratios - we'll start with the position 0 ratio.
    # So, we start at -1/2. Units are placed every UPIR - so it should be:
    #                             -1/2 + UPIR
    # right? WRONG! Because we're calculating on the edge of a pawn
    # position cell. We need to calculate the center - which is:
    #                          -1/2 + (UPIR / 2)
    # And that is the pawn index start ratio - or, PISR!
    var PISR = (-1.0 / 2.0) + (UPIR / 2.0)
    
    # Every time we increment an index, how much space do we cover? 
    var x_increment = UPIR * x_len
    var z_increment = UPIR * z_len
    
    # The position of the unit, calculated from the index. We'll start with a
    # ZERO vector and modify what we want.
    var index_pos = Vector3.ZERO
    index_pos.x = ( PISR * x_len ) + (x_increment * unit_x )
    index_pos.z = ( PISR * z_len ) + (z_increment * unit_z )
    
    # We did it! Return that puppy!
    return index_pos

func _on_UnitPawn_pawn_died(pawn, unit, unit_index):
    pass
