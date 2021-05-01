# Actions
This directory holds our various actions. Each action is a single *XSM* `State` and provides a common interface.

These actions exist so that we don't need to constantly duplicate code for common actions. This will help keep things consistent between tasks, which will further keep things consistent between different machines and AI constructs.

A couple of quick notes about the current design philosophy of actions:

1. *Actions should be very specialized. They should do one thing and one thing only.*
	- For example, an action may be dropping an item, or grabbing an item, or moving to a very particular position. Another way to look at it is that states must be *atomic*, as actions are the lowest level breakdown of what an AI can do.
	
2. *Actions should generally accept a singular input.*
	- Whereas tasks should be designed to do multiple things, actions - being atomic - should only accept singular inputs. It is the responsibility of the task to chain actions together as needed.

3. *Actions should never repeat. They must succeed or they must fail.*
	- Again, this relates to the atomic nature of actions. It is up to the tasks that are *composed* of actions to decide what actions bear repeating.

4. *Actions must hard fail or hard succeed. No partial conclusions.*
	- Because actions are atomic, they must either fail or succeed. There can be no partial conditions. Anything that could "partially" fail or succeed is a bad candidate for an action, and could probably be decomposed into several separate actions.

Actions may or may not be error-tolerant. Your decision.

### Core
This directory stores the Core scenes that make up the *Action*'s core interface.  See this directory for further explanation of the interface quirks of Actions. 

## Drop All Item
This action drops all the items currently being held by the integrating body. Note that this drops the items in their physical form.

This action starts at the top of the stack and drops them in their physical form.

This action succeeds once all items have been dropped, or if there were no items to drop at all.

### Configurables
##### All Items At Once
We can either drop all of the items at once, or once-per-update for a nice step-by-step.

### Signals
This task has the standard `action_success` and `action_failure` signals, as defined by the *Action Template*.

## Flee All Body
This action flees all of a given type of item in a given area. Fleeing is different from moving - when a body flees, it moves in a direction away from a given set of bodies. Rather than succeeding when it reaches a destination, it succeeds when the bodies are no longer in the area.

This action will fail if it cannot path or the body gets stuck too much.

### Configurables
##### Priority Area
The machine's sensory *priority area* that we're tracking bodies in. Once there are no flee-bodies in this area, the action succeeds.

This interfaces with the *Sensory Sort Core* to provide common behavior across unique sensory areas.

##### Group Category
The *group category* of bodies we're attempting to flee.

This interfaces with the *Sensory Sort Core* to provide common behavior to different categories of stimuli across unique machines. 

##### Dynamic Flee Vector
Generally, the *Flee All Body* action only decides on a new direction once it's moved a given distance. If this option is enabled, the action will dynamically update every-time a new signal of *Group Category* enters a *Priority Area*.

### (Public) Variables

##### `flee_distance`
An `int`, representing how far we flee each time we flee. This needs to be set by an integrating task, since it should change depending on the size of the integrating body.

Beware! Setting the `flee_distance` to a low value will cause the integrating body to more frequently stop and evaluate the flee direction. If the integrating body is fleeing something, this will allow that "something" to catch up pretty quickly.

Also, keep in mind that this is the distance an integrating body will *attempt* to move. It may move a smaller distance if it can't go any farther.

### Signals
This task has the standard `action_success` and `action_failure` signals, as defined by the *Action Template*.

## GrabItem
This action will grab a single item, adding it to the *Item Management Core*'s stack.

This action will fail if it cannot grab the item.

### (Public) Variables

##### `_target_entity`
A `Node`, specifically one deriving from our `MasterItem` scene. This is the item we will attempt to grab. Providing a non-`MasterItem` node will most likely crash the game.

### Signals
This task has the standard `action_success` and `action_failure` signals, as defined by the *Action Template*.

## MoveToEntityPriorityArea
This action attempts to move towards an entity, stopping when the entity enters a specified *Priority Area*. This is useful for tying together actions with the specific ranges at which that action can occur - for example, a ranged character moving until an enemy is at the edge of it's general awareness. Or any character moving to it's interaction range to interact with an item.

This action will fail if the integrating body cannot path, gets stuck too many times, or reaches the item without detecting it.

Note that this item must fall under an integrating body's *Group Categories* otherwise it won't detect it and will fail!

### Configurables
##### Priority Area
The machine's sensory *priority area* that we're watching. If the desired item enters this area, the action will succeed.

This interfaces with the *Sensory Sort Core* to provide common behavior across unique sensory areas.

### (Public) Variables

##### `_target_entity`
A `Node`, specifically a physics node of some kind - such that these nodes can be detected by the *Priority Area*.

### Signals
This task has the standard `action_success` and `action_failure` signals, as defined by the *Action Template*.

## MoveToPosition
This action attempts to move the integrating body to a specific position. That's all - it just moves it!

This action will fail if the integrating body cannot path or gets stuck too many times.

### (Public) Variables

##### `_target_position`
A `Vector3` - the global coordinate that we will attempt to move the integrating body to.

### Signals
This task has the standard `action_success` and `action_failure` signals, as defined by the *Action Template*.