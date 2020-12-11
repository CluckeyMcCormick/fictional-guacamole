# Pawn
The pawn is the main NPC of the game, and is one of the key areas of development.

## Asset Naming Scheme
Since there are many color palettes and animations for the pawn, which we're constantly working on, we have a naming scheme for pawn sprites and associated image files. It looks something like this:

```
{pawn version}_{skin}_{type}
```

We're not locked on a particular design for the pawn yet, and I fully acknowledge that there will likely be series changes in the future. Thus, each pawn asset is first identified by the *Pawn Version*. Our current generation of sprites is `pawn_revision01`.

Next comes the *Skin*, which identifies the flavor of pawn sprite. These are, most typically, recolors.

Finally comes the *Type* set (if there is a type set, it depends on the files). It's a bit of a weird distinction, but animations are meant to be grouped by what type of state/pawn the represent. Three example types would be:

- *Normal*
- *Wounded*
- *Zombie*

So there would be several animations under *normal*, several under *wounded*, and several under *zombie*. This is because each type of pawn would move differently, attack differently, and carry objects differently.

## Base Pawn
The basic pawn - the star of the show, if you will. We repeatedly refer to it as basic, base, or basal because we're considering having different scenes inherit from this one.

If you look at the scene, you'll notice that the `KinematicDriver` (see the `motion_ai/common` directory) is already integrated with the Pawn. Note that there's two collision shapes - an effective collision shape and an actual collision shape. The actual collision shape is used in conjunction with the `KinematicDriver`'s *Float Height* configurable to allow the Pawn to step up ledges.

Currently, the only real functionality of the Pawn is pathing: give the Pawn a path, and it will follow that path.

### Configurables
##### Position Algorithm
In order to move the Pawn appropriately, the `KinematicDriver` needs to know where the Pawn is, as aligned with the path points. Trouble is, that changes depending on exactly what we're doing. We currently support three separate methods:

- *Floor*: The Pawn's adjusted position is measured from the floor, or the Pawn's feet.
- *Navigation*: The Pawn's adjusted position is given by querying a Navigation node. This is the Godot-native method and what we hope to use once Godot 4.0 is released.
- *Detour Mesh*: The Pawn's adjusted position is given by querying a Navigation Mesh node from Godot Navigation Lite, a pathing add-on we're using. This will hopefully be removed with Godot 4.0.

##### Navigation
Two of our *Position Algorithm*s, *Navigation* and *Detour Mesh*, require nodes in order to work. This configurable allows the user to provide the appropriate node.

### (Public) Variables
##### `current_path`
The current path the Pawn is following. Should be an array of `Vector3` points. Points are followed front-to-back. Path is considered complete once the array is empty.

### Signals
##### `path_complete`
Emitted when the current path is complete. Includes the pawn and the path-adjusted position.

## Pawn Sizer
This scene is literally just a scene with the 3D version that the 2D sprites are based on. This can be used for reference, but was mostly used to scale the sprites until they were the "correct" size.
