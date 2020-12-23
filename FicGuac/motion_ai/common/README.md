# Common (Motion AI)
This directory holds all the common AI scenes and assets - mostly the actual programmatic AI scenes, or the "brains-in-jars".

Each "brain" is designed to be as plug-and-play as possible, but it's impossible to completely eliminate code integration (in some instances). So, sometimes, there's a lot more plugging than playing. We'll capture the specifics, oddities, and configuration items in this documentation.

Where some amount of coding is required as part of the plugging, we typically refer to this action as "coupling"; functions created as part of coupling are referred to as "coupling functions". This is especially true for signals.

## KinematicDriver
The *KinematicDriver* is the core *motion* component of *Motion AI*. It allows us to easily build a `KinematicBody` that a) moves at all and b) moves in the exact way we tell it to.

This scene exists because there's actually a lot code that relates to how characters move and collide with the world. It was originally all integrated into Pawn, but I realized that meant we'd have to copy-paste the code to anything that we wanted to move. We want all characters - be they player, NPC, or something dumb that exists between those states - to be able to move easily and consistently.

The *KinematicDriver* works by using a `KinematicBody`'s methods to push the body towards a specified goal. The driver handles any *movement* difficulties that could arise - scaling a slope, stepping up a ledge, moving through the open, running straight into a wall, etc.

Note that the *KinematicDriver* handles *movement*, not *pathing*. The points must, currently, be fed into the *KinematicDriver* one at a time as it reaches each point. Pathing is outside the scope of what I want the driver to handle, so pathing should be part of the integration code, or a separate brain.

### Configurables
##### Drive Body
As part of the set-up process, the *KinematicDriver* needs a `KinematicBody` to move and collide around. If we aren't provided a node, or it's not a `KinematicBody`, the game **will** crash. So no need to worry about misconfiguring that particular item: once the game has stopped crashing, you know you did it right. :grinning:

##### Position Function
This is the most complicated configurable in the whole of the *KinematicDriver*.

In order to check whether we are at our target position, we default to using the `KinematicBody`'s global origin. However, it's pretty rare that whatever point we've been handed actually aligns with the body's global origin. This is especially true if the point came from a navigation mesh. 

However, pathing - and thus detecting our position on a navigation mesh - is outside the driver's area of responsibility. But we **NEED** that information for the driver to work!

The *Position Function* configurable is the solution. Provide the name of a function, defined on the configured `KinematicBody`, and the driver will use this function to determine our current point. The function should take no arguments and return a `Vector3`.

Even though it is difficult to configure, this is currently the best solution we have keep the driver relatively self-contained.

##### Move Speed & Fall Speed
Pretty basic - the *move speed* is how quick the KinematicBody moves, in units-per-second. The *fall speed* is how quick the KinematicBody falls when not on the floor, in units-per-second. 9.8 units/second, which is the sort of bog-standard for gravity, is the recommended fall speed.

##### Goal Tolerance
There might be instances where we don't want to stop exactly on the goal position. This configurable allows the body to stop when within a certain distance of the target, rather than being precisely at the target.

##### Float Height
This configurable allows the driver to float the `KinematicBody` a fixed distance above the ground. While it does make the `KinematicBody` float, this was actually intended as a mechanism for stepping-up ledges. The `KinematicBody` behaves differently depending on the current collision shape, but I was finding that running into a small step was mostly stopping the body entirely.

By shrinking the collision shape upward, and adjusting the *float height* appropriately, the body takes on an effective height but will also step upward whenever it comes to a small ledge or step.

The value is equivalent to the maximum height it is possible for the `KinematicBody` to step up.

##### Max Slope Degrees
The maximum slope angle of the body can climb, in degrees. 45 degrees is recommended, but you can do some crazy stuff with higher values.

### (Public) Variables
##### `target_position`
The current target position. When set to `null`, the driver will not move the body. Set to a `Vector3` to start moving towards that point.

##### `_combined_velocity`
A `Vector3`, where each axis is the current velocity on that axis. Updated every time `_physics_process` is called. Setting this value most likely does nothing, but it could mess with other functions that rely on this value so it is NOT recommended.

##### `_is_moving`
A `bool` - tracks whether we are moving or not. Effectively means x, y, or z in `_combined_velocity` does not equal zero. Updated every time `_physics_process` is called. 

##### `_on_floor`
A `bool` - tracks whether we are on the floor or not. Updated every time `_physics_process` is called. 

### Signals
##### `target_reached`
Indicates that we reached our target position. The `target_position` variable is cleared before the signal is emitted. The previous target position is given as a signal argument, just in case it is needed.

##### `error_microposition_loop`
There is an observed issue with the *KinematicDriver*, where it will consistently undershoot and overshoot it's target position. This results in an infinite loop of the driver's body rapidly vibrating back and forth in microscopic steps. When we detect this occurrence, the `error_microposition_loop` signal is fired along with the current target position. This gives us an opportunity to handle the problem when it occurs.

Exactly why and where this happens is harder to pin down. I've noticed that it tends to happen at the intersection of edges - the edge of a navigation mesh that lies along a y-height difference-edge. I suspect it's got something to do with the interaction between the driver body's collision model, the *KinematicDriver*'s floating stuff, and where the navigation mesh seems to think we are. It doesn't seem to happen as often with drive bodies that have smooth collision models (i.e. NOT SQUARES) so I recommend using something like a capsule or cylinder.