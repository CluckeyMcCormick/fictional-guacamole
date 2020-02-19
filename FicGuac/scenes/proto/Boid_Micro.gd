extends RigidBody2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast?
const RAYCAST_MAGNITUDE = 100

# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern. Ideally, an odd number
const RAYCAST_STEPS_COUNT = 19
# When we raycast, we cast the points in front of the boid using the unit
# circle. We start in "front" of the Boid, and cast extra points using this step
const RAYCAST_STEP = (2 * PI) / (RAYCAST_STEPS_COUNT - 1)

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
# Shall we show the sample points that we are casting to?
export(bool) var show_cast_points
var _cast_points = []
# Shall we leave a path to show where the boid has been?
export(bool) var show_boid_path
# Shall we display a point representing our threat vector?
export(bool) var show_guide_vector
var guide_vector_sprite

# The torque/rotation force that we'll use to rotate the boid
const ROT_TORQUE = 250

# Our maximum driving force; if we encounter no obstacles, this will be our 
const DRIVE_FORCE_MAX = 125
const DRIVE_FORCE_MIN = -250

# What is our current speed?
var _arti_speed
# What is our current raycast magnitude?
var _raycast_mag
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
    _raycast_mag = RAYCAST_MAGNITUDE
    
    if show_cast_points:
        ray_step = 0
        for i in range(RAYCAST_STEPS_COUNT):
            # Calculate our current angle
            new_angle = ray_step * RAYCAST_STEP
            
            # Calculate the raycasted/shifted point
            var casted_pos = Vector2(_raycast_mag, 0).rotated(new_angle)
                    
            # Add a point at the shifted location
            var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
            add_child(debug_node) # Add it as a child of this node.
            debug_node.position = casted_pos
            debug_node.set_color(X_SPRITE_SCRIPT.X_CLASSES.CAST_POINT)
            
            # Throw it all into our array
            _cast_points.append( debug_node )
            
            # Otherwise, update our step for the next go-around
            if i % 2 == 0:
                ray_step = abs(ray_step) + 1
            else:
                ray_step = -ray_step

    if show_guide_vector:
        # Add a point at the shifted location
        guide_vector_sprite = Sprite.new() # Create a new sprite!
        guide_vector_sprite.texture = load("res://assets/circle.png")
        add_child(guide_vector_sprite) # Add it as a child of this node.
        guide_vector_sprite.position = Vector2.ZERO
        guide_vector_sprite.modulate = Color.royalblue
        guide_vector_sprite.scale = Vector2(1, 1) * 0.05

func _integrate_forces(body_state):
    # Skip if dead
    if _dead:
        return
    
    var space_state = body_state.get_space_state()
    var threat_sum = Vector2.ZERO
    var ray_step = 0
    
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        var curr_angle = self.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(_raycast_mag, 0).rotated(curr_angle)
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
            # We want to know which direction to go - in theory, we should just
            # go opposite of the collision. So, let's first convert the position
            # into a vector originating from the boid
            var new_threat_vec = result.position - global_position
            # We want to scale the threat vector, such that threat vectors are
            # given more weight the closer they get to the boid - so scale the
            # vector by the inverse percentage
            new_threat_vec *= 1 - (new_threat_vec.length() / RAYCAST_MAGNITUDE )
            # Now, since we want the boid to head in the opposite direction of
            # this threat, invert the vector
            new_threat_vec *= -1
            # Add our newly baked threat vector to the pile
            threat_sum += new_threat_vec
        
        # Otherwise, update our step for the next go-around
        if i % 2 == 0:
            ray_step = abs(ray_step) + 1
        else:
            ray_step = -ray_step
    
    # If we're showing a threat vector, set the position to the threat sum
    if show_guide_vector:
        guide_vector_sprite.global_position = global_position + threat_sum
    
    # So now we have a summed-up threat vector that's telling us which way to
    # go. Let's find out how much we have to turn - that will inform our
    # decision making
    var turn_angle = self.get_angle_to(global_position + threat_sum)
    # We need to scale our torque (rotational force) so that we don't radically
    # overshoot the angle we need to turn to. Our angle should either be between
    # 0 & -PI or 0 & PI. Either way, we'll never have to go longer than an arc
    # length of PI - so set the turn force as a percentage of PI
    set_applied_torque( ROT_TORQUE * (turn_angle / PI) )

    
    var drive = DRIVE_FORCE_MAX 
    drive *= 1 - ( abs(turn_angle) / (PI / 6) )
    #drive *= 1 - ( abs(turn_angle) / RAYCAST_LRC_RADS )
    drive = clamp( drive, DRIVE_FORCE_MIN, DRIVE_FORCE_MAX)
    set_applied_force( Vector2(drive, 0).rotated(rotation) )
    
    if show_boid_path:
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        debug_node.position = position
        owner.add_child(debug_node) # Add it as a child of the parent node
        
func _physics_process(delta):
    # Skip if dead
    if _dead:
        return

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
    # Clear the applied force
    set_applied_torque(0)
    set_applied_force( Vector2.ZERO )
    # Make ourselves explode
    $Explosion.visible = true
    $Explosion/ExplosionTimer.start()
    $Explosion/ExplosionPlayer.play("explode")
