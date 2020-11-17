extends Control

# This class is meant to provide three things:
#   1. A core menu for us to access all of the tests from
#   2. A loading screen to load those tests in the background
#   3. A pause menu that provides common behavior to ALL of the tests
# It also provides a convenient fourth item: a wonderful demonstration on why
# DOING ALL OF THE ABOVE IS A TERRIBLE IDEA! We have to track the state of
# everything and do a whole bunch of unecessary dumb error checking and even
# then we have a dubious success rate.
#
# Other game scenes should control their pause menus and loading processes
# internally. That way we don't have to worry about an external stuff - we don't
# need to worry about where the scene came from, only where it is going.
#
# All that being said, this awful mess of a class/node/scene is, to me,
# justifiable. It provides a common functionality and control set to the test
# scenes, which were purposefully designed to be as lightweight as possible.
# Creating a test should be quick and easy - this scene allows us to offload the
# burden (in exchange for some ugly code). Using it outside this context,
# however, would be abhorrent.

# What's our current state?
enum GameState {
    AT_MENU, # We are at the main menu
    LOADING, # We are loading a scene
    SCENE_RUNNING, # We are running a scene
    SCENE_PAUSED # The scene is paused
}

# What state, of the above, are we in?
var current_state = GameState.AT_MENU

# What is our currently running scene?
var scene_running = null

func _ready():
    # The Pause menu is disabled
    $PauseMenu.disabled = true

# Process input.
func _input(event):
    # If the user presses the pause button...
    if event.is_action_pressed("game_core_pause"):
        # ...and our scene is running...
        if current_state == GameState.SCENE_RUNNING:
            # Show the menu
            $PauseMenu.visible = true
            # Enable the menu
            $PauseMenu.disabled = false
            # Update the state
            current_state = GameState.SCENE_PAUSED
            # Inform the user
            print("Game Paused!")
            # Pause the scene...
            get_tree().paused = true

func _on_LoadingScreen_loading_complete(scene_resource, path):
    # Tell user
    print("Successfully loaded ", path)
    
    # Instance the scene
    scene_running = scene_resource.instance()
    
    # Add the scene to the root
    self.add_child(scene_running)
    
    # Hide the LoadingScreen, reset
    $LoadingScreen.reset()
    $LoadingScreen.visible = false
    
    # Hide, the TestMenu
    $TestMenu.visible = false
    
    # We're now on our scene. Neat!
    current_state = GameState.SCENE_RUNNING

func _on_LoadingScreen_loading_failed(path):
    # Turn off our loading screen
    $LoadingScreen.visible = false
    # Re-enable the menu scene
    $TestMenu.disabled = false
    # Tell user
    print("Load failed for path: ", path)
    # We're back at the menu now
    current_state = GameState.AT_MENU

func _on_TestMenu_scene_chosen(resource_path, scene_name):
    # Inform the user
    print("Loading: ", scene_name)
    
    # Disable the menu
    $TestMenu.disabled = true
    
    # Show the load screen
    $LoadingScreen.visible = true
    
    # Start the load
    $LoadingScreen.initiate_scene_load(resource_path)

    # We're loading!
    current_state = GameState.LOADING

func _on_PauseMenu_resume_game():
    # Hide the menu
    $PauseMenu.visible = false
    # Disable the menu
    $PauseMenu.disabled = true
    # Update the state
    current_state = GameState.SCENE_RUNNING
    # Inform the user
    print("Game is resuming!")
    # Unpause the scene...
    get_tree().paused = false

func _on_PauseMenu_main_menu():
    # Hide the menu
    $PauseMenu.visible = false
    # Disable the menu
    $PauseMenu.disabled = true
    # Update the state
    current_state = GameState.AT_MENU
    # Inform the user
    print("Back to the main menu!")
    # Unpause the scene...
    get_tree().paused = false
    # Destroy the running scene
    self.remove_child(scene_running)
    scene_running.queue_free()
    # Enable and show the loading screen
    $TestMenu.disabled = false
    $TestMenu.visible = true

func _on_PauseMenu_exit_game():
    # Tell the user
    print("Quitting the game!")
    # Quit!
    get_tree().quit()

