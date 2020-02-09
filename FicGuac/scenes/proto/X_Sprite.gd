extends Sprite

var uncasted_pos

# The difference classes of X/point
enum X_CLASSES {
    NONE, NO_COLLIDE, COLLIDE,
    LEFT, LEFT_CENTER, CENTER, RIGHT_CENTER, RIGHT
}

func start_timer(time_sec):
    $Timer.start(time_sec)

# Set the color for this point 
func set_color(x_class):
    match x_class:
        X_CLASSES.NO_COLLIDE:
            self.modulate = Color(0.0, 1.0, 0.0)
            
        X_CLASSES.COLLIDE:
            self.modulate = Color(1.0, 0.0, 0.0)
            
        X_CLASSES.LEFT:
            self.modulate = Color(0.352, 0.691, 0.731)
            
        X_CLASSES.LEFT_CENTER, X_CLASSES.CENTER, X_CLASSES.RIGHT_CENTER:
            self.modulate = Color(0.965, 0.863, 0.445)
            
        X_CLASSES.RIGHT:
            self.modulate = Color(0.645, 0.781, 0.508)
            
        _, X_CLASSES.NONE:
            pass
    
    
# On time out, remove this node
func _on_Timer_timeout():
    queue_free()
