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

# Initialize the template's variables
func _template_initialize(machine_root, physics_travel_region, target_body):
    # Set our machine root and physics travel region
    self.MR = machine_root
    self.PTR = physics_travel_region

    # Ensure the owner-target corresponds to the target body
    self.fsm_owner = target_body.get_path()
    self.target = target_body

