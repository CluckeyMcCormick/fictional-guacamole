tool
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# What's our primary area
export(NodePath) var primary_sensory_area setget set_primary_sensory_area
# We resolve the node path into this variable.
var prime_sensor

# We track all bodies that we've sensed in this dictionary
var _sensed_bodies = {}

# Signal issued when a body enters our primary sensory area. Basically a
# re-signal of the exact same primary_sensory_area signal
signal body_entered(body)
# Signal issued when a body exits our primary sensory area. Basically a
# re-signal of the exact same primary_sensory_area signal
signal body_exited(body)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the position function. Mostly here so we can validate the configuration in
# the editor
func set_primary_sensory_area(new_primary_sensory_area):
    primary_sensory_area = new_primary_sensory_area
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing the primary sensory area during runtime is \n"
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Returns an array, listing the bodies we've just sensed
func get_bodies():
    return self._sensed_bodies.values()

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the SensoryCore is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the body - but only if we have a body to get!
    var prime : Node = null
    if primary_sensory_area != "":
        prime = get_node(primary_sensory_area)
    
    # Test 1: Check if we have a node
    if prime == null:
        wrnstr += "No Primary Sensory Area specified, or path is invalid!\n"       
    
    # Test 2: Check if we have a
    if not prime is Area:
        wrnstr += "Primary Sensory Area must be an Area!\n"
    
    return wrnstr

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Called when the node enters the scene tree for the first time.
func _ready():
    # Back out if we're in the editor
    if Engine.editor_hint:
        return
        
    # Get the prime sensor
    prime_sensor = get_node(primary_sensory_area)
    
    # Assert that we have a prime sensor
    assert(prime_sensor != null, "Prime Sensor must be set as a node in the scene!")
    
    # Connect up the prime sensor to our tracking functions.
    prime_sensor.connect("body_entered", self, "_on_prime_sensor_body_entered")
    prime_sensor.connect("body_exited", self, "_on_prime_sensor_body_exited")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Integration functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_prime_sensor_body_entered(body):
    # Stick the body we just sensed in our "sensed_bodies" dictionary. Using the
    # node for both the key and value effectively makes the dictionary behave as
    # a set.
    _sensed_bodies[body] = body
    emit_signal("body_entered", body)

func _on_prime_sensor_body_exited(body):
    # Now that the body has left our sensory area, we can remove it from the
    # dictionary.
    _sensed_bodies.erase(body)
    emit_signal("body_exited", body)

func has_bodies():
    return not _sensed_bodies.empty()
