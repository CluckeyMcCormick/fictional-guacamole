extends StateRoot

# The machine's root. Should be passed in via the _template_initialize function.
var MR

# The machine's physics travel region. Should be passed in via the
# _template_initialize function.
var PTR

# Signal for whenever this task succeeds
signal task_succeeded()

# Signal for whenever this task fails. Note that this is a hard failure for the
# task, and will probably result in a task reassignment (or something similar)
signal task_failed()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Initialize Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# We have THREE initialization functions. Yes that's confusing BUT we sometimes
# we need to initialize different components of the task at different times. So
# we have three: 

# This function initializes the template's variables. The variables passed here
# are essentially coupling variables - variables that allow us to interface with
# /connect to the host machine. Ergo, this function should be called by the 
# host machine!
func template_initialize(machine_root, physics_travel_region, target_body):
    # Set our machine root and physics travel region
    self.MR = machine_root
    self.PTR = physics_travel_region

    # Ensure the owner-target corresponds to the target body
    self.fsm_owner = target_body.get_path()
    self.target = target_body

# This function initializes those variables that are specific to the current
# task. It frequently requires input from the world - like a list of specific
# items, or a specific target. This can be called from within the host
# machine, but we may want to call it from outside the machine and then
# inject/pass the task into the machine.
func specific_initialize(arg_dict):
    print("Task Template Specific Initialize called, please overload.")

# ~~~
# This third initialization function is actually just a convenience version of
# the earlier functions - bound together into a single function call. For those
# instances where we can initialize both at the same time. This is what should
# be called if we're not doing any fancy task-injection.
func initialize(machine_root, physics_travel_region, target_body, arg_dict):
    template_initialize(machine_root, physics_travel_region, target_body)
    specific_initialize(arg_dict)
