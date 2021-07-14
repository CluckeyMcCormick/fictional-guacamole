# Common (Motion AI)
This directory holds all the common AI scenes and assets. There are two types of AI scenes: **Cores** and **Machines**. The *Cores* serve as the configuration interface and information store, while the *Machines* do the actual processing. By their nature, the *Cores* are reusable and generalized. *Machines* are much more specialized.

The *Cores* exist separate from the *Machines* in order to give a common configuration interface and functionality across multiple machines. Also, placing all of the appropriate configuration items on the machine level would lead to a MASSIVE configuration menu. I'd like to try and avoid that.

The *Machines* and *Cores* are designed to be as plug-and-play as possible - for example, the required *Cores* are presented as `Node` configurables for each machine. However it's impossible to completely eliminate code integration (in some instances). So, sometimes, there's a lot more plugging than playing. We'll capture the specifics, oddities, and configuration items in this documentation.

Where some amount of coding is required as part of the plugging, we typically refer to this action as "coupling"; functions created as part of coupling are referred to as "coupling functions". This is especially true for signals.

The *Machines* are somewhat unique in that they represent different phases of AI development, each preserved as separate machines. We maintain older machines for testing purposes, and as proofs-of-concept.

### Falling Body Machine
The most basic machine. Developed as a debugging tool to so we can see how sprites sit on a surface, given certain collision models. All it does is fall/move downward.

### Kinematic Driver Machine
A step up from the *Falling Body Machine*. This machine accepts either a single point, or an array-path of points. It moves towards it's current target, and works through the current `Array` path of points. Currently only used for testing movement and environment interaction.

### Rat Emulation Machine
This machine builds from the *Kinematic Driver Machine* - the path following has been internalized and the machine now generates its own paths. The machine features several states that control the pawn's pathing and movement, independent of the states that *actually perform* the movement. It can wait, it can wander around, and it can flee from danger. It's a big step forward for the AI.

### Tasking Coward Machine
This machine is an evolution from the *Rat Emulation Machine* - that rat machine was good, but it wasn't easily extensible. If we wanted the machine to do something specific, we had to program in a specific goal state just to deal with it. This didn't seem sustainable to me, so I revised how the machine was constructed.

The machine now operates by issuing itself tasks, which handle the lower level moment-to-moment processing. This creates different levels that allow us to effectively handle high and low level AI processing (and everything in between).

### Tasking
A key component of our main series of AI is the use of tasks - little machines that can be inserted into certain larger machines and perform moment-to-moment decisions. Each task has a common interface but implementation is largely up to the individual tasks themselves.

## GroupSortMatrix
We identify different spatial elements in this game - hazards, items, projectiles, Motion AI, etc - using Godot's `Node` *Groups*. They're the closest things Godot has to some sort meta-tagging system. In order to build a robust motion AI system, we can't just use global tags (that'd be a bit painful managing global strings like that, anyhow). No, instead we need a way to group tags into universal categories, and leave it up to an integrating body to decide which groups fall into which category.

This custom (scripted) resource provides an interface for listing which groups fall under which category.

### Configurables
We have one configurable for each *Group Category*.

##### Threat Groups
A `PoolStringArray`. Each string should be a group that an integrating body treats as a *Threat*. Threats are different from enemies, representing a danger that can't be addressed and should instead be fled from.

##### Goal Groups
A `PoolStringArray`. Each string should be a group that an integrating body treats as a *Goal*. Goals are just a temporary grouping for anything and everything good. We'll expand it into multiple categories later.

## KinematicCore
The *KinematicCore* is the core *motion* component of *Motion AI*. It governs the movement characteristics of an AI.

### Configurables

##### Fallback Move Speed & Fall Speed
Pretty basic - the *fallback move speed* is how quick the KinematicBody moves, in units-per-second. This is a fallback since more complex move speed (i.e. influenced by status effects) is supposed to be provided by the CharacterCore. The *fall speed* is how quick the KinematicBody falls when not on the floor, in units-per-second. 9.8 units/second, which is the sort of bog-standard for gravity, is the recommended fall speed.

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

## PathingInterfaceCore
The *PathingInterface* is the core that allows the *Motion AI* to navigate the map independent of any other externalities. It provides configurables for an easy cross-machine interface, as well as several utility functions to allow any machine to path or check it's position.

