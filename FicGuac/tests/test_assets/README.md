# Tests Assets
This is a directory for scenes and assets that are used in testing - exclusively for testing. Anything used sporadically or in level construction/prototyping should go in the *utility* directory.

## Cubit
The *Cubit* is both a test vehicle for the *KinematicDriverMachine* and a demonstration of the minimal effort required to integrate the machine and order it's parent/target node around. 

### Functions
##### `move_to_point`
Instructs the Cubit to path-and-move from its current position to the specified point. Behavior is undefined if a path cannot generated; most likely outcome is the Cubit defaults to the *Idle* state (doesn't move).

##### `clear_pathing`
Clears the pathing variables. This will cause the Cubit to stop moving.

## SpriteDiagnosticPawn
This is a *BasePawn* with the *FallingBodyMachine* integrated in. So it's basically a Pawn with gravity attached. The real utility of this class is that it ignores `visual_update` signals coming from the integrated *FBM*. This allows us to set the sprites/animations at will and observe how they look with the *BasePawn*'s *kinematic profile*.

A lot of words for a thing that does nothing but fall straight down, but believe or not that was something we really needed.

## KinematicPawn
This is a *BasePawn* with the *KinematicDriverMachine* integrated in. This allows us to test just the movement aspects of the *kinematic profile* and the *pathing interface* without having to deal with higher level AI functions. This pawn instead focuses on pathing to user specified points.

### Functions
##### `move_to_point`
Instructs the Pawn to path-and-move from its current position to the specified point. Behavior is undefined if a path cannot generated; most likely outcome is the Pawn defaults to the *Idle* state.

##### `clear_pathing`
Clears the pathing variables. This will cause the Pawn to stop moving.

### Signals
##### `path_complete`
Emitted when the current path is complete. Includes the pawn and the path-adjusted position.

##### `error_goal_stuck`
Signal issued when this pawn is stuck and our other error resolution methods didn't work. A pass-through of the `error_goal_stuck` signal from the *KinematicDriverMachine*. Includes the pawn and the path-adjusted target.

## RatPawn
This is a *BasePawn* with the *RatEmulationMachine* integrated in. This is largely a testbed for that machine. It's a bit bare bones at the moment.

## TaskingCowardPawn
This is a *BasePawn* with the *TaskingCowardMachine* integrated in. This allows the Pawn to serve as a test-bed for any and all tasks.

### Functions
##### `give_task`
Gives the Pawn a specific task to perform. Basically a wrapper function for the *TaskingCowardMachine*'s `give_task` function. The task should already be initialized using the `specific_initialize` function. The `template_initialize` function will be called by the Pawn/machine.

### Signals
##### `task_complete`
Emitted when the assigned task is completed - either succeeded or failed. Allows us to react during testing.