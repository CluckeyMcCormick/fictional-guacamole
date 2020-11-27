extends Spatial

var pawn_waiting_list = []

func _ready():
    # To start the ball rolling, we need to assign starting targets to any and
    # all pawns in the scene.
    pawn_waiting_list.append($BubblePawn)
    pawn_waiting_list.append($MultiplyPawnA)
    pawn_waiting_list.append($MultiplyPawnB)
    pawn_waiting_list.append($FillPawnA)
    pawn_waiting_list.append($FillPawnB)

# Special clean up function - we have to reset the time scale when we exit.
func _exit_tree():
    Engine.set_time_scale(1)

# Called every physics... frame? Cycle? Tick? Doesn't matter - 'delta' is the
# elapsed time since the previous frame.
func _physics_process(delta):
    # While we still have pawns to process...
    while not pawn_waiting_list.empty():
        # We're processing the first pawn on the stack! Get it and remove it.
        var pawn = pawn_waiting_list.pop_front()
        # Is this location we just tested valid?
        var valid_loc = false
    
        # While we don't have a valid location to send the Pawn to...
        while not valid_loc:
            # First, choose a random position between -10 and 10 on x & z
            var new_x = (randf() * 20) - 10
            var new_z = (randf() * 20) - 10
            
            # Move the Telepointer there.
            $Telepointer.translation.x = new_x
            $Telepointer.translation.z = new_z
            
            # Force updates
            $Telepointer/FloorCast.force_raycast_update()
            $Telepointer/ObstacleCast.force_raycast_update()
            
            # This is a valid location IF the Floor Cast is colliding, but NOT
            # the Obstacle Cast
            valid_loc = $Telepointer/FloorCast.is_colliding()
            valid_loc = valid_loc and not $Telepointer/ObstacleCast.is_colliding()
            
        # Telepointer is now at a valid location. Nice! Get a path from the
        # current pawn to wherever we're colliding
        var path = $DetourNavigation/DetourNavigationMesh.find_path(
            pawn.get_translation(),
            $Telepointer/FloorCast.get_collision_point()
        )
        # Set the path!
        pawn.current_path = Array(path["points"])

func _on_AnyPawn_path_complete(pawn, position):
    # Stick this pawn on the stack
    pawn_waiting_list.append(pawn)

func _on_Slider_value_changed(value):
    $GUI/SliderValue.text = str(value)
    Engine.set_time_scale(value)
