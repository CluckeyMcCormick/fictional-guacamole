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
