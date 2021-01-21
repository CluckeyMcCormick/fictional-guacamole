# Pawn
The pawn is the main NPC of the game, and is one of the key areas of development.

## Base Pawn
The basic pawn. Contains a basic script, some sprites, and what we collectively refer to as the *Kinematic profile*.

The *Kinematic profile* consists of the `KinematicCore` and the collision shapes that help define how the Pawn moves. We define this in the base class so that all the derived scenes have the same profile. This helps keep things consistent, but also allows us to test different aspects of the *Kinematic profile* separately. That's really important, given the complex interactions between elements of the *Kinematic profile*.

You'll notice that we have three collision shapes. The "actual" collision shape is used in conjunction with the `KinematicCores`'s *Float Height* configurable to allow the Pawn to step up ledges. The other two are guide shapes; we mostly use them to help measure the Pawn's ideal and effective sizes.

Currently, the pawn's actual collision shape is a capsule. This was done so that the Pawn could easily move over and around objects without getting hooked on things (a common problem for boxier shapes). The Pawn's effective step-up height is ~0.5 units - exactness is difficult because of interplay between the *Float Height* and the capsule's rounded bottom.


### Configurables
##### Position Algorithm
In order to move the Pawn appropriately, we need to know where the Pawn is, as aligned with the path points. Trouble is, that changes depending on exactly what we're doing. We currently support three separate methods:

- *Floor*: The Pawn's adjusted position is measured from the floor, or the Pawn's feet.
- *Navigation*: The Pawn's adjusted position is given by querying a Navigation node. This is the Godot-native method and what we hope to use once Godot 4.0 is released.
- *Detour Mesh*: The Pawn's adjusted position is given by querying a `NavigationMesh` node from *Godot Navigation Lite*, a pathing add-on we're using. This will hopefully be removed with Godot 4.0.

##### Navigation
Two of our *Position Algorithm*s, *Navigation* and *Detour Mesh*, require nodes in order to work. This configurable allows the user to provide the appropriate node.

##### Equipment
The `BasePawn` has two sprites - the *Visual Sprite* and the *Weapon Sprite*. We set these independently so any sprite of the same silhouette can reuse a weapon set. The whole system is designed for palette swaps.

Anyway, you can specify the equipment that the pawn should be carrying by using this configurable.

### (Public) Variables
##### `_orient_enum`
The current orientation/heading/direction of the pawn. Set to one of the *Cardinal* `Enum` values (see below). Good for reading, but should generally only be set using feedback from an AI machine of some kind. Should be set using the `update_orient_enum` function.

### Functions
##### `get_adjusted_position`
Returns the current `Vector3`, position, as determine by the Pawn's *Position Algorithm* configuration.

##### `assert_equipment`
Sets the equipment of the sprite given an `Equipment` `Enum` (see below). This includes loading the appropriate sprite frames (that's why there's a function!).

##### `update_orient_enum`
Updates the `_orient_enum` variable given a `Vector3`. Sets the value to one of the *Cardinal* `Enum` values.

### Constants

##### Cardinals (`Enum`)
A constant enumeration that isn't actually named in code - but we generally refer the enumeration as the *Cardinal*(s). Used for easy delineation of directions - very important for our 8-directional sprites.

##### `PosAlgo` (`Enum`)
Enumerates the different positional algorithms this Pawn can use - these `Enum` values correspond to the *Position Algorithm* configurable.

##### `Equipment` (`Enum`)
Enumerates the different pieces of equipment the Pawn can have equipped - these `Enum` values correspond to the *Equipment* configurable.

##### `FLOOR_DISTANCE`
The (rough) distance from the center of the pawn to the floor. Used in the *Floor* *Position Algorithm*.

## Pawn Sizer
This scene is literally just a scene with the 3D version that the 2D sprites are based on. This can be used for reference, but was mostly used to scale the sprites until they were the "correct" size.
