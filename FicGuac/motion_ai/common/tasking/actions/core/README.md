# Core (Action)
This directory contains the core components for our various *actions*.

## Action Template
This is the scene from which all other actions should be derived (inherited). It provides a common interface that will make using actions much simpler.

Note that the `MR` and `PTR` variables rely on the action being the immediate child of a *Task* node. Ergo, all actions must be immediate children of a *task* in order to function and not crash the game.

To actually implement an action, you need to implement at least one of *XSM*'s "abstract public functions":

```python
#  func _on_enter(args) -> void:
#  func _after_enter(args) -> void:
#  func _on_update(_delta) -> void:
#  func _after_update(_delta) -> void:
#  func _before_exit(args) -> void:
#  func _on_exit(args) -> void:
#  func _on_timeout(_name) -> void:
```

Any combination of functions will work, as long as the action works.

Unlike tasks, actions need clearly delineated success or failure. The action must fail or succeed. If you've designed an action that can somehow partially succeed, then that's not an action - it's a simplified task. Actions are really the most discrete, atomic possible breakdown of doing something.

It is not recommended to allow actions to have children states.

### Variables
Although we would not normally document purely internal variables, I felt that it was important to cover the variables available to a task - to express what was inherited, what was unique to an action, and what to expect these values to be.

##### `MR`
The *Machine Root* of this task's parent-machine. This variable offers access to the various configurables of the current machine - especially the *cores*.

##### `PTR`
The *Physics Travel Region* of this task's parent-machine. This region changes very little between different machines and is critical for moving an integrating body (and responding to completed movements).

##### `target`
When correctly integrated into a task, this will be the parent-machine's integrating body. This variable is inherited from *XSM*'s `State` class.

### Functions
##### `simulated_reset`
This resets an action by calling the action's *XSM* exit and enter factions (see above). In this way, it effectively resets the function. This function is very useful for when the current action in a task needs to be repeated after success - maybe the variables need to updated, or we're trying something *X* number of times as error handling.

This should work perfectly **so long as the action has no child states**. That's a **very fundamental assumption** that *should not be broken*. If your action needs to have a child state to work, then it must be something incredibly complicated and would likely be better as a series of separate actions.

Now, since there a four *XSM* transition functions that must be called in order to reset an *XSM* state, there are four arguments to this function:

- `before_arg`: Argument supplied to the `_before_exit` function.
- `exit_arg`: Argument supplied to the `_on_exit` function.
- `enter_arg`: Argument supplied to the `_on_enter` function.
- `after_arg`: Argument supplied to the `_after_enter` function.

All of these arguments are optional; they default to *null* if not provided.

### Signals
##### `action_success`
This signal indicates that the action succeeded.

##### `action_failure`
This signal indicates that the action failed.