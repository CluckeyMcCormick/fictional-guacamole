extends Spatial

const FIRE_DIAMOND = preload("res://special_effects/particles/FireDiamond32.tscn")

const START_VALUE = -3.5
const END_VALUE = 4
const INCREMENT = 1

const SPIN_TIME = 30

# 
var x = START_VALUE
var y = 0.5
var z = START_VALUE

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_Timer_timeout():
    var new_fire = FIRE_DIAMOND.instance()
    
    $MeshInstance/FireMount.add_child(new_fire)
    new_fire.translation = Vector3(x, y, z)
    
    x += INCREMENT
    
    if x > END_VALUE:
        x = START_VALUE
        z += INCREMENT
    
    if z > END_VALUE:
        $Timer.stop()
        _on_Tween_tween_completed(null, ":translation:x")

func _on_Tween_tween_completed(object, key):
    print(object, "|<-->|", str(key))
    
    # Clean all the tweens
    $Tween.remove_all()
    
    # Reset the platform
    $MeshInstance.translation = Vector3(0, -1, 0)

    # Now we need to do different TWEENS based on the tween we just completed.
    match str(key):
        ":translation:x":
            $Tween.interpolate_property(
                $MeshInstance, "translation:z", -25, 25, SPIN_TIME
            )
        ":translation:z":
            $Tween.interpolate_property(
                $MeshInstance, "rotation_degrees:y", 0, 360, SPIN_TIME
            )
        ":rotation_degrees:y":
            $Tween.interpolate_property(
                $MeshInstance, "translation:x", -25, 25, SPIN_TIME
            )
        _:
            print("Bad +-> ", str(key))
    $Tween.start()
