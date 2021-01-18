extends Control

# This class is meant to provide three things:
#   1. A core menu for us to access all of the tests from
#   2. A loading screen to load those tests in the background
#   3. A pause menu that provides common behavior to ALL of the tests
# It also provides a convenient fourth item: a wonderful demonstration on how to
# do the other items using XSM! Seriously, the states have made everything WAY
# more clear.

# What is our currently running scene?
var scene_running = null
# What is the resource path for that scene?
var scene_res = null

func _ready():
    # The Pause menu is disabled
    $PauseLayer/PauseMenu.disabled = true
