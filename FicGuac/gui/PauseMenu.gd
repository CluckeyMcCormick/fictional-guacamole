extends Control

signal resume_game()
signal main_menu()
signal exit_game()

# Is this scene currently enabled? We try to en/disable the scene so we don't
# accidentally take the user back to the menu or something.
var disabled = true setget set_disabled

# If the player pressed the "resume" button...
func _on_ResumeButton_pressed():
    # Tell the world!
    emit_signal("resume_game")

# If the player pressed the "main menu" button...
func _on_MenuButton_pressed():
    # Tell the world!
    emit_signal("main_menu")

# If the player pressed the "exit game" button...
func _on_ExitButton_pressed():
    # Tell the world!
    emit_signal("exit_game")

# Set the disabled status for this scene.
func set_disabled(new_bool):
    disabled = new_bool
    if disabled:
        $VBoxContainer/ResumeButton.disabled = true
        $VBoxContainer/MenuButton.disabled = true
        $VBoxContainer/ExitButton.disabled = true
    else:
        $VBoxContainer/ResumeButton.disabled = false
        $VBoxContainer/MenuButton.disabled = false
        $VBoxContainer/ExitButton.disabled = false
