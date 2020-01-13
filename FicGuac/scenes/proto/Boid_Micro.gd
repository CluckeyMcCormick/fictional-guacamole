extends RigidBody2D

# The container for bodies we are currently tracking as our "flock"
var flock_members = {}

# The container for bodies we are currently tracking as our "dangers"
var obstacle_members = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

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
