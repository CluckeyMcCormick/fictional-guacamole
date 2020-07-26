extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# If something goes through this crop...
func _on_CornArea_body_entered(body):
    # Then we need to "crush" it, so that it looks like something trounced on
    # it.
    # First, disable monitoring on the area, so that this doesn't happen again.
    # Once crushed, this node is crushed.
    $CornArea.monitoring = false
    $CornArea.monitorable = false
    $CornArea/CornShape.disabled = true
    # Hover it just .002 off of the ground
    $CornQuad.translate( Vector3(0, -0.998, 0) )
    # Rotate the barley so that it's flat
    $CornQuad.rotation_degrees.x = -90
    
    # If this body has a combined velocity...
    if body.get("_combined_velocity") != null:
        # Then we can use that to determine which way we should fold our crop.
        # Let's extract the x and z values.
        var xz_velo = Vector2(body._combined_velocity.x, -body._combined_velocity.z)
        # Then, rotate on y to match the direction
        $CornQuad.rotation_degrees.y = rad2deg( xz_velo.angle() - (PI / 2))
        
