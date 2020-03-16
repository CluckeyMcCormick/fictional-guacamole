extends RigidBody2D

# Are we dead? Did we die?
var _dead = false

# What faction are we a part of?
var faction = null

#
# !--> Ready, Process, and Miscellaneous Functions
#

# Called when the node enters the scene tree for the first time.
func _ready():
    # Assert the team
    $BoidBrain.set_mode_boid(self)

func _input(event):
    if event.is_action_pressed("debug_print"):
        print(rotation)
        print(rotation_degrees)

# Kills the boid, playing the animation and doing any other necessary actions
func die():
    # We're dead. We died.
    _dead = true
    
    # Change the team to none. Because we died.
    $BoidBrain.set_mode_obstacle(self)
    
    # Null out our present-level faction and brain-level faction
    set_faction(null)
    
    # Set our layers up so that we're an obstacle
    # Make ourselves explode
    $Explosion.visible = true
    $Explosion/ExplosionTimer.start()
    $Explosion/ExplosionPlayer.play("explode")
    
    # Turn off the boid brain so it's no longer doing flock operations 
    $BoidBrain.deactivate()
    # Turn off contact monitoring - now that we're dead, there's no need to
    # monitor our body
    self.contact_monitor = false

func set_faction(faction_node):
    self.faction = faction_node
    $BoidBrain.faction = faction_node

#
# !--> Driving Functions
#
func _integrate_forces(body_state):
    # Skip if dead
    if _dead:
        return
    # Get the result of integrating forces on the BoidBrain
    var integrate_array = $BoidBrain.boid_integrate_forces(body_state)
    # Set the linear velocity
    self.set_linear_velocity(integrate_array[0])
    # Set the angular velocity
    self.set_angular_velocity(integrate_array[1])
    
func _physics_process(delta):
    # Skip if dead
    if _dead:
        return
    # Perform any necessary processing for our boid. Doesn't return anything
    $BoidBrain.boid_physics_process(delta)

#
# !--> Singal Functions
#

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
    # If the body has a faction and it's friendly with ours, the do nothing
    if body.get("faction") and not self.faction.is_friendly(body.faction):
        return
    
    # Otherwise - DIE!
    self.die()
