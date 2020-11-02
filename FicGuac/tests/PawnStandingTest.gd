extends Spatial

func _ready():
    # We can't actually manipulate UnitPawn's sprite animation directly, so
    # we've instead parented an AnimatedSprite 3D DIRECTLY on top of the
    # UnitPawn sprite. While we can't effect the animation, we can affect the
    # visibility of that sprite.
    $UnitPawn/VisualSprite.visible = false

# Update the GUI so we know what's up
func _process(delta):
    # Set the position label to the position vector
    $Items/PositionLabel/Info.text = str( $UnitPawn.global_transform.origin )
