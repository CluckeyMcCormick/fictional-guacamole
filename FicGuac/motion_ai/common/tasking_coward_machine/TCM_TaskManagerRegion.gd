extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable & Signal Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Signal for whenever this task succeeds. Wrapper for the same signal coming
# from the TaskTemplate (or other such implementing node).
signal current_task_succeeded(task)

# Signal issued when this task has hard failed and needs to be somehow handled.
# Wrapper for the same signal coming from the TaskTemplate (or other such
# implementing node).
signal current_task_failed(task)

# The current task we are working on. Should be this state's singular child
# (though the task itself can have as many children as it wants)
var current_task = null

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func remove_current_task():
    # If we don't have a current task, back out
    if current_task == null:
        return
    
    # Remove the task-child
    self.remove_child(current_task)
    
    # Detach the signal functions - important that we do this after removing the
    # task as a child (since that would call the _on_exit function)
    current_task.disconnect("task_succeeded", self, "_on_current_task_succeeded")
    current_task.disconnect("task_failed", self, "_on_current_task_failed")
    
    # Free the task-child
    current_task.queue_free()
    # We HAVE NO TASK-CHILD
    current_task = null

func set_new_task(new_task):
    # If we still have a task, REMOVE IT
    if current_task != null:
        remove_current_task()
    
    # We now own this task
    new_task.owner = self
    
    # Hook up our signals - important that we do this before adding the task as
    # a child (since that would call the _ready/_on_enter functions)
    new_task.connect("task_succeeded", self, "_on_current_task_succeeded")
    new_task.connect("task_failed", self, "_on_current_task_failed")

    # We are it's parent, too - AND IT IS OUR CHILD
    self.add_child(new_task)
    # This is now our current task
    current_task = new_task

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Capture Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _on_current_task_succeeded():
    emit_signal("current_task_succeeded", current_task)

func _on_current_task_failed():
    emit_signal("current_task_failed", current_task)
