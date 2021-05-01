# Core (Tasks)
This directory contains the core components for our various *tasks*.

## Task Template
This is the scene from which all other tasks should be derived (inherited). It provides a common interface that will make using tasks much simpler.

Note that the base scene is an *XSM* `SceneRoot` with no children `State` nodes. That means it's invalid, right off the bat. Add *actions* to complete the task. 

Tasks are allow to partially fail or succeed, however the signals only allow for this to be expressed as a failure-success binary. For our purposes, we only consider 100% whole task completion to be a "success". If we couldn't do everything we were assigned to do, that's a failure.

To actually implement a task, add actions to a scene inheriting from this one. From there, it's a simple matter of adding code to glue the actions together. You'll most likely use a combination of utility functions and functions responding to signals. Don't forget that the initial state of an *XSM* machine is always the first child state in a tree!

### Variables
Although we would not normally document purely internal variables, I felt that it was important to cover the variables available to a task - to express what was inherited, what was unique to a task, and what to expect these values to be.

##### `MR`
The *Machine Root* of this task's parent-machine. This variable offers access to the various configurables of the current machine - especially the *cores*.

##### `PTR`
The *Physics Travel Region* of this task's parent-machine. This region changes very little between different machines and is critical for moving an integrating body (and responding to completed movements).

##### `fsm_owner`
A Godot `NodePath`. This will be the path to the integrating body node. This variable is inherited from *XSM*'s `StateRoot` class. 

##### `target`
This is the node retrieved from the `fsm_owner` path. We actually set this in the `_template_initialize` function as well, but it is usually overwritten when the task enters the scene. This variable is inherited from *XSM*'s `StateRoot` class.

### Functions
##### `_template_initialize`
Initializes the task so that it can actually run. This function should be called in every implementing task so that they are all consistent. It initializes things so that the actions can execute without issue. The arguments are as follows:

- `machine_root`: The root of the machine this task is going to be inserted to. In this instance, "machine" is used in the sense of the game's AI constructs, not specifically an XSM machine. This is needed by tasks to access the various configuration items.
- `physics_travel_region`: The *Physics Travel Region* of the machine this task is going to be inserted in to. This is required in order to move the pawn and detect movement success or errors.
- `target_body`: The target body - must be a 3D `KinematicBody` node. This should be the body integrating the task's parent-machine.

### Signals
##### `task_succeeded`
This signal indicates that the task succeeded. If a task succeeds, that means it did 100% of what it was supposed to.

##### `task_failed`
This signal indicates that the task failed. If a task fails, that means it did **not** complete 100% of what it was supposed to. Could be 0%, could be 99%. Its therefore the responsibility of whatever manages this task to appraise the extent of the failure.