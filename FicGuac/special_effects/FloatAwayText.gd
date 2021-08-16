extends "res://special_effects/DynamicSpriteText.gd"

# How fast do we float away, in units/second?
export(float) var float_velocity = 1.0
# We float up for a certain duration before starting our disappear animation.
# How long does this message "live" for?
export(float, 0.01, 30, 0.01) var life_timer = 1.5
# Once we've hit the end of the "life" timer, we start to disappear. How long
# does the disappearing animation last?
export(float, 0.01, 30, 0.01) var fade_away_timer = .5

# Called when the node enters the scene tree for the first time.
func _ready():
    $LifeTimer.start(life_timer)

func _physics_process(delta):
    # Move ourselves up by using our velocity and the time delta
    self.translate(Vector3(0, float_velocity * delta, 0))

func _on_LifeTimer_timeout():
    # Shrink ourselves.
    $FadeAwayTween.interpolate_property(
        self, # Target
        "scale", # Target Property
        self.scale, # Initial Value
        Vector3.ZERO, # Final Value
        fade_away_timer, # Duration,
        $FadeAwayTween.TRANS_SINE # Transition type
    )
    # Start the shrinking
    $FadeAwayTween.start()

func _on_FadeAwayTween_tween_all_completed():
    # Now that we've "disappeared", remove ourselves from the scene tree
    self.get_parent().remove_child(self)
    # Destroy ourselves
    self.queue_free()
