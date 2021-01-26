extends StateRoot

# Called when the node enters the scene tree for the first time.
func _ready():
    # Force "AtMenu" as initial state
    goto_state("AtMenu")
    # Call _on_enter because XSM doesn't do that for initial nodes
    $AtMenu._on_enter(null)
