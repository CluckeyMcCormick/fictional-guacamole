extends Spatial

func _on_Timer_timeout():  
    $TaskingCowardPawn.move_item(
        $PawnCorpse,
        $Position3D.global_transform.origin
    )
