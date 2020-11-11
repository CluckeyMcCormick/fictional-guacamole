extends Spatial

# How many bodies are we tracking that are inside the house?
var interior_body_count = 0
# How many bodies are we tracking that are outside the house?
var exterior_body_count = 0

# What are the corners of this house?
enum Corners {BACK_RIGHT, BACK_LEFT, FRONT_LEFT, FRONT_RIGHT}
# Since this game is isometric, there will be instances where bodies move behind
# (or in) this house and we won't be able to see them. In that instance, we need
# to drop/collapse/disappear certain segments of the house. What corner is
# hidden from view and, thus, needs to be observed for collapsing purposes? 
export(Corners) var hiding_corner = Corners.FRONT_LEFT

func _ready():
    match hiding_corner:
        Corners.BACK_RIGHT:
            $PawnDetectors/Exterior/EastShape.disabled = false
            $PawnDetectors/Exterior/NortheastShape.disabled = false
            $PawnDetectors/Exterior/NorthShape.disabled = false
        Corners.BACK_LEFT:
            $PawnDetectors/Exterior/NorthShape.disabled = false
            $PawnDetectors/Exterior/NorthwestShape.disabled = false
            $PawnDetectors/Exterior/WestShape.disabled = false
        Corners.FRONT_LEFT:
            $PawnDetectors/Exterior/WestShape.disabled = false
            $PawnDetectors/Exterior/SouthwestShape.disabled = false
            $PawnDetectors/Exterior/SouthShape.disabled = false
        Corners.FRONT_RIGHT:
            $PawnDetectors/Exterior/SouthShape.disabled = false
            $PawnDetectors/Exterior/SoutheastShape.disabled = false
            $PawnDetectors/Exterior/EastShape.disabled = false
            
func assert_shadow_status():
    var shadow_modes = $UpperWallSet.ShadowModes
    
    # If we have no reason to show the exterior or the interior, then... don't!
    if interior_body_count <= 0 and exterior_body_count <= 0:
        $Roof.shadow_only_mode = false
        $UpperWallSet.shadow_only_mode = shadow_modes.FULL_VIS
    
    # Otherwise, if there's only bodies inside the house...
    elif interior_body_count > 0 and exterior_body_count <= 0:
        $Roof.shadow_only_mode = true
        
        # Now, we want to cut away the walls to show the inside of the house.
        # Since the "hiding corner" is the side the camera can't see, that means
        # the opposite corner is what the camera CAN see - so turn that wall to
        # shadow only mode! 
        match hiding_corner:
            Corners.BACK_RIGHT:
                $UpperWallSet.shadow_only_mode = shadow_modes.SHADOW_SW
            Corners.BACK_LEFT:
                $UpperWallSet.shadow_only_mode = shadow_modes.SHADOW_SE
            Corners.FRONT_LEFT:
                $UpperWallSet.shadow_only_mode = shadow_modes.SHADOW_NE
            Corners.FRONT_RIGHT:
                $UpperWallSet.shadow_only_mode = shadow_modes.SHADOW_NW
    
    # Here's where we'd put some code for controlling what happens whenever
    # there is something outside but not inside. We just don't really have a
    # need for that - yet!
    
    # Otherwise, there must be stuff both inside and outside 
    else:
        $Roof.shadow_only_mode = true
        $UpperWallSet.shadow_only_mode = shadow_modes.SHADOW_ONLY
    
func _on_Interior_body_entered(body):
    interior_body_count += 1
    assert_shadow_status()

func _on_Interior_body_exited(body):
    interior_body_count -= 1
    assert_shadow_status()

func _on_Exterior_body_entered(body):
    exterior_body_count += 1
    assert_shadow_status()

func _on_Exterior_body_exited(body):
    exterior_body_count -= 1
    assert_shadow_status()
