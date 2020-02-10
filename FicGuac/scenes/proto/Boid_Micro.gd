extends RigidBody2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast? These constants will help to define that.
# The length for each raycast at no speed
const MIN_RAYCAST_MAGNITUDE = 30
# Our length for each raycast at full speed
const MAX_RAYCAST_MAGNITUDE = 100

# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern. Ideally, an odd number
const RAYCAST_STEPS_COUNT = 25
# When we raycast, we cast the points in front of the boid using the unit
# circle. We start in "front" of the Boid, and cast extra points using this step
const RAYCAST_STEP = PI / (RAYCAST_STEPS_COUNT - 1)
# Left-Right-Center dividing line. For making a pathing decision, we divide our
# rays into three groups - Left, Right, and Center. The rays that are less than
# (rotation - RAYCAST_LRC_RADS) are left, the rays that are greater than
# (rotation + RAYCAST_LRC_RADS) are right, and those rays between those points
# are center
const RAYCAST_LRC_RADS = (3 * PI) / 14 # Appropriate "Forward" range for a microboid

# Packed scene, used for debug and collision marking. Has convenience routines
# for setting colors and removing itself.
var X_SPRITE_SCENE = load("res://scenes/proto/X_Sprite.tscn")
# Need the script to access the sprite color enums
var X_SPRITE_SCRIPT = load("res://scenes/proto/X_Sprite.gd")
# The lifetime (in seconds) of debug sprites used to mark non-collisions
const X_SPRITE_COLLISION_LIFETIME = 25
# The lifetime (in seconds) of debug sprites used to mark non-collisions
const X_SPRITE_NO_COLLIDE_LIFETIME = 2

# Some configurable debug variables, makes all our lives easier
enum RAYCAST_DEBUG {none, only_collisions, all}
export(RAYCAST_DEBUG) var show_cast_result
export(bool) var show_cast_points
export(bool) var show_boid_path
var _cast_points = []

const ARTI_ACCEL = 50
const MAX_SPEED = 300
# Our maximum rotation speed - since this operates inversely to linear speed,
# this is our rotation speed at a linear speed of 0
const MAX_ROT_SPEED = (5 * PI) / 2
# Minimum rotation speed - which we'll hit at max linear speed
const MIN_ROT_SPEED = (16 * PI) / 8

# What is our current speed?
var _arti_speed
# What is our current raycast magnitude?
var _raycast_mag
# Which direction are we turning? Left is negative, Right is positive, Straight
# Ahead is 0.
var _turn_dir = 0
# Are we dead? Did we die?
var _dead = false

# The container zfor bodies we are currently tracking as our "flock"
var flock_members = {}

# The container for bodies we are currently tracking as our "dangers"
var obstacle_members = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    var ray_step
    var new_angle
    _arti_speed = 0
    _raycast_mag = MIN_RAYCAST_MAGNITUDE
    
    if not show_cast_points:
        return
        
    ray_step = 0
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        new_angle = ray_step * RAYCAST_STEP
        
        # Calculate the raycasted/shifted point
        var uncasted_pos = Vector2(0, 0)
        uncasted_pos.x = cos(new_angle)
        uncasted_pos.y = sin(new_angle)
        
        # Add a point at the shifted location
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        add_child(debug_node) # Add it as a child of this node.
        debug_node.position = uncasted_pos * _raycast_mag
        debug_node.uncasted_pos = uncasted_pos
        
        # If we haven't crossed the LRC line yet, then we're still in the center
        var is_center = RAYCAST_LRC_RADS > abs(ray_step * RAYCAST_STEP)
        # If our step is negative, then we're probing the left
        var is_left = ray_step < 0
        
        if is_center:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.CENTER)
        elif is_left:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.LEFT)
        else:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.RIGHT)
        
        # Throw it all into our array
        _cast_points.append( debug_node )
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # Skip if dead
    if _dead:
        return
    
    # Calculate the rotational velocity
    var rota_velo = clamp(
        MAX_ROT_SPEED * ( 1 - (_arti_speed / MAX_SPEED) ),
        MIN_ROT_SPEED, MAX_ROT_SPEED
    )
    # Turn as specified by our turn direction
    rotation += _turn_dir * (rota_velo * delta)
    
    # Add our newly recieved acceleration
    _arti_speed = clamp(_arti_speed + (ARTI_ACCEL * delta), 0, MAX_SPEED)
    # Calculate the new raycast magnitude 
    var new_mag = clamp(
        MAX_RAYCAST_MAGNITUDE * (_arti_speed / MAX_SPEED),
        MIN_RAYCAST_MAGNITUDE, MAX_RAYCAST_MAGNITUDE
    )
    # If the raycast magnitude is different, we need to adjust the magnitude
    # and the debug points
    if new_mag != _raycast_mag:
        _raycast_mag = new_mag
        if RAYCAST_DEBUG:
            # Then we need to move up the points
            for debug_node in _cast_points:
                debug_node.position = debug_node.uncasted_pos * _raycast_mag
    
    # Calculate our movement, given heading, speed, and time delta
    var movement = Vector2(0, 0)
    movement.x = cos(rotation)
    movement.y = sin(rotation)
    movement *= _arti_speed
    movement *= delta
    
    self.position = self.position + movement
    
    if show_boid_path:
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        debug_node.position = position
        owner.add_child(debug_node) # Add it as a child of the parent node
        
