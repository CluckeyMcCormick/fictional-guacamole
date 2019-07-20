extends Camera2D

const SPEED = 500

func _process(delta):
    var move_dist = Vector2(0, 0)
    
    if Input.is_action_pressed("scroll_right"):
        move_dist.x += SPEED * delta
        
    if Input.is_action_pressed("scroll_up"):
        move_dist.y -= SPEED * delta
        
    if Input.is_action_pressed("scroll_left"):
        move_dist.x -= SPEED * delta
        
    if Input.is_action_pressed("scroll_down"):
        move_dist.y += SPEED * delta

    self.position += move_dist