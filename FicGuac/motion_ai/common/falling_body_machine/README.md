# Kinematic Driver Machine
The most basic way to impress a sense of intelligence upon an artificial object is to give it movement.

This is the most basic machine. It blindly moves towards a target.

### Configurables
This machine features the standard configurable items for a machine `State` (see the *addons* directory for more, and the *statechart* subdirectory for EVEN MORE).

##### FSM Owner
As with every machine, the *FSM Owner* is required to be a `KinematicBody` node.

##### Kinematic Core
We require a `KinematicCore` node to define the movement profile for this machine.

### (Public) Variables
##### `target_position`
The current target position. Whether or not this is safe to mess with will change with whatever *Machine* you are using, as each uses them in different ways.

##### `_curr_orient`
A `Vector3`, where each axis is the current (rough) heading on each axis. The number is actually equivalent to the last updated velocity on each axis - however, it should only really be used to gauge "heading" or "orientation".

The values are irregularly updated in order to preserve continuity between states. This is particularly necessary for our sprites, which require an angle calculated from this `Vector3`. If this were to reset to (0, 0, 0) when not moving, the sprites would jerk into a common direction when at rest. Always.

### Signals
##### `target_reached`
Indicates that we reached our target position. The `target_position` variable is cleared before the signal is emitted. The previous target position is given as a signal argument, just in case it is needed.

##### `error_microposition_loop`
There was an observed issue with the older *KinematicDriver* node where it was consistently undershooting and overshooting it's target position. This resulted in an infinite loop of the driver's body rapidly vibrating back and forth in microscopic steps.

If we detect this occurrence, the `error_microposition_loop` signal is fired along with the current target position. This gives us an opportunity to handle the problem when it occurs.

Exactly why and where this happens is harder to pin down. I've noticed that it tends to happen at the intersection of edges - the edge of a navigation mesh that lies along a y-height difference-edge. I suspect it's got something to do with the interaction between the driver body's collision model, the *KinematicCore*'s floating stuff, and where the navigation mesh seems to think we are. It doesn't seem to happen as often with drive bodies that have smooth collision models (i.e. NOT SQUARES) so I recommend using something like a capsule.

This error has been observed firing when the driver body is doing something as simple as running into a wall. It serves its purpose well enough for now, but it might need to be adjusted later on.

##### `visual_update`
While the *Extended States Machine* suggests supplying a animation node, and doing EVERYTHING through that, we're holding off on that for now. That method isn't exactly compatible with our usage of `AnimatedSprite3D`. So instead, we offer a more general solution - states in the machine are free to emit the `visual_update` signal at will; it is up to the scene integrating this machine to update the visuals appropriately.

There are two arguments emitted with this signal. First is the `animation_key`, which indicates the type of animation that needs to be played. It will be something like "walk", "idle", "single\_swing", "single\_stab", etc.

The next argument is an orientation `Vector3`, `curr_orientation`. This indicates the heading/direction/facing of the *FSM Owner* at the time the signal is emitted. For this machine, it's a straight copy of the `_curr_orient` field.

### State Composition
Excluding the root state, there are four other states: 

1. *Falling*
1. *OnGround*
1. *Walk*
1. *Idle*

The *OnGround* state is a super state containing the *Walk* and *Idle* states. This can be observed in the arrangement of the states in the scene:

![Image](./doc_images/KDM.hierarchy.png "KDM Tree")

The machine defaults to the *Idle* state. If `target_position` is not null, we will move towards it via the *Walk* state. Once we reach the target position, we will clear `target_position`, emit a `target_reached` signal. If a `target_position` is not set, we will revert to the *Idle* state.

Meanwhile, the *OnGround* state is constantly probing downwards to ensure we are on the ground. If we aren't on the ground for whatever reason, the subordinate states are interrupted and we move to the *Falling* state.

While in the *Falling* state, the only thing we do is fall. That's it.

The `visual_update` signal is regularly emitted throughout the *Falling*, *Idle*, and *Walk* states.

This whole process can be observed in this image:

![Image](./doc_images/KDM.flow.png "KDM Tree")

Note that the *OnGround* state contains the *Idle* and *Walk* states.