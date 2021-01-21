# Common (Motion AI)
This directory holds all the common AI scenes and assets. There are two types of AI scenes: **Cores** and **Machines**. The *Cores* serve as the configuration interface and information store, while the *Machines* do the actual processing. By their nature, the *Cores* are reusable and generalized. *Machines* are much more specialized.

The *Cores* exist separate from the *Machines* in order to give a common configuration interface and functionality across multiple machines. Also, placing all of the appropriate configuration items on the machine level would lead to a MASSIVE configuration menu. I'd like to try and avoid that.

The *Machines* and *Cores* are designed to be as plug-and-play as possible - for example, the required *Cores* are presented as `Node` configurables for each machine. However it's impossible to completely eliminate code integration (in some instances). So, sometimes, there's a lot more plugging than playing. We'll capture the specifics, oddities, and configuration items in this documentation.

Where some amount of coding is required as part of the plugging, we typically refer to this action as "coupling"; functions created as part of coupling are referred to as "coupling functions". This is especially true for signals.

The *Machines* are somewhat unique in that they represent different phases of AI development, each preserved as separate machines. We maintain older machines for testing purposes, and as proofs-of-concept.

## KinematicCore
The *KinematicCore* is the core *motion* component of *Motion AI*. It governs the movement characteristics of an AI.

### Configurables
##### Drive Body
The *KinematicCore* provides several utility functions that are used across states - some of these require a `Node` (for an example, see *Position Function*). It is recommended this be the same node as the corresponding machine's *FSM Owner*. That's not a requirement but things could get out-of-hand otherwise.

##### Position Function
This is the most complicated configurable in the whole of the *KinematicCore*.

See, checking a `KinematicBody`'s position against a point isn't exactly trivial. Doing the check is trivial, but not deciding what kind of check to perform. See, a point could be aligned with the ground. It could be aligned with the middle of the body. It could be aligned with the body's head. It could require extra function calls to `Navigation` nodes. 

But that's outside the purview of a particular *Machine* or *Core*! That depends on the purpose and form of whatever is using the *AI*.  But we **NEED** that information for the driver to work! 

The *Position Function* configurable is the solution. Provide the name of a function, defined on the configured `KinematicBody`, and the driver will use this function to determine our current point. The function should take no arguments and return a `Vector3`. If this is not set, or is otherwise invalid, we default to using the *Drive Body's* global origin.

Even though it is difficult to configure, this is currently the best solution we have keep the *cores* and *machines* relatively scene-neutral and independent.

##### Move Speed & Fall Speed
Pretty basic - the *move speed* is how quick the KinematicBody moves, in units-per-second. The *fall speed* is how quick the KinematicBody falls when not on the floor, in units-per-second. 9.8 units/second, which is the sort of bog-standard for gravity, is the recommended fall speed.

##### Goal Tolerance
There might be instances where we don't want to stop exactly on the goal position. This configurable allows the body to stop when within a certain distance of the target, rather than being precisely at the target.

##### Float Height
This configurable allows us to float the `KinematicBody` a fixed distance above the ground. While it does make the `KinematicBody` float, this was actually intended as a mechanism for stepping-up ledges. The `KinematicBody` behaves differently depending on the current collision shape, but I was finding that running into a small step was mostly stopping the body entirely.

By shrinking the collision shape upward, and adjusting the *float height* appropriately, the body takes on an effective height but will also step upward whenever it comes to a small ledge or step.

The value is equivalent to the maximum height it is possible for the `KinematicBody` to step up.

##### Max Slope Degrees
The maximum slope angle of the body can climb, in degrees. 45 degrees is recommended, but you can do some crazy stuff with higher values.

### Constants
##### `MINIMUM_FALL_HEIGHT`
When determining whether a `KinematicBody` is on the ground or not, we do a fake move downwards. Even if the body is 100%, undeniably on the ground, this fake move usually returns a non-zero fall length. Ergo, we need an absolute minimum fall distance before we actually fall. This value is the absolute minimum distance a `KinematicBody` has to fall in the floor test to be considered "falling" or "not on the floor".

##### `TARG_DIST_HISTORY_SIZE`
In order to detect certain errors, we measure distance-to-target and store it in an array. How big is that array - i.e. how big is our history?

##### `TARG_DIST_ERROR_THRESHOLD`
Detecting the error relies on any entries recurring at least a specified number of times. This constant tracks that magic number.

## Falling Body Machine
The most basic machine. Developed as a debugging tool to so we can see how sprites sit on a surface, given certain collision models. All it does is fall/move downward.

## Kinematic Driver Machine
A step up from the *Falling Body Machine*. This machine accepts either a single point, or an array-path of points. It moves towards it's current target, and works through the current `Array` path of points. Currently only used for testing movement and environment interaction.