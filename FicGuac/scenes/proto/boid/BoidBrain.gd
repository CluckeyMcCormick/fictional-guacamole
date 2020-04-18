extends Node2D

# To scan for danger, we'll raycast in front of our boid. But how big is our
# raycast?
# This needs to be constant since other elements of the BoidBrain (Flock &
# Cohesion areas) are directly related to this size
const RAYCAST_MAGNITUDE = 100
# How many points we want to cast, including the central/forward ray. Points are
# measured in a plus-STEP minus-STEP pattern. Ideally, an odd number
export(int) var RAYCAST_STEPS_COUNT = 35 #19
# When we raycast, we cast the points in front of the boid using the unit
# circle. We start in "front" of the Boid, and cast extra points using this step
var RAYCAST_STEP = (2 * PI) / (RAYCAST_STEPS_COUNT - 1)

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
export(int) var DRIVE_SPEED_MIN = 5
export(int) var  DRIVE_SPEED_MAX = 350

# The rate-of-change for _drive_speed; we'll modulate this to either make the
# boid speed up or slow down.
var _drive_accelerate
# What's our default acceleration?
export(int) var DRIVE_DEFAULT_ACCEL = 350
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
export(int) var DRIVE_ROTATIONAL = 12

# What faction are we a part of?
var faction = null

# The container for bodies we are currently tracking as our "flock"
var flock_members = {}
# The container for bodies we are currently tracking for the purposes of
# cohesion
var cohesion_members = {}

# Get the global variables - these will have the scalars for our 3 input factors
onready var boid_globals = get_node("/root/BoidGlobals")

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
            
# Sets the boid to TRULY boid mode
func set_mode_boid(boid_body):
    boid_body.set_collision_layer_bit(1, true)
    boid_body.set_collision_layer_bit(0, false)
    boid_body.set_collision_mask_bit(1, false)
    boid_body.set_collision_mask_bit(0, true)
    if show_guide_vector:
        guide_vector_sprite.visible = true

# Sets the boid to obstacle mode
func set_mode_obstacle(boid_body):
    boid_body.set_collision_layer_bit(1, false)
    boid_body.set_collision_layer_bit(0, true)
    boid_body.set_collision_mask_bit(1, true)
    boid_body.set_collision_mask_bit(0, false)
    if show_guide_vector:
        guide_vector_sprite.visible = false

func deactivate():
    # Disable the flock area
    $FlockArea.monitorable = false
    $FlockArea.monitoring = false
    # Disable the danger area
    $DangerArea.monitorable = false
    $DangerArea.monitoring = false
    # Disable the cohesion area
    $CohesionArea.monitorable = false
    $CohesionArea.monitoring = false

func activate():
    # Enable the flock area
    $FlockArea.monitorable = true
    $FlockArea.monitoring = true
    # Enable the danger area
    $DangerArea.monitorable = true
    $DangerArea.monitoring = true
    # Enable the cohesion area
    $CohesionArea.monitorable = true
    $CohesionArea.monitoring = true

#
# !--> Driving Functions
#
func boid_physics_process(delta):
    # Set the new drive speed, then clamp the result
    _drive_speed = _drive_speed + (_drive_accelerate * delta)
    _drive_speed = clamp( _drive_speed, DRIVE_SPEED_MIN, DRIVE_SPEED_MAX)

func boid_integrate_forces(body_state):
    # TODO: Actually remember how weighted averaging works
    
    var guide_vector = Vector2(RAYCAST_MAGNITUDE, 0)
    
    # Get the boid's globalized scalar values
    var avoid_scale = boid_globals.avoidance
    var align_scale = boid_globals.alignment
    var cohes_scale = boid_globals.cohesion
    
    # Catch the scale in case it's too small
    if avoid_scale <= 0:
        avoid_scale = boid_globals.SCALAR_MIN
    if align_scale <= 0:
        align_scale = boid_globals.SCALAR_MIN
    if cohes_scale <= 0:
        cohes_scale = boid_globals.SCALAR_MIN       
    
    guide_vector = avoid_scale * calculate_avoidance_vector(body_state) #* .9
    guide_vector += align_scale * calculate_alignment_vector(body_state) #* .875 #* .75
    guide_vector += cohes_scale * calculate_cohesion_vector(body_state) #* .125 #* .25
    
    #guide_vector /= avoid_scale + align_scale + cohes_scale
    
    # If we're showing a threat vector, set the position to the threat sum
    if show_guide_vector:
        guide_vector_sprite.global_position = owner.global_position + (guide_vector * .5)
    
    # So now we have a summed-up threat vector that's telling us which way to
    # go. Let's find out how much we have to turn - that will inform our
    # decision making
    var turn_angle = self.get_angle_to(owner.global_position + guide_vector)
    # We need to scale our torque (rotational force) so that we don't radically
    # overshoot the angle we need to turn to. Our angle should either be between
    # 0 & -PI or 0 & PI. Either way, we'll never have to go longer than an arc
    # length of PI - so set the turn force as a percentage of PI
    var angular_velo = DRIVE_ROTATIONAL * (turn_angle / PI)
    
    # Our velocity is determined by our drive speed, which is calculated in
    # boid_physics_process
    var linear_velo = Vector2(_drive_speed, 0).rotated(owner.rotation)
    
    # Calculate the acceleration as a percentage of PI
    _drive_accelerate = DRIVE_DEFAULT_ACCEL
    _drive_accelerate *= 1 - ( abs(turn_angle) / PI )
    
    if show_boid_path:
        var debug_node = X_SPRITE_SCENE.instance() # Create a new sprite!
        debug_node.position = global_position
        owner.owner.add_child(debug_node) # Add it as a child of the parent node's parent
    
    # Return the linear velocity and angular velocity as a sort of pseudo-tuple.
    # Whoever owns this brain can do whatever they want with this information
    return [linear_velo, angular_velo]

