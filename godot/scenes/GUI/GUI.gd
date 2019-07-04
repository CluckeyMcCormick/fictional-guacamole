extends MarginContainer

"""
This script / class is entirely registering methods that allow external
nodes access to specific internal signals. 

As far as I can tell, there's now way to do a "Pass-Through" or "Boost"
of a signal to make it visible outside of it's respective scene - so
we'll use this registration method instead.
"""

onready var wheel_master = $BoxMargins/BoxDivider/WheelMaster

# Registers the "wheel_velocity_changed" signal with the provided node
# and function.
func register_wheel_velocity(target_node, target_function):
    wheel_master.connect("wheel_velocity_changed", target_node, target_function)