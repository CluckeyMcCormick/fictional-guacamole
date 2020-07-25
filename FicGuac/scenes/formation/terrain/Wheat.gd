extends Spatial

# How many bodies are in this wheat pile? 
var body_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    pass

func _on_PawnDetect_body_entered(body):
    # We don't care about what kind of body entered the wheat - we only need to
    # know when one enters and leaves. It's more efficient, then, to just count
    # the bodies rather than actually tracking them.
    var old_count = body_count
    body_count += 1
    
    # If we were less than 0, than the wheat was in an "Undistrubed" state. We
    # need to change it to the "disturbed" state
    if old_count == 0:
        # For right now, we'll say the "disturbed" wheat in just invisible
        $WheatCube.translate( Vector3(0, -0.25, 0) )

func _on_PawnDetect_body_exited(body):
    # Just reverse what we did before 
    var old_count = body_count
    body_count -= 1
    
    if old_count == 1:
        $WheatCube.translate( Vector3(0, 0.25, 0) )