Unfortunately, because this node requires access to a *Navigation* node of some description, and those almost invariably exist outside of any integrating bodies, there will likely be some integration code required.

### Configurables
##### Navigation Node
The node we'll use to navigate the world - can either be a vanilla Godot `Navigation` node or a `DynamicNavigationMesh` node from *Milos Lukic's* *Godot Navigation Light*.

If you're having trouble decoding what node that's really supposed to be, just remember that it's the node that actually has the pathing functions attached to it.

This configurable is a `NodePath` - since any navigation resource will typically exist outside of an integrating body, you will likely need to do a hot/runtime configuration, most likely in some parent node's `_ready` function. I recommend getting the full `NodePath` by calling the `get_path` function on the appropriate node.

### Functions
##### `get_adjusted_position`
Returns the position of the given spatial node on the core's *Navigation Node* configurable.

##### `path_between`
Returns an `Array`-path of points that start at `from_point` and go to `to_point`. May return an empty path.

## SensorySortCore
The *SensorySort* is the core *sensory* component of *Motion AI*. It handles sensing (observing nearby physics bodies) and sorting (identifying the type of body). Think of it like a radar that both detects things and identifies those things.

This core uses multiple `Area` nodes to do the appropriate sensing. It is assumed that the nodes are nested, starting with the largest external and moving to the smallest internal node. Using multiple nested areas in this way allows us to create a sort of "priority" structure.

It sorts these inputs into the different *Group Categories* using a *GroupSortMatrix* resource.

### Configurables
##### General Sensory Area
The primary sensory area. Needs to be a 3D `Area` node. Used for sensing anything and everything, then sorting those inputs appropriately. Has the lowest priority, and should be the largest of the areas. It should contain the other two areas.

This configurable does not support runtime configuration. It is updated once, when the `_ready()` function is called.

##### Fight or Flight Area
The secondary sensory area. Needs to be a 3D `Area` node. Called *Fight or Flight* because certain entities entering or exiting this area should trigger a flight or flight response in AI. Has higher priority than the *General Sensory Area*, and should be smaller than it too.

This configurable does not support runtime configuration. It is updated once, when the `_ready()` function is called.

##### Danger Interrupt Area
The primary sensory area. Needs to be a 3D `Area` node. This area has the highest priority and should be the smallest area. It's meant to capture *imminent* threats that need to interrupt and override whatever the integrating body is doing. Ergo, it should be just a bit bigger than the actual collision model of the integrating body.

This is really here to stop the integrating body from, say, walking into fire.

This configurable does not support runtime configuration. It is updated once, when the `_ready()` function is called.

##### Group Sort Matrix
In order to sort the different bodies detected into the the *Group Categories*, the *SensorySortCore* relies on a *GroupSortMatrix* resource.

Unlike other configurables, this one does support runtime value changes. Swapping out this resource will trigger a reappraisal of all tracked objects. The *SensorySortCore* will send out signals as though the bodies were just being discovered. Depending on the number of nodes, categories, and group names, this could have some major memory-processing overhead.

### Constants
Bodies need to be tracked, retrieved, and emitted with their area and group categories. To provide a common interface, the *SensorySortCore* defines constants for the *priority area* and the *group category*.

##### `PRI_AREA_GENERAL`
Constant-key for the *General Sensory* priority-area.

##### `PRI_AREA_FOF`
Constant-key for the *Fight or Flight* priority-area.

##### `PRI_AREA_DANGER`
Constant-key for the *Danger Interrupt* priority-area.

##### `GC_GOAL`
Constant-key for the *Goal* group category.

##### `GC_THREAT`
Constant-key for the *Threat* group category.

### Functions
##### `get_bodies`
Returns an array of the currently tracked body `Node`s. Each entry in the array will be unique. Requires

##### `has_bodies`
Returns a *boolean* value, indicating whether the core is currently tracking bodies or not.

### Signals
##### `body_entered`
Emitted when a body enters the *Primary Sensor Area*. Emits the detected body with it. Basically a wrapper for the same signal from the *Primary Sensor Area*.

##### `body_exited`
Emitted when a body exits the *Primary Sensor Area*. Emits the detected body with it. Basically a wrapper for the same signal from the *Primary Sensor Area*.
