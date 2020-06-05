extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Should we have UnitPawns in this unit colliding with each other?
export(bool) var intra_unit_collision = false
# The current count of pawns in the unit
var pawn_count
# What is considered to be the Unit's "current" position?
var unit_target_pos

# Signal issued whenever a move order is recieved. Argument passed is the
# Vector3 position of the move order - it is the "target" if you will.
signal move_ordered(target_position)

# Called when the node enters the scene tree for the first time.
func _ready():
    # Register each Pawn with this Unit
    pawn_count = 0
    
    # Grab the list of pawns
    var pawn_list = $PawnGroup.get_children()
    
    # For each child (which we'll assume is a UnitPawn)
    for pawn in pawn_list:
        # Register it to a unit
        pawn.register_to_unit(self, pawn_count)
        # If we're NOT colliding the UnitPawns in this unit together...
        if not intra_unit_collision:
            # No collide all the fellows with this unit. This might be a bit
            # inefficient since it's an N x N (matching every node with every
            # node), but it seems the best solution for us right now
            pawn.no_collide_with_list(pawn_list)
        # Increment the count
        pawn_count += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# Orders the unit to move to the specified position 
func order_move(position):
    # Set the Unit's target position to the position provided
    unit_target_pos = position
    
    # Now, move TargetGroup node to reflect
    $TargetGroup.translation.x = unit_target_pos.x
    $TargetGroup.translation.z = unit_target_pos.z
    
    emit_signal("move_ordered", unit_target_pos)

# The position of each and every Pawn is decided according to a mathematical
# formula. Given the index of the pawn, we can calculate where exactly it should
# go.
func get_pawn_index_pos(pawn_index):
    # The unit forms up into a square - how many pawns make up one side of the
    # square?
    var UNIT_SIZE = 4
    
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