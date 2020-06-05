extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# What's our tolerance for meeting our goal
const GOAL_TOLERANCE = .05
# What's our tolerance for straying/overshooting on our path to the goal
const PATHING_TOLERANCE = .05
# How fast do we move? (units/second)
const MOVE_RATE = 1

# What is our target position - where are we trying to go?
var target_position = null

# What is this pawn's unit? Who's feeding it the orders? Who is determining
# where it should be to be "in formation"?
var control_unit = null

# What is this pawn's index in it's unit? The index is used to calculate where
# the pawn should come to rest relative to the Unit's "center".
var pawn_index = -1

# Signal issued when this pawn dies. Arguments passed include the specific Pawn,
# the assigned Unit, and the Unit Index.
signal pawn_died(pawn, unit, unit_index)

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func _physics_process(body_state):   
    var dirs = Vector3.ZERO
    
    if not self.is_on_floor():
        dirs.y = -0.05
    
    if target_position != null and self.global_transform.origin.distance_to(target_position) > GOAL_TOLERANCE:
        # Calculate the distance from our current global position
        dirs = target_position - self.global_transform.origin
        # Use that distance to calculate a direction on each axis - do we need to go
        # positively or negatively?
        if dirs.x != 0 and abs(dirs.x) > PATHING_TOLERANCE:
            dirs.x = dirs.x / abs(dirs.x)
        if dirs.z != 0 and abs(dirs.z) > PATHING_TOLERANCE:
            dirs.z = dirs.z / abs(dirs.z)

    # If we're trying to move somewhere...
    if dirs != Vector3.ZERO:
        # Then move (with some snap)
        self.move_and_slide_with_snap(dirs * MOVE_RATE, Vector3(0, 1, 0))
        #self.move_and_slide(dirs * MOVE_RATE)

# Registers this UnitPawn to a Unit node. Assigns the provided index to this
# UnitPawn
func register_to_unit(unit_node, unit_index):
    # Assign the controlling unit
    control_unit = unit_node
    # Assign the unit index
    pawn_index = unit_index
    # Register the move_order_callback with our current object (so we can get
    # move orders hand delivered)
    control_unit.connect("move_ordered", self, "_on_Unit_move_ordered")
    # Register the pawn_died signal with our current object (so we can get
    # move orders hand delivered)
    self.connect("pawn_died", unit_node, "_on_UnitPawn_pawn_died")

# Sets this UnitPawn to not collide with all of the nodes in the provided list.
# Intended for making sure a UnitPawn doesn't collide with the other UnitPawns
# in it's fellow unit.
func no_collide_with_list(node_list):
    # For each node in the provided node list...
    for node in node_list:
        # If the current node in our list is NOT this UnitPawn...
        if node != self:
            # Then don't collide this UnitPawn with this other node
            self.add_collision_exception_with( node )

func _on_Unit_move_ordered(unit_target):
    # Calculate the individual position based on the unit_position, and set the
    # target position using that calculated value
    var new_target = self.control_unit.get_pawn_index_pos(self.pawn_index)
    new_target.x += unit_target.x
    new_target.z += unit_target.z
    
    set_target_position(new_target)

# Set the target position for this UnitPawn. This exists so that we have a
# standardized way of setting the target position. Currently we only need to do
# this one line - makes this function a bit weird, but we can expand it if we
# need to.
func set_target_position(position):
    target_position = position
    