extends Spatial

# Has this particular stalk of corn been trampled?
var trampled = false

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

# If something goes through this crop...
func _on_CornArea_body_entered(body):
    # Then we need to "crush" it, so that it looks like something trounced on it.
    # If we've already been trampled, nothing to do here. Back out.
    if trampled:
        return
    
    # If we're here, then we gotta make this corn look crushed. Set it to be
    # crushed.
    trampled = true
    
    # Next, disable monitoring on the area, so that this doesn't happen again.
    # Once crushed, this node is crushed.
    $CornArea.monitoring = false
    $CornArea.monitorable = false
    $CornArea/CornShape.disabled = true
    
    # Hover the corn .002 off of the ground
    $CornQuad.translate( Vector3(0, -0.998, 0) )
    # Reset the corns's y rotation so that we can do the other rotations
    $CornQuad.rotate_y(-PI / 4)
    # Rotate the corn so that it's flat
    $CornQuad.rotate_x(-PI / 2)
    
    # If this body has a combined velocity...
    if body.get("_combined_velocity") != null:
        # Then we can use that to determine which way we should fold our crop.
        # Let's extract the x and z values.
        var xz_velo = Vector2(body._combined_velocity.x, -body._combined_velocity.z)
        # Then, rotate on y to match the direction
        $CornQuad.rotate_y( xz_velo.angle() - (PI / 2))
        
    # Finally, turn off shadows on the quad so we're not wasting processing
    # power on flat things with no shadows. 
    $CornQuad.set_cast_shadows_setting(0)
    # Normally cast_shadows is supposed to be set by enum but for some reason
    # Godot can't find the enum - I think this is an editor issue (3.2.2 26Jun20)
