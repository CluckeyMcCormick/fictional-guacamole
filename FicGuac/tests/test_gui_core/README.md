# Test GUI Core
This directory is dedicated to running to running the tests using a united GUI - as well as demonstrating how such a concept would work.

## Test Menu
This is a GUI that lists all of the available/registered tests. It emits a signal when the user has made a choice. Pretty basic overall.

## Test Shell
The *Test Shell* provides a common GUI to all over our tests, using a mix of existing GUI components and the *Test Menu*. This scene gives us a single launching point for all tests. It loads and spawns the scene on-the-fly. It even provides a loading screen. It also provides a pause menu (complete with ACTUAL pausing!) to all scenes. 

