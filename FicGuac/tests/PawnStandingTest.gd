extends Spatial

# Update the GUI so we know what's up
func _process(delta):
    # Set the position label to the position vector
    $Items/PositionLabel/Info.text = str( $SpriteDiagnosticPawn.global_transform.origin )