func _physics_process(delta):
    # Skip if dead
    if _dead:
        return
    
    var space_state = get_world_2d().direct_space_state
    var ray_step
    
    # We have four quadrants that we evaluate - left, center left, center right,
    # and right. Anything in the "center" categories is something we WILL hit if
    # we continue on our current trajectory, so priority is given to avoiding
    # collisions in those areas
    var left_blocked = 0
    var cen_left_blocked = 0
    var cen_right_blocked = 0
    var right_blocked = 0
    
    ray_step = 0
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        var curr_angle = self.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(0, 0)
        casted_pos.x = cos(curr_angle)
        casted_pos.y = sin(curr_angle)
        casted_pos *= _raycast_mag
        casted_pos += global_position
        
        # Get the result of our collision raycast
        var result = space_state.intersect_ray(global_position, casted_pos, [self])

        # Render our collision, depending on whether we've enabled the debug or not
        match show_cast_result:
            RAYCAST_DEBUG.none:
                pass
            RAYCAST_DEBUG.only_collisions, RAYCAST_DEBUG.all:
                if !result and show_cast_result == RAYCAST_DEBUG.only_collisions:
                    continue
                # Add a point at the shifted location
                var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
                if result:
                    debug_node.position = result.position
                else:
                    debug_node.position = casted_pos
                owner.add_child(debug_node) # Add it as a child of this node.
                # Color the collision appropriately
                if result:
                    debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.COLLIDE)
                    debug_node.start_timer(X_SPRITE_COLLISION_LIFETIME)
                else:
                    debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.NO_COLLIDE)
                    debug_node.start_timer(X_SPRITE_NO_COLLIDE_LIFETIME)
        
        # If we got a collision, we need to register it
        if result:
            # If we haven't crossed the LRC line yet, then we're still in the center
            var is_center = RAYCAST_LRC_RADS > abs(ray_step * RAYCAST_STEP)
            # If our step is negative, then we're probing the left
            var is_left = ray_step < 0
            # Calculate the length of this
            # Special case when ray step is 0
            if ray_step == 0:
                cen_left_blocked += 1
                cen_right_blocked += 1
            # CENTER LEFT
            elif is_center and is_left:
                cen_left_blocked += 1
            # CENTER RIGHT
            elif is_center and not is_left:
                cen_right_blocked += 1
            # LEFT
            elif not is_center and is_left:
                left_blocked += 1
            # RIGHT
            elif not is_center and not is_left:
                right_blocked += 1
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step

    # If the left center is blocked, but not the right center...    
    if cen_left_blocked > 0 and cen_right_blocked <= 0:
        # Then we need to rotate towards the center of center right
        _turn_dir = 1
    # If the right center has a collision, but the left center is open...
    elif cen_right_blocked > 0 and cen_left_blocked <= 0:
        # Then we need to do the same as above - but with the left!
        _turn_dir = -1
    # Otherwise, if the whole center is blocked...
    elif cen_left_blocked > 0 and cen_right_blocked > 0:
        # Then we need to pick either the left or right quadrants
        # If left is blocked, but right is open,
        if left_blocked > 0 and right_blocked <= 0:
            _turn_dir = 1
        # Otherwise, if right is closed but the left is clear
        elif right_blocked > 0 and left_blocked <= 0:
            _turn_dir = -1
        else:
            # Right, so now we KNOW that everything is blocked - but to what
            # degree? Let's choose the least blocked - left or right?
            # If the left is least blocked, turn left.
            if left_blocked < right_blocked:
                _turn_dir = -1
            # If the right is least blocked, turn right.
            elif right_blocked < left_blocked:
                _turn_dir = 1
            # Otherwise - they're both equal?!?! Oh to hell with it - flip a
            # coin and see which direction to go
            elif randi() % 2 == 0:
                _turn_dir = 1
            else:
                _turn_dir = -1
    # Otherwise, the way forward is clear. We don't need to turn at all
    else:
        _turn_dir = 0

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
    # $Skin.visible = false
    $Skin.modulate = Color(0, 0, 0)

# Called when colliding with another body - be it static, rigid, or kinematic
func _on_Boid_Micro_body_entered(body):
    # If we died, we don't want to do anything
    if _dead:
        return
    # We're dead. We died.
    _dead = true
    # Convert our artificial speed and rotational velocity into physics-end
    # velocity and rotation
    self.linear_velocity = Vector2( cos(rotation), sin(rotation) ) * _arti_speed
    # Calculate the rotational/angular velocity
    var rota_velo = clamp(
        MAX_ROT_SPEED * ( 1 - (_arti_speed / MAX_SPEED) ),
        MIN_ROT_SPEED, MAX_ROT_SPEED
    )
    # Turn as specified by our turn direction
    self.angular_velocity = _turn_dir * rota_velo
    # Make ourselves explode
    $Explosion.visible = true
    $Explosion/ExplosionTimer.start()
    $Explosion/ExplosionPlayer.play("explode")
