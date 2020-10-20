# Blender Scripts

These scripts were used to create the pawn sprites for this game. Each one
serves a particular purpose.

## Included Scripts

### pawn_constants.py
The pawn_constants.py script doesn't actually do anything - rather, it provides
constants the are required for the other scripts to run. This mostly takes the
form of measurements for the pawn's different components: feet width, head
depth, hand radius, etc.

One important (and somewhat odd note): I based the pawn model off of a little
wooden doll. To make the pawn, I took measurements from the doll and applied
them to the various components. Rather than actually taking the time to
translate these into Blender World Units (WU) like a normal person, I kept all
of the measurements in millimeters.

Because of that, we have one key constant: `MM_PER_WORLD_UNIT`. This acts as our
scaling ratio, specifying how many millimeters correspond to a world unit.

This file also has the string names for many components, to ensure consistency
across scripts. 

### generate_pawn.py
This script populates the current scene/collection with custom-generated pawn
components. This is the only way to populate the scene with pawn components - so
if you changed something in pawn_constants.py, you will need to run this script
again to generate all the components appropriately.

All the components will be the right size and shape, but will all be
independent from each other: no component will be parented to any other
component.

While you could animate in this state, you would need to animate each component
individually - ergo, it's not exactly animation ready. You may wish to add
extra parts or use the parts separately, or you can move on and organize the
pawn using another script.

If this script is run in a scene where there are already existing pawn
components, the pawn components will still be created but under an alternate
name. Ergo, these new components will not be affected by subsequent scripts.

One thing to note - you could theoretically use this model in Godot or any other
game engine, but I designed the script intending the model to only be used in
Blender. I've used it in Godot, and I noticed that the faces are all wrong.
It's like you can see right through it! Ergo, I'd recommend either redoing this
script or just not using the model. 

### prepare_pawn.py
This script serves as an intermediate step - it takes the components in the
scene and parents them as appropriate. The feet are attached to the legs, the
hands attached to the body, etc.

Outside of setting up the pawn for animation, this script serves little
purpose.

### scene_configuration.py
The previous scripts all related to the pawn; this script sets up our camera,
lighting, and export settings. This helps ensure consistency with existing
sprites - this will make it easier to create new sprites on the fly.

The lights and cameras are added under an "empty" object, which acts as the rig
for moving the lights and the cameras. It is centered on the middle point of
the pawn's body by default.

### pose_pawn.py
This script has various functions for putting each component of the pawn in a
variety of positions. Each function governs one component - a left arm, a right
leg, the head, or the left foot.

The intention is that you mix-and-match function calls to create your ideal
pose, and then register that pose as a keyframe. You can then change the
function calls to create a new pose, and so on and so on.

## Execution Order
In case you couldn't tell from our description of each script, they are meant
to be run in a particular order, like so:

1. Edit `pawn_constants.py` (if you want to)
1. Run `generate_pawn.py`
1. Run `prepare_pawn.py`
1. Run `scene_configuration.py`
1. Use `pose_pawn.py` for posing as desired

## Running the scripts
These scripts were meant to be loaded into Blender's text file window, and
then ran in sequence. However, there are is one special caveat, and it concerns
the `pawn_constants.py`.

To ensure consistency between the scripts, we actually add the file-path to the
constants script to Python's file path. That might not mean anything to you
_BUT_ it has __two__ important implications.

First, you have to edit each script so that the path reflects where your
`pawn_constants.py` file is stored. You'll notice that most scripts have the
following lines near the top:

```Python
# This is the path to where the other Python scripts are stored. You will need
# to update this if it doesn't match your exact project path.
SCRIPTS_PATH = "~/godot/fictional-guacamole/scripts/Blender" # Change me!
```

Just like the comment says - this needs to be changed to whatever path your
scripts are stored on.

Secondly: because this is dynamically loaded at runtime, it uses whatever
version of `pawn_constants.py` is in that directory. So, if you load
`pawn_constants.py` into Blender and make changes but don't somehow update the
actual file in the actual directory, the changes will not propagate! That's why
it's recommended you edit that file first before running the other scripts.
