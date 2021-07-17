# Tasking (Tasks)
This directory holds our various tasks - miniature *XSM* machines that chain together prewritten action states with some decision making code that are then integrated on-the-fly with the proper AI machines. That's a bit of an ecosystem-level appraisal - they're actually a lot easier to understand and implement then that scary sentence makes it seem.

As stated, each one of these tasks is an *XSM* machine. The primary purpose of the *Tasks* is to handle decision making that is too low-level or minute-to-minute to be handled by the *Goal Region* of a given machine. It also allows for individual actions to be semantically grouped together.

For example - let's say the *Goal Region* of a particular machine wants to pick up a particular item. What if the item got moved by a physics action? What if the AI got stuck? And where do we execute the pick up? The detection? The constant manipulation and checking of the *Physics Travel Region*? It wouldn't be right to handle such minutia in the *Goal Region*, and it would probably lead to a lot of copy-paste code. You can generally copy-paste things two or three times before divergence - better to avoid it all together!

Tasks are specifically designed to alleviate that burden. We dispatch tasks and they tell us whether they succeeded or failed. It is then up to the *Goal Region* to decide the next course of action.

A couple of quick notes about the current design philosophy of tasks:

1. *Tasks should include setup actions. Do not assume the intended actions can be executed immediately.*
	- For example, say we need to pick up an item. Rather than the task consisting of *just* a grab action, the task should consist of a preemptive drop action, a move-into-range action (sometimes called a range-in), and THEN the grab action.
	- It is the responsibility of tasks to handle the setup for a given task. The *Goal Region* will not handle this.
2. *Tasks should generally accept plural inputs.*
	- For example, say we need to pick up an item. It may be tempting to have two tasks, where one targets just one item and the other only targets multiple items. This is a waste of effort - the multiple item task (which takes *plural input*) will naturally be more robust and can easily be overloaded to only work with a single item.
3. *Tasks should not repeat infinitely. They must succeed or they must fail.*
	- It is the responsibility of the *Goal Region* to assess whether repeating a task or doing a different task is appropriate. The task should not repeat infinitely.
	- The only issue with this design element is that, since XSM states operate in Godot's `_physics_process` loop, frequently repeating a task by recreating it and restarting it can sometimes result in milliseconds of downtime for an AI. That's not a problem when picking up an item, but it's definitely a problem when an AI is attempting to flee a pursuing danger. Because of that, some tasks have the potential to repeat forever (though it probably wouldn't happen).
4. *Tasks should be robust enough to deal with changing game state.*
	- What I'm really trying to say is to not fail a task immediately if there's potential to recover. For example, an AI may not be able to act on a particular entity but could try other entities in it's list.
5. *Tasks may hard fail, soft fail, or hard succeed. There are no soft successes.*
	- In this instance, a "soft failure" is a partial success. In other words, when a task succeeds, it succeeds wholly. Otherwise, it fails. This helps makes processing for the *Goal Region* much easier, since we only have to evaluate the extent of any failures. And we'd have to do anyway, so it works out perfectly!

### Actions
In order to make the tasks as consistent as possible with one another, this directory contains *Action* nodes, which are meant to be the building blocks for *Tasks*.

### Core
This directory stores the Core scenes that make up the *Task*'s core interface.  See this directory for further explanation of the interface quirks of Tasks. 

## Flee Immediate Threat
This task flees all *Threat* bodies in a machine's *Fight-or-Flight* area. If new *Threat*s enter the *Fight-or-Flight* area, the task adjusts appropriately.

If the integrating body escapes the *Threat* bodies, it succeeds. If the integrating body gets stuck, it fails.

### Constants
##### `AK_FLEE_DISTANCE`
Constant argument-key for the flee distance. See `specific_initialize` for more.

### Functions
##### `specific_initialize`
Initializes the task's specific/unique variables.

- `arg_dict`: The dictionary of arguments specific to this task. Should contain the following key/values:
 - `AK_FLEE_DISTANCE`: The flee distance, in game units. Every time the task flees it 	moves this distance before reassessing the best path (or it at least ATTEMPTS to). 			If this value is too small this may result in the integrating body rapidly 					stuttering and losing ground to whatever it is fleeing.

### Signals
This task has the standard `task_succeeded` and `task_failed` signals, as defined by the *Task Template*.

## Move Item Drop Multi
This task moves a provided set of items to a provided point. It expects the given items to be physical items and will drop them at the provided point as physical items.

The task will prioritize closest items first, and will stack as many items as possible. It will make as many trips as necessary.

If it successfully grabs and moves all items, the task will succeed. Otherwise, it will fail, regardless of how many items it managed to move.

### Constants
##### `AK_ITEMS_LIST`
Constant argument-key for the list/Array of items we're trying to pick up. See `specific_initialize` for more.
##### `AK_DROP_POSITION`
Constant argument-key for where we'll drop the items. See `specific_initialize` for more.

### Functions
##### `initialize`
Initializes the task's specific/unique variables.

- `arg_dict`: The dictionary of arguments specific to this task. Should contain the following key/values:
 - `AK_ITEMS_LIST`: A Godot `Array` of item nodes. Any nodes that do not match the game's defined item type will be ignored.
 - `AK_DROP_POSITION`: A Godot `Vector3`. This is the position in global space that we'll move the items to.

### Signals
This task has the standard `task_succeeded` and `task_failed` signals, as defined by the *Task Template*.

## Wander Random
This task moves in a random direction. One time. Just once, not repeating or anything. And that's it. That's all it does.

If the integrating body moves correctly, it succeeds. If the integrating body gets stuck, it fails.

### Constants
##### `AK_WANDER_DISTANCE`
Constant argument-key for the distance we'll wander in one direction. See `specific_initialize` for more.

### Functions
##### `initialize`
Initializes the task's specific/unique variables.

- `arg_dict`: The dictionary of arguments specific to this task. Should contain the following key/values:
 - `AK_WANDER_DISTANCE`: The wander distance, in game units. The task will attempt to move this far as part of the wander action.

### Signals
This task has the standard `task_succeeded` and `task_failed` signals, as defined by the *Task Template*.
