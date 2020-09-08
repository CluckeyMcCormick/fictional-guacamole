extends Spatial

# 134 bpm - set to match "Your Secrets" by SUI UZI
const TWEEN_DURATION = 0.447761194

# Store our angular transforms ahead of time. Each one of these specifies a
# rotation for the text to rotate into
var ALIGN_RIGHT = Transform.IDENTITY.rotated(Vector3.UP, PI / 6)
var ALIGN_LEFT = Transform.IDENTITY.rotated(Vector3.UP, -PI / 6)
var ALIGN_DOWN = Transform.IDENTITY.rotated(Vector3.RIGHT, PI / 6)
var ALIGN_UP = Transform.IDENTITY.rotated(Vector3.RIGHT, -PI / 6)
var ALIGN_UL = ALIGN_LEFT.rotated(Vector3.RIGHT, -PI / 6)
var ALIGN_UR = ALIGN_RIGHT.rotated(Vector3.RIGHT, -PI / 6)
var ALIGN_DL = ALIGN_LEFT.rotated(Vector3.RIGHT, PI / 6)
var ALIGN_DR = ALIGN_RIGHT.rotated(Vector3.RIGHT, PI / 6)
var CENTER = Transform.IDENTITY

# To animate an object rotating between two given rotations, you need to 'slerp'
# between two quaternions. This value tracks our slerp progress, from 0 to 1. 
var quat_step = 0
# What's the quaternion of our origin rotation?
var origin_quat = Quat(CENTER.basis)
# What's the quaternion of our target rotation?
var target_quat = Quat(CENTER.basis)

# What's the transition method we'll be using on our tween? The transition
# method controls the flow of values in the tween, allowing you to make things
# move linearly or bounce
var TWEEN_TRANS = Tween.TRANS_ELASTIC
# What's the easing method we'll be using on our tween? The transition method
# controls the flow into and out of the transition method described above. Think
# of it as the 'acceleration'.
var TWEEN_EASE = Tween.EASE_IN_OUT

# To randomize which position/rotation we're doing, we'll stick all those baked
# rotations into this array. We'll then pop them out one-by-one, ensuring we get
# a round robin rotation of different... rotations.
var choice_rr = [
    ALIGN_RIGHT, ALIGN_LEFT, ALIGN_DOWN, ALIGN_UP, CENTER, ALIGN_UL, ALIGN_DL,
    ALIGN_DR, ALIGN_UR
]

# Called when the node enters the scene tree for the first time.
func _ready():
    # Randomize the current seed
    randomize()
    # Shuffle the array
    choice_rr.shuffle()
    
    # Interpolate quat_step - we'll operate on it at every step
    $BounceTween.interpolate_property(
        self, "quat_step",
        0, 1, # We're slerp'ing between 0 and 1
        TWEEN_DURATION, TWEEN_TRANS, TWEEN_EASE
    )
    $BounceTween.start()


func _on_Tween_tween_step(object, key, elapsed, value):
    # Slerp from the origin quat to the target quat, using our quat step
    var interp_quat = origin_quat.slerp(target_quat, value)
    # Wrap the output Quaternion in a basis and apply it
    $EveryoneDied.transform.basis = Basis( interp_quat )

func _on_BounceTween_tween_completed(object, key):
    # If we're out of prebaked angles...
    if len(choice_rr) == 0:
        # ... then refresh our red robin list!
        choice_rr = [
            ALIGN_RIGHT, ALIGN_LEFT, ALIGN_DOWN, ALIGN_UP, CENTER, ALIGN_UL, ALIGN_DL,
            ALIGN_DR, ALIGN_UR
        ]
        # Don't forget to shuffle it.
        choice_rr.shuffle()
    
    # Now that we're at our target, it has become our origin
    origin_quat = target_quat
    # Our new target is whatever transform is at the back of the round robin
    # list
    target_quat = Quat(choice_rr.pop_back().basis)
    # Reset BounceTween
    $BounceTween.reset_all()
    # Reset quat step. No, the above method doesn't do that, no matter how hard
    # I try.
    quat_step = 0
    $BounceTween.interpolate_property(
        self, "quat_step",
        0, 1, TWEEN_DURATION,
        TWEEN_TRANS, TWEEN_EASE
    )
    $BounceTween.start()
