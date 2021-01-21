# Falling Body Machine
The most basic machine. Developed as a debugging tool to so we can see how sprites sit on a surface, given certain collision models. All it does is fall/move downward.

### Configurables
This machine features the standard configurable items for a machine `State` (see the *addons* directory for more, and the *xsm* subdirectory for EVEN MORE).

##### FSM Owner
As with every machine, the *FSM Owner* is required to be a `KinematicBody` node.

##### Kinematic Core
We require a `KinematicCore` node to define the movement profile for this machine.

### (Public) Variables
##### `_curr_orient`
A `Vector3`, where each axis is the current (rough) heading on each axis. The number is actually equivalent to the last updated velocity on each axis - however, it should only really be used to gauge "heading" or "orientation".

The values are irregularly updated in order to preserve continuity between states. This is particularly necessary for our sprites, which require an angle calculated from this `Vector3`. If this were to reset to (0, 0, 0) when not moving, the sprites would jerk into a common direction when at rest. Always.

##### `readable_state`
A `String`, indicating the current state (i.e. Walk, OnGround, Falling, etc.). Made for debugging/display purposes.

### Signals
##### `visual_update`
While the *Extended States Machine* suggests supplying a animation node, and doing EVERYTHING through that, we're holding off on that for now. That method isn't exactly compatible with our usage of `AnimatedSprite3D`. So instead, we offer a more general solution - states in the machine are free to emit the `visual_update` signal at will; it is up to the scene integrating this machine to update the visuals appropriately.

There are two arguments emitted with this signal. First is the `animation_key`, which indicates the type of animation that needs to be played. It will be something like "walk", "idle", "single\_swing", "single\_stab", etc.

The next argument is an orientation `Vector3`, `curr_orientation`. This indicates the heading/direction/facing of the *FSM Owner* at the time the signal is emitted. For this machine, it's a straight copy of the `_curr_orient` field.

### State Composition
Excluding the root state, there are two other states: 

1. *Falling*
1. *OnGround*

This looks like so:

![Image](./doc_images/FBM.hierarchy.png "FBM Hierarchy Tree")

The *OnGround* state is constantly probing downwards to ensure we are on the ground. If we aren't on the ground for whatever reason, we move to the *Falling* state.

While in the *Falling* state, the only thing we do is fall. That's it. Once we hit the ground, we move to the *OnGround* state.

The `visual_update` signal is regularly emitted throughout the *Falling* and *OnGround* states.

This whole process can be observed in this image:

![Image](./doc_images/FBM.flow.png "FBM State Flow Chart")
