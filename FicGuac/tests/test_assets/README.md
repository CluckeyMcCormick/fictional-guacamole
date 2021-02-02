# Tests Assets
This is a directory for scenes and assets that are used in testing - exclusively for testing. Anything used sporadically or in level construction/prototyping should go in the *utility* directory.

## Cubit
The *Cubit* is both a test vehicle for the *KinematicDriverMachine* and a demonstration of the minimal effort required to integrate the machine and order it's parent/target node around. 

## SpriteDiagnosticPawn
This is a *BasePawn* with the *FallingBodyMachine* integrated in. So it's basically a Pawn with gravity attached. The real utility of this class is that it ignores `visual_update` signals coming from the integrated *FBM*. This allows us to set the sprites/animations at will and observe how they look with the *BasePawn*'s *kinematic profile*.

A lot of words for a thing that does nothing but fall straight down, but believe or not that was something we really needed.

## KinematicPawn
This is a *BasePawn* with the *KinematicDriverMachine* integrated in. This allows us to test just the movement aspects of the *kinematic profile* without having to deal with higher level AI functions. This pawn instead focuses on following user provided paths and points.

### Functions
##### `set_target_position`
Sets the `target_position` variable on the pawn's internal machine. The pawn will move towards the provided position.

##### `set_target_path`
Sets the `target_path` variable on the pawn's internal machine. The pawn will iterate through the provided path (it should be an `Array` of `Vector3` points), visiting each point.

### Signals
##### `path_complete`
Emitted when the current path is complete. Includes the pawn and the path-adjusted position.

##### `error_goal_stuck`
Signal issued when this pawn is stuck and our other error resolution methods didn't work. A pass-through of the `error_goal_stuck` signal from the *KinematicDriverMachine*. Includes the pawn and the path-adjusted target.

## RatPawn
This is a *BasePawn* with the *RatEmulationMachine* integrated in. This is largely a testbed for that machine. It's a bit bare bones at the moment.