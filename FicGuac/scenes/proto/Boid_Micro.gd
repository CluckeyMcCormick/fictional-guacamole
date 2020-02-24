extends RigidBody2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast?
const RAYCAST_MAGNITUDE = 100
# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern. Ideally, an odd number
const RAYCAST_STEPS_COUNT = 35#19
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

# The boid can only move "forward" (to it's current rotation) - but how fast is
# the boid currently moving?
var _drive_speed
# Our minimum and maximum speed - we will default to minimum speed
const DRIVE_SPEED_MIN = 5
const DRIVE_SPEED_MAX = 350

# The rate-of-change for _drive_speed; we'll modulate this to either make the
# boid speed up or slow down.
var _drive_accelerate
# What's our default acceleration?
const DRIVE_DEFAULT_ACCEL = 350
# We set the acceleration like so: we take DRIVE_DEFAULT_ACCEL and we multiply
# it by a percentage. That percentage is derived from our "angle_to" the ideal
# heading divided by this value, all subtracted from one. 
# As an example, let's say this value is PI. That means, if our "angle_to" the
# ideal heading was 0, we would go 100% of DRIVE_DEFAULT_ACCEL. If "angle_to"
# was PI / 2, it would 50%. And, if "angle_to" was PI, it would be 0%.
# This constant, then, acts as the angular acceleration threshold - turns with
# an arc beyond this size will cause the boid to slow down more and more. So, a
# lower value of PI (i.e. PI / 6) will cause the boid to slow down more heavily
# for turns
const DRIVE_ACCEL_ARC = PI / 6

# When we need to turn, we'll set the angular velocity to (at most) this value
# Anywhere from 12 to 15... units seems to work pretty well
const DRIVE_ROTATIONAL = 12

# Are we dead? Did we die?
var _dead = false

# What team are we on?
var boid_team = "Best Boids"
# The container for bodies we are currently tracking as our "flock"
var flock_members = {}

#
# !--> Ready, Process, and Miscellaneous Functions
#

# Called when the node enters the scene tree for the first time.
func _ready():
    var ray_step
    var new_angle
    
    _drive_speed = DRIVE_SPEED_MIN
    _drive_accelerate = DRIVE_DEFAULT_ACCEL
    
    if show_cast_points:
        ray_step = 0
        for i in range(RAYCAST_STEPS_COUNT):
            # Calculate our current angle
            new_angle = ray_step * RAYCAST_STEP
            
            # Calculate the raycasted/shifted point
            var casted_pos = Vector2(RAYCAST_MAGNITUDE, 0).rotated(new_angle)
                    
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

func _input(event):
    if event.is_action_pressed("debug_print"):
        print(rotation)
        print(rotation_degrees)

# Kills the boid, playing the animation and doing any other necessary actions
func die():
    # We're dead. We died.
    _dead = true
    
    # Change our collision layer. Now that we're dead, we're no longer a boid -
    # we are merely an obstacle
    set_collision_layer_bit(1, false)
    set_collision_layer_bit(0, true)
    
    if show_guide_vector:
        guide_vector_sprite.visible = false
    
    # Set our layers up so that we're an obstacle
    # Make ourselves explode
    $Explosion.visible = true
    $Explosion/ExplosionTimer.start()
    $Explosion/ExplosionPlayer.play("explode")
#
# !--> Driving Functions
#
func _integrate_forces(body_state):
    # Skip if dead
    if _dead:
        return
    
    var guide_vector = Vector2(RAYCAST_MAGNITUDE, 0)
    guide_vector = calculate_avoidance_vector(body_state)
    
    # If we're showing a threat vector, set the position to the threat sum
    if show_guide_vector:
        guide_vector_sprite.global_position = global_position + guide_vector
    
    # So now we have a summed-up threat vector that's telling us which way to
    # go. Let's find out how much we have to turn - that will inform our
    # decision making
    var turn_angle = self.get_angle_to(global_position + guide_vector)
    # We need to scale our torque (rotational force) so that we don't radically
    # overshoot the angle we need to turn to. Our angle should either be between
    # 0 & -PI or 0 & PI. Either way, we'll never have to go longer than an arc
    # length of PI - so set the turn force as a percentage of PI
    set_angular_velocity( DRIVE_ROTATIONAL * (turn_angle / PI) )
    
    _drive_accelerate = DRIVE_DEFAULT_ACCEL
    _drive_accelerate *= 1 - ( abs(turn_angle) / PI )
    set_linear_velocity( Vector2(_drive_speed, 0).rotated(rotation) )
    
    if show_boid_path:
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        debug_node.position = position
        owner.add_child(debug_node) # Add it as a child of the parent node

func calculate_avoidance_vector(body_state):
    var space_state = body_state.get_space_state()
    var threat_sum = Vector2(0, 0)
    var ray_step = 0
    
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        var curr_angle = self.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(RAYCAST_MAGNITUDE, 0).rotated(curr_angle)
        casted_pos += global_position
        
        # We do want to exclude some items - starting with our flock
        var excludes = flock_members.values()
        # Okay, if that had no values, default to an empty array
        if not excludes:
            excludes = []
        # We obviously want to exclude ourselves
        excludes.append(self)
        
        # Get the result of our collision raycast
        var result = space_state.intersect_ray(global_position, casted_pos, excludes)

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
            
    return threat_sum

func calculate_alignment_vector(body_state):
    
    var alignment_sum = Vector2(0, 0)
    
       
func calculate_cohesion_vector(body_state):
    pass
    
func _physics_process(delta):
    # Skip if dead
    if _dead:
        return
    
    # Set the new drive speed, then clamp the result
    _drive_speed = _drive_speed + (_drive_accelerate * delta)
    _drive_speed = clamp( _drive_speed, DRIVE_SPEED_MIN, DRIVE_SPEED_MAX)

#
# !--> Singal Functions
#

# An area has entered our detection area
# This might be an attack guide of some sort

# An area has exited our detection area
# This might be an attack guide of some sort

# A physical body has entered our flock detection zone
# That means it was on the boid layer...
func _on_DangerFlock_body_entered(body):
    # Get the other body's boid_team
    var other_boid_team = body.get("boid_team")
    # If the boid team doesn't match ours, we're done here
    if other_boid_team != boid_team:
        return
    # Stuff it in the dict
    flock_members[body.name] = body

# A physical body has exited our detection zone
# As above, this is either another boid, an obstacle, or a projectile
func _on_DangerFlock_body_exited(body):
    # Remove the body, if applicable
    flock_members.erase(body.name)

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
    # Get the other body's boid_team
    var other_boid_team = body.get("boid_team")
    # If it matches ours, then we're done. We ignore same-team collisions
    if other_boid_team == boid_team:
        return
    # Otherwise - DIE!
    self.die()
