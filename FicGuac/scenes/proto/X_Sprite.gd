extends Sprite

# The difference classes of X/point
enum X_CLASSES {
    NONE, NO_COLLIDE, COLLIDE, THREAT_VECTOR, CAST_POINT
}

func start_timer(time_sec):
    $Timer.start(time_sec)

# Set the color for this point 
func set_color(x_class):
    # Palatable Blue - Color(0.352, 0.691, 0.731)
    match x_class:
        X_CLASSES.NO_COLLIDE:
            self.modulate = Color(0.0, 1.0, 0.0)
            
        X_CLASSES.COLLIDE:
            self.modulate = Color(1.0, 0.0, 0.0)
            
        X_CLASSES.THREAT_VECTOR:
            self.modulate = Color(0.965, 0.863, 0.445)
            
        X_CLASSES.CAST_POINT:
            self.modulate = Color(0.645, 0.781, 0.508)
            
        _, X_CLASSES.NONE:
            pass
    
    
# On time out, remove this node
func _on_Timer_timeout():
    queue_free()
