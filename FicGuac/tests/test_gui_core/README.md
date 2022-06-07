# Test GUI Core
This directory is dedicated to running to running the tests using a united GUI - as well as demonstrating how such a concept would work.

## Test Menu
This is a GUI that lists all of the available/registered tests. The list of tests is populated from `Manifest`'s `TEST_SCENES` dictionary. It emits a signal when the user has made a choice. Pretty basic overall.

## Test Shell
The *Test Shell* provides a common GUI to all over our tests, using a mix of existing GUI components and the *Test Menu*. This scene gives us a single launching point for all tests. It loads and spawns the scene on-the-fly. It even provides a loading screen. It also provides a pause menu (complete with ACTUAL pausing!) to all scenes. 

## Time GUI
The *Time GUI* was originally developed so that the interactions/happenings of the *Viewport Shader Test* could be more easily observed. However, this proved to be a really useful piece of functionality so we isolated it into this scene.

This scene consists of a couple of labels and a slider. It was designed to occupy the entire bottom 1/5 of the screen or so, but thanks to Godot's Control Nodes, it can fit just about anywhere.

Moving the slider will set the Engine's speed (e.g. the time flow) to the specified value. When this scene exits the tree, it resets the Engine speed (so no need to worry about that). Possible values range from 0 (stopped) to 1.5 (1 and 1/2 speed). 