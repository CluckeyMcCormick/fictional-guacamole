extends "res://motion_ai/pawn/BasePawn.gd"

# Do we want to draw a line showing our projected movement vector?
export(bool) var draw_projected_movement = false

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _process(delta):    
    # If we're drawing the projected movement...
    if draw_projected_movement:
        var debug_draw = get_node("/root/DebugDraw")
        debug_draw.draw_ray_3d(
            self.global_transform.origin,
            $KinematicDriverMachine._projected_movement, 
            1,
            Color.crimson
        )