func calculate_avoidance_vector(body_state):
    var space_state = body_state.get_space_state()
    var threat_sum = Vector2(0, 0)
    var ray_step = 0
    
    for i in range(RAYCAST_STEPS_COUNT):
        # Calculate our current angle
        var curr_angle = owner.rotation + (ray_step * RAYCAST_STEP)
        
        # Calculate the raycasted/shifted point
        var casted_pos = Vector2(RAYCAST_MAGNITUDE, 0).rotated(curr_angle)
        casted_pos += owner.global_position
        
        # We do want to exclude some items - starting with our flock
        var excludes = flock_members.values()
        # Okay, if that had no values, default to an empty array
        if not excludes:
            excludes = []
        # We obviously want to exclude ourselves
        excludes.append(owner)
        
        # Get the result of our collision raycast
        var result = space_state.intersect_ray(owner.global_position, casted_pos, excludes)

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
                owner.owner.add_child(debug_node) # Add it as a child of this node.
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
            var new_threat_vec = result.position - owner.global_position
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
    # Create a blank vector for us to add to
    var align_sum = Vector2.ZERO
    
    # If we don't have any flock members, back out now. Otherwise, we might
    # divide by zero, get a NAN vector, and then everything would be REALLY bad
    if flock_members.size() <= 0:
        return align_sum
    
    # For each boid in flock members...
    for flock_boid in flock_members.values():
        # Create a standard "forward" vector
        var rotated_alignment = Vector2(1, 0)
        # Rotate it by this boid's heading
        rotated_alignment = rotated_alignment.rotated( flock_boid.rotation )
        # Add that to our "blank" vector
        align_sum += rotated_alignment
        
    # Divide the total vector by the boid count to get the "average" alignment
    # vector
    align_sum /= flock_members.size()
    
    # Send it!
    return align_sum
       
func calculate_cohesion_vector(body_state):
    # Create a blank vector for us to add to
    var cohesion_sum = Vector2.ZERO
    
    # If we don't have any cohesion members, back out now. Otherwise, we might
    # divide by zero, get a NAN vector, and then everything would be REALLY bad
    if cohesion_members.size() <= 0:
        return cohesion_sum
    
    # For each boid in cohesion-flock members...
    for coho_boid in cohesion_members.values():
        # Calculate the vector from brain-boid to current-cohesion-boid, add it
        # to our "blank" vector
        cohesion_sum += coho_boid.global_position - owner.global_position
        
    # Divide the total vector by the boid count to get the "average" cohesion
    # position vector
    cohesion_sum /= cohesion_members.size()
    
    # Send it!
    return cohesion_sum

#
# !--> Singal Functions
#

# A physical body has entered our flock detection zone
# That means it was on the boid layer...
func _on_FlockArea_body_entered(body):
    # Ensure that both us and the body have a faction
    if not self.get("faction") or not body.get("faction"):
        return
    # If the other body's faction isn't friendly with ours, exit
    if not self.faction.is_friendly(body.faction):
        return
    # Stuff it in the dict
    flock_members[body.name] = body

func _on_DangerArea_body_entered(body):
    # Remove the body, if applicable
    flock_members.erase(body.name)
    
# We track flock members to cohese with  
func _on_CohesionArea_body_entered(body):
    # Ensure that both us and the body have a faction
    if not self.get("faction") or not body.get("faction"):
        return
    # If the other body's faction isn't friendly with ours, exit
    if not self.faction.is_friendly(body.faction):
        return
    # Stuff it in the dict
    cohesion_members[body.name] = body

# A physical body has exited our detection zone
# As above, this is either another boid, an obstacle, or a projectile
func _on_DangerArea_body_exited(body):
    # Ensure that both us and the body have a faction
    if not self.get("faction") or not body.get("faction"):
        return
    # If the other body's faction isn't friendly with ours, exit
    if not self.faction.is_friendly(body.faction):
        return
    # Stuff it in the dict
    flock_members[body.name] = body

func _on_FlockArea_body_exited(body):
    # Remove the body, if applicable
    flock_members.erase(body.name)

func _on_CohesionArea_body_exited(body):
    # Remove the body, if applicable
    cohesion_members.erase(body.name)
