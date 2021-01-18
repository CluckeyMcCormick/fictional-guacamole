extends State

onready var PauseMenu = get_node("../../PauseLayer/PauseMenu")

func _on_enter() -> void:
    # Show the menu
    PauseMenu.visible = true
    # Enable the menu
    PauseMenu.disabled = false
    # Inform the user, pause the game
    print("Game Paused!")
    get_tree().paused = true
    
    # Connect listening functions
    PauseMenu.connect("resume_game", self, "_on_PauseMenu_resume_game")
    PauseMenu.connect("main_menu", self, "_on_PauseMenu_main_menu")
    PauseMenu.connect("exit_game", self, "_on_PauseMenu_exit_game")

func _on_exit() -> void:
    # Hide the menu
    PauseMenu.visible = false
    # Disable the menu
    PauseMenu.disabled = true
    # Unpause the game
    get_tree().paused = false

    # Disconnect listening functions
    PauseMenu.disconnect("resume_game", self, "_on_PauseMenu_resume_game")
    PauseMenu.disconnect("main_menu", self, "_on_PauseMenu_main_menu")
    PauseMenu.disconnect("exit_game", self, "_on_PauseMenu_exit_game")

func _on_PauseMenu_resume_game():
    change_state("SceneRunning")
    # Disable the menu ahead of time to prevent double-dipping
    PauseMenu.disabled = true
    # Have to unpause because state relies on _physics_process to change states
    get_tree().paused = false

func _on_PauseMenu_main_menu():
    change_state("AtMenu")
    # Disable the menu ahead of time to prevent double-dipping
    PauseMenu.disabled = true
    # Have to unpause because state relies on _physics_process to change states
    get_tree().paused = false

func _on_PauseMenu_exit_game():
    # Tell the user
    print("Quitting the game!")
    # Quit!
    get_tree().quit()
