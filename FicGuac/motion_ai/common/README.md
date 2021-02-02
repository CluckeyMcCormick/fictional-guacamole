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

##### Tolerance Error Step
There was an observed issue with the older *KinematicDriver* node where it was consistently undershooting and overshooting it's target position. This resulted in an infinite loop of the driver's body rapidly vibrating back and forth in microscopic steps. We called this the *Microposition Loop Error*.

We now handle this error by slowly increasing the goal tolerance. We do so in a series of steps, until we either reach our goal or decide we're well and truly stuck.

Every time we need to increment the effective goal tolerance, we go up by this amount.

> Exactly why and where this happens is harder to pin down. I've noticed that it tends to happen at the intersection of edges - the edge of a navigation mesh that lies along a y-height difference-edge. I suspect it's got something to do with the interaction between the driver body's collision model, the *KinematicCore*'s floating stuff, and where the navigation mesh seems to think we are. It doesn't seem to happen as often with drive bodies that have smooth collision models (i.e. NOT SQUARES) so I recommend using something like a capsule. It also seems to have something to do with a body that moves too quickly.

##### Float Height
This configurable allows us to float the `KinematicBody` a fixed distance above the ground. While it does make the `KinematicBody` float, this was actually intended as a mechanism for stepping-up ledges. The `KinematicBody` behaves differently depending on the current collision shape, but I was finding that running into a small step was mostly stopping the body entirely.

By shrinking the collision shape upward, and adjusting the *float height* appropriately, the body takes on an effective height but will also step upward whenever it comes to a small ledge or step.

The value is equivalent to the maximum height it is possible for the `KinematicBody` to step up.

##### Max Slope Degrees
The maximum slope angle of the body can climb, in degrees. 45 degrees is recommended, but you can do some crazy stuff with higher values. Also note that the behavior when the slope matches the angle *exactly* can be a bit odd. Usually a body will be able to climb a slope but not without glitching around a bit. Ergo a plus-or-minus buffer of 1 degree is recommended.

##### Fall State Delay Time
Once we enter a fall state, we're hard locked into it, and whatever machine we've integrated with will stop moving horizontally. However, we don't always want to transition to a fall state. Could you imagine if you locked up or did a ragdoll flop every time you stepped off a curb? No, that's no good.

So, we have a time delay. This many seconds of uninterrupted falling and we'll transition to the fall state.

### Constants
##### `MINIMUM_FALL_HEIGHT`
When determining whether a `KinematicBody` is on the ground or not, we do a fake move downwards. Even if the body is 100%, undeniably on the ground, this fake move usually returns a non-zero fall length. Ergo, we need an absolute minimum fall distance before we actually fall. This value is the absolute minimum distance a `KinematicBody` has to fall in the floor test to be considered "falling" or "not on the floor".

##### `TARG_DIST_HISTORY_SIZE`
In order to detect certain errors (i.e. Microposition Loop, Stuck, etc.), we measure distance-to-target and store it in an array. How big is that array - i.e. how big is our history?

##### `TARG_DIST_ERROR_THRESHOLD`
Detecting certain errors relies on any entries recurring at least a specified number of times. This constant tracks that magic number.

##### `MAX_TOLERANCE_ITERATIONS`
Once we've detected certain errors, we slowly increment the goal tolerance using a set step value (see the *Tolerance Error Step* configurable). However, we only do that as many times specified by this constant before we just assume that we're stuck. How exactly that's handled depends on the implementation of the machine.

##### `ERROR_DETECTION_PRECISION`
Because movement in Godot has a precision of ~6 decimal places, our error detection could be hit or miss if we were looking for EXACT matches. Instead, we'll round the history entries (and our checks) to this decimal position, using the `stepify()` function. This simplifies error checking and makes it more robust.

## SensorySortCore
The *SensorySort* is the core *sensory* component of *Motion AI*. It handles sensing (observing nearby physics bodies) and sorting (identifying the type of body). Think of it like a radar that both detects things and identifies those things.

### Configurables

##### Primary Sensory Area
The primary sensory area. Needs to be a 3D `Area` node. Eventually there will be multiple categories of sensory areas to elicit different responses. For now, there's just this one.

### Functions
##### `get_bodies`
Returns an array of the currently tracked body `Node`s. Each entry in the array will be unique.

##### `has_bodies`
Returns a *boolean* value, indicating whether the core is currently tracking bodies or not.

### Signals
##### `body_entered`
Emitted when a body enters the *Primary Sensor Area*. Emits the detected body with it. Basically a wrapper for the same signal from the *Primary Sensor Area*.

##### `body_exited`
Emitted when a body exits the *Primary Sensor Area*. Emits the detected body with it. Basically a wrapper for the same signal from the *Primary Sensor Area*.

## Falling Body Machine
The most basic machine. Developed as a debugging tool to so we can see how sprites sit on a surface, given certain collision models. All it does is fall/move downward.

## Kinematic Driver Machine
A step up from the *Falling Body Machine*. This machine accepts either a single point, or an array-path of points. It moves towards it's current target, and works through the current `Array` path of points. Currently only used for testing movement and environment interaction.

## Rat Emulation Machine
This machine builds from the *Kinematic Driver Machine* - the path following has been internalized and the machine now generates its own paths. The machine features several states that control the pawn's pathing and movement, independent of the states that *actually perform* the movement. It can wait, it can wander around, and it can flee from danger. It's a big step forward for the AI.