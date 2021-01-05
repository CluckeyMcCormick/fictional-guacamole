# Blender Scripts

These scripts were used to create the pawn sprites for this game. Each one
serves a particular purpose. They were created and tested for Blender 2.90, but
the API is standard to Blender 2.80 forward, so it SHOULD be compatible with
those versions.

## Included Scripts

### `pawn_constants.py`
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

### `pawn_generate.py`
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

### `pawn_prepare.py`
This script serves as an intermediate step - it takes the components in the
scene and parents them as appropriate. The feet are attached to the legs, the
hands attached to the body, etc.

Outside of setting up the pawn for animation, this script serves little
purpose.

### `pawn_prepare_accessories.py`
Sometimes the pawn has additional items that need to be "prepared" - moved into
place. These items are generally something loaded into the scene by hand. Custom
assets like hats, armor, jewelry, weapons, etc.

This file has functions for preparing (positioning) different accessories, which
will change depending on what accessories have currently been loaded in. Because
of that, this is one of the few scripts with decent error handling.

### `pawn_scene_configuration.py`
The previous scripts all related to the pawn; this script sets up our camera,
lighting, and export settings. This helps ensure consistency with existing
sprites - this will make it easier to create new sprites on the fly.

The lights and cameras are added under an "empty" object, which acts as the rig
for moving the lights and the cameras. It is centered on the middle point of
the pawn's body by default.

Running this script again will remove & replace the camera rig and update the
export settings.

### `pawn_pose_core.py`
This script has various functions for putting each component of the pawn in a
variety of positions. Each function governs one component - a left arm, a right
leg, the head, or the left foot.

The intention is that you mix-and-match function calls to create your ideal
pose, and then register that pose as a keyframe. You can then change the
function calls to create a new pose, and so on and so on.

This was originally intended to have ALL of the pose functions, but I realized
that most specific poses are best kept with their associated animations. Now
this just serves as a library for some common pose functions, like default
position functions.

### `pawn_animate.py`
This script is a natural extension of `pawn_pose_core.py` - where that script has
controls for setting the position of the pawn's components, this script offers
utilities for bundling those pose functions together, and then creating all of
the keyframes necessary for that animations at all 8 angles.

That's right - the utilities in this script even handle keyframing the multiple
angles you'll need!

Once you export the animation as a series of images, you just have to
pack it all into a spritesheet. I used a combination of my own personal
ImageMagick script, `sprite_sheetmaker.bash` (see the appropriate directory).

### `pawn_compositing_configuration.py`
We render the Pawn sprites separate from the weapons. The pawn sprites are the
whole sprite, while the weapon sprites have the pawn masked out. This means
weapon sprites are essentially "subordinate" to the pawn sprites - a change in
the Pawn model necessitates a change to the weapon sprites, but a change in the
weapon sprites doesn't impact the Pawn sprites. 

This is a bit bonkers, but it allows us to match any pawn sprite with any
weapon, PROVIDED there is nowmorphological changes. In other words, this
strategy works as long as there's no change in the actual shape of the models - 
just the color of the models.

This script is what enables that crazy strategy, via Blender's compositing system
and the 'Cycles' rendering system (it only works with 'Cycles'). When ran, it
presents the user with several options - mask out the weapon, mask out the Pawn, 
disable node rendering, or cancel any operations. 

Right now, masking out the Pawn is what we use to make weapon sprites. Pawn
sprites are made by moving the weapon out of frame, NOT by masking out the weapon.
Masking out the weapon is provided as more of an example, or a curiosity - it may
be deleted in the future.

### Animations
The animation directory contains our individual animations - one script, one
animation. Running one of these scripts will create all the required keyframes
(and probably a lot more than that too).

## Execution Order
In case you couldn't tell from our description of each script, they are meant
to be run in a particular order, like so:

1. Edit `pawn_constants.py` (if you want to)
1. Run `pawn_generate.py`
1. Run `pawn_prepare.py`
1. Edit and run `pawn_prepare_accessories.py` as necessary
1. Run `pawn_scene_configuration.py`

At this point, the scene should be configured appropriately. The last thing
you'll really need to configure will be the output directory, since that has
to be configured by hand - check the "Output" tab under the "Output Properties"
tab (in Blender 2.9, the icon looks like a little printer)

The next two steps are meant to be run repeatedly (as necessary) to generate
the needed sprites.

1. Run `pawn_compositing_configuration.py` as needed
1. Run a script in the `animations` directory (or add a new one) as necessary
1. Render the animation

## Running the scripts
These scripts were meant to be loaded into Blender's text file window, and
then ran in sequence. However, there are is one special caveat, and it concerns
`pawn_constants.py`.

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

Note that `animate_pawn.py` relies on `pose_pawn.py` in the same way, as do many
of the `animation` scripts.


