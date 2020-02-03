extends RigidBody2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast? These constants will help to define that.
# Our length for each raycast
const RAYCAST_MAGNITUDE = 30
# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern.
const RAYCAST_STEPS_COUNT = 15
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

const ARTI_ACCEL = 50
const MAX_SPEED = 250

var _arti_speed
var _target_rotation

# The container zfor bodies we are currently tracking as our "flock"
var flock_members = {}

# The container for bodies we are currently tracking as our "dangers"
var obstacle_members = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    var ray_step
    var new_angle
    _arti_speed = 0
    
    if not show_cast_points:
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
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        add_child(debug_node) # Add it as a child of this node.
        debug_node.position = casted_pos
        
        if new_angle < -RAYCAST_LRC_RADS:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.LEFT)
        elif new_angle > RAYCAST_LRC_RADS:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.RIGHT)
        else:
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.CENTER)
        
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
    
    # We have four quadrants that we evaluate - left, center left, center right,
    # and right. Anything in the "center" categories is something we WILL hit if
    # we continue on our current trajectory, so priority is given to avoiding
    # collisions in those areas
    var left_blocked = false
    var cen_left_blocked = false
    var cen_right_blocked = false
    var right_blocked = false
    
    ray_step = 0
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        var curr_angle = self.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(0, 0)
        casted_pos.x = cos(curr_angle)
        casted_pos.y = sin(curr_angle)
        casted_pos *= RAYCAST_MAGNITUDE
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
            # Special case when ray step is 0
            if ray_step == 0:
                cen_left_blocked = true
                cen_right_blocked = true
            # CENTER LEFT
            elif is_center and is_left:
                cen_left_blocked = true
            # CENTER RIGHT
            elif is_center and not is_left:
                cen_right_blocked = true
            # LEFT
            elif not is_center and is_left:
                left_blocked = true
            # RIGHT
            elif not is_center and not is_left:
                right_blocked = true
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step

    # If the left center is blocked, but not the right center...    
    if cen_left_blocked and not cen_right_blocked:
        # Then we need to rotate towards the center of center right
        _target_rotation = self.rotation + (RAYCAST_LRC_RADS / 2)
    # If the right center has a collision, but the left center is open...
    elif cen_right_blocked and not cen_left_blocked:
        # Then we need to do the same as above - but with the left!
        _target_rotation = self.rotation - (RAYCAST_LRC_RADS / 2)
    # Otherwise, if the whole center is blocked...
    elif cen_left_blocked and cen_right_blocked:
        # Then we need to pick either the left or right quadrants
        
        # Let's calculate the angle addition we'll use real quick - reuse ray_step!
        # First, calculate the radian arc size for the post-LRC arc
        ray_step = (PI / 2) - RAYCAST_LRC_RADS
        # Then, cut it in half to get the middle
        ray_step /= 2
        # Finally, shift it past the LRC line
        ray_step += RAYCAST_LRC_RADS
        
        # If left is blocked, but right is open,
        if left_blocked and not right_blocked:
            _target_rotation = self.rotation + ray_step
        # Otherwise, if right is closed but the left is clear
        elif right_blocked and not left_blocked:
            _target_rotation = self.rotation - ray_step
        # Otherwise, if both are clear and open
        elif not left_blocked and not right_blocked:
            if randi() % 2 == 0:
                _target_rotation = self.rotation + ray_step
            else:
                _target_rotation = self.rotation - ray_step
        # Otherwise, both must be closed - That means literally everything in
        # front of us is death - we need a full reverse!
        else:
            _target_rotation = self.rotation + PI
    # Otherwise, the way forward is clear. We don't need to turn at all
    else:
        _target_rotation = self.rotation
        
    rotation = _target_rotation

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
