extends State

# Need ready to disable calls to _input that could be premature
func _ready():
    self.set_process_input(false)

func _on_enter() -> void:
    self.set_process_input(true)

func _on_exit() -> void:
    self.set_process_input(false)

func _input(event):
    # If the user presses the pause button...
    if event.is_action_pressed("game_core_pause"):
        # Change to the "ScenePaused" state!
        change_state("ScenePaused")
