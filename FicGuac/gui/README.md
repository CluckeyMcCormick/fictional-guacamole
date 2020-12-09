# GUI
This directory contains our common in GUI elements. The plan for future scenes is for them to handle pausing and loading at the scene level. We could have multiple game scenes, or just one core game scene - it's really up in the air right now. These common GUI scenes are provided for consistency between any scene; now and future.

Note that the *Tests* currently use these scenes in a different way, see that directory for more information.

In keeping with Godot's Scene Philosophy, each of these scenes is as self contained as possible. It's up to external scenes to activate and deactivate these GUI scenes (and listen to the signals emitted by these scenes).

### LoadingScreen
The LoadingScreen presents the user with a loading animation, and a metric of progress. It actually loads a given resource in the background and sends out a signal when done.

I've noticed that there's still some lagtime associated with spawning into a scene; this is most likely due to runtime processing - like procedurally building the houses. The background loading handles the assets, but those are actually pretty quick loads. The spawning and building is what's getting us on load times. We should, eventually, look into solutions to building levels progressively/iteratively, or in the background somehow.

There will be an update to this GUI item to allow, eventually, for different loading status messages.

### PauseMenu

The PauseMenu presents the user with a pretty basic pause menu - Resume, Main Menu, and Quit Game. Each one is linked to a signal. At this time, it doesn't handle any pause functionality in the same way the LoadingScreen does. That's because the activation and deactivation of an in-game pause is a bit complicated, so I think that logic really belongs in the parent scene.
