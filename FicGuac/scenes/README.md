# Scenes
This is the common directory for game-scene specific assets and scenes, including the main game scenes themselves.

## Camera Rig
This is the standardized camera meant for use in game scenes and tests. It handles movement and zoom. More importantly, it actually consists of multiple cameras, with movement and resizes synced between them (that's the 'rig' part). These alternate cameras are then largely used for shaders and other special effects.

Each one of the cameras is already configured to *Orthographic* mode and is rotated appropriately for an *isometric* perspective. Because of that, the *Camera Rig* should **never be rotated**. It only needs to be moved into an initial position on x, y, and z.

Because camera movement is a bit complicated, there are a lot of different configurable options for the Camera Rig.

### Configurables
##### Basic Move Rate
The basic move rate of the camera, in units-per-second. The move rate decreases as the camera zooms in, and increases as the camera zooms out. It does this as a percentage of the current zoom over the maximum zoom.

In other words, this is the movement rate of the camera **at maximum zoom**. As the player zooms in, the camera will slow down. The idea is to present a camera that effectively seems to be moving at the same rate no matter the zoom level.

##### Camera Size
With orthographic cameras, there's no real concept of zoom or FOV. Instead, what the camera can see is determined by it's *size*. This configurable controls the current size of all the cameras on the rig.

##### Max Camera Size
This is the maximum possible camera size.

##### Min Camera Size
This is the minimum possible camera size.

##### Zoom Step
This configurable controls the size change whenever the user zooms in or out.

##### Move Enabled
This configurable controls camera movement (based on input). If a static camera is required, turn this configurable off.

Keep in mind that this only disables camera movement from user input - if the camera is translated or a child of some object, the camera will still move.

##### Zoom Enabled
This configurable controls camera zoom (based on input). If a static camera is required, turn this configurable off.

Keep in mind that this only disables camera zoom from user input - the *Camera Size* can still be manipulated directly.

##### Move Clamping Extents
In almost any game, you don't want the camera to be able to move forever - that's just a bad idea. The *Move Clamping Extents* allows us to clamp the movement on both the x and z axis. Note that the GUI says x and y, just ignore that: in this instance, **y is z**. That's just a side effect of using a `Vector2`. Besides, there's no reason to move the camera on Z.

If a value for a given axis is > 0, then the camera movement will be clamped on that axis. The camera is clamped to it's starting point on the axis, plus-or-minus the configured axis value.