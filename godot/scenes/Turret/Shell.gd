extends Area2D

# Whenever the shell leaves the screen, kill the shell
func _on_VisDetect_screen_exited():
    queue_free()
