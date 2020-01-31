extends RigidBody2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast? These constants will help to define that.

# Our length for each raycast
const RAYCAST_MAGNITUDE = 25
# When we raycast, we cast the points in front of the boid using the unit
# circle. We start in "front" of the Boid, and cast extra points using this step
const RAYCAST_STEP = PI / 15
# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern.
const RAYCAST_STEPS_COUNT = 20

export(bool) var draw_debug_ray

const ARTI_ACCEL = 50
const MAX_SPEED = 250

var _arti_speed

# The container for bodies we are currently tracking as our "flock"
var flock_members = {}

# The container for bodies we are currently tracking as our "dangers"
var obstacle_members = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    var ray_step
    var new_angle
    _arti_speed = 0
    
    if not draw_debug_ray:
        return
        
    ray_step = 0
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        new_angle = ray_step * RAYCAST_STEP
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(0, 0)
        casted_pos.x = cos(new_angle)
        casted_pos.y = sin(new_angle)
        casted_pos *= RAYCAST_MAGNITUDE
        
        # Add a point at the shifted location
        var debug_node = Sprite.new() # Create a new sprite!
        debug_node.texture = load("res://assets/proto/x.png")
        debug_node.visible = draw_debug_ray
        add_child(debug_node) # Add it as a child of this node.
        debug_node.position = casted_pos
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Add our newly recieved acceleration
    _arti_speed = clamp(_arti_speed + (ARTI_ACCEL * delta), 0, MAX_SPEED)
    # Calculate our movement, given heading, speed, and time delta
    var movement = Vector2(0, 0)
    movement.x = cos(rotation)
    movement.y = sin(rotation)
    movement *= _arti_speed
    movement *= delta
    
    self.position = self.position + movement

func _physics_process(delta):
    var space_state = get_world_2d().direct_space_state
    var ray_step
    var new_angle
    
    ray_step = 0
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        new_angle = self.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(0, 0)
        casted_pos.x = cos(new_angle)
        casted_pos.y = sin(new_angle)
        casted_pos *= RAYCAST_MAGNITUDE
        casted_pos += global_position
        
        # Get the result of our collision raycast
        var result = space_state.intersect_ray( global_position, casted_pos, [self])
        
        # If we're drawing our ray debug
        if draw_debug_ray:
            # Add a point at the shifted location
            var debug_node = Sprite.new() # Create a new sprite!
            debug_node.texture = load("res://assets/proto/x.png")
            debug_node.position = casted_pos
            debug_node.visible = draw_debug_ray
            owner.add_child(debug_node) # Add it as a child of this node.
            # If a collision occurred, color it red
            if result:
                debug_node.modulate = Color(1.0, 0, 0)
            # Otherwise, color it green!
            else:
                debug_node.modulate = Color(0, 1.0, 0)
            
        # If we didn't get fed a result, break! The way is clear, this is our
        # new rotation!
        if not result:
            break;
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step
    
    # Right, now we've got a new rotation - either it's the right way to go or
    # our boid will be turning in a desperate attempt to save itself
    rotation = new_angle

func _input(event):
    if event.is_action_pressed("debug_print"):
        print(rotation)
        print(rotation_degrees)

# An area has entered our detection area
# This might be an attack guide of some sort

# An area has exited our detection area
# This might be an attack guide of some sort

# A physical body has entered our flock detection zone
# This is either another boid, an obstacle, or a projectile

# A physical body has exited our detection zone
# As above, this is either another boid, an obstacle, or a projectile

# Called when the explosion animation has finished; that means it's time to
# remove this boid.
func _on_ExplosionPlayer_animation_finished(anim_name):
    $Explosion.visible = false

# Called when the ExplosionTimer times out; this has been purposefully
# calibrated to occur when the Skin sprite is obscured so we can toggle
# visibility
func _on_ExplosionTimer_timeout():
    $Skin.visible = false

# Called when colliding with another body - be it static, rigid, or kinematic
func _on_Boid_Micro_body_entered(body):
    print("BODY ENTERED!")
    $Explosion.visible = true
    $Explosion/ExplosionTimer.start()
    $Explosion/ExplosionPlayer.play("explode")
