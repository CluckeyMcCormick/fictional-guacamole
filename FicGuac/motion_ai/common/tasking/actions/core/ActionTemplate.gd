extends State

# Get the machine's root; we need access to some of the configurables and
# signals and the like. Grab that from the parent class (which should be a Task
# (I hope))
onready var MR = get_parent().MR

# We need to communicate with the Physics Travel Region, so grab that from the
# parent class (which should be a Task of some sort!!!)
onready var PTR = get_parent().PTR

# Signal for whenever this action succeeds
signal action_success()

# Signal for whenever this action fails. It is up to the task to decide whether
# this constitutes a failure or not.
signal action_failure(failure_code)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Utility Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This functions effectively resets this action by simulating a state exit and
# enter. You can provide arguments for each call as needed. Note that this isn't
# done for children - for this reason, child states are not recommended for
# actions.
func simulated_reset(before_arg=null, exit_arg=null, enter_arg=null, after_arg=null):
    # If this action is not active, don't do the reset. That could mess things
    # up. 
    if not self.active:
        return
    # Simulate an exit
    self._before_exit(before_arg)
    self._on_exit(exit_arg)
    # Simulate an enter
    self._on_enter(enter_arg)
    self._after_enter(after_arg)
