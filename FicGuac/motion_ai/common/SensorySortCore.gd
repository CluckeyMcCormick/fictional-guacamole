tool
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# What's our primary area
export(NodePath) var general_sensory_area setget set_general_sensory_area
# We resolve the node path into this variable.
var general_sensor

# What's our primary area
export(NodePath) var fight_or_flight_area setget set_fight_or_flight_area
# We resolve the node path into this variable.
var fof_sensor

# What's our primary area
export(NodePath) var danger_interrupt_area setget set_danger_interrupt_area
# We resolve the node path into this variable.
var danger_sensor

# We track all bodies that we've sensed in different dictionaries. One for each
# of our different tracking areas
var _general_bodies = {}
var _fof_bodies = {}
var _danger_bodies = {}

# We have one signal for when a body enters each area, and one for when the body
# exits each area.
# First, let's start with the signals for the General Sensory Area.
signal body_entered_general(body)
signal body_exited_general(body)

# Fight or Flight Area
signal body_entered_fof(body)
signal body_exited_fof(body)

# Danger Interrupt Area
signal body_entered_danger(body)
signal body_exited_danger(body)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the general sensory area we'll be working with.
func set_general_sensory_area(new_general_sensory_area):
    general_sensory_area = new_general_sensory_area
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing the general sensory area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Set the fight-or-flight area we'll be working with.
func set_fight_or_flight_area(new_fight_or_flight_area):
    fight_or_flight_area = new_fight_or_flight_area
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing the fight or flight area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

func set_danger_interrupt_area(new_danger_interrupt_area):
    danger_interrupt_area = new_danger_interrupt_area
    if Engine.editor_hint:
        update_configuration_warning()
    else:
        var warning = "Changing the danger interrupt area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the SensoryCore is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the general body - but only if we have a body to get!
    var general : Node = null
    if general_sensory_area != "":
        general = get_node(general_sensory_area)
    # Test 1: Check if we have a node
    if general == null:
        wrnstr += "No General Sensory Area specified, or path is invalid!\n"       
    # Test 2: Check if the type is right
    if not general is Area:
        wrnstr += "General Sensory Area must be an Area!\n"

    # Get the general body - but only if we have a body to get!
    var fof : Node = null
    if fight_or_flight_area != "":
        fof = get_node(fight_or_flight_area)
    # Test 1: Check if we have a node
    if fof == null:
        wrnstr += "No Fight or Flight Area specified, or path is invalid!\n"       
    # Test 2: Check if the type is right
    if not fof is Area:
        wrnstr += "Fight or Flight Area must be an Area!\n"
 
    # Get the general body - but only if we have a body to get!
    var danger : Node = null
    if danger_interrupt_area != "":
        danger = get_node(danger_interrupt_area)
    # Test 1: Check if we have a node
    if danger == null:
        wrnstr += "No Danger Interrupt Area specified, or path is invalid!\n"       
    # Test 2: Check if the type is right
    if not danger is Area:
        wrnstr += "Danger Interrupt Area must be an Area!\n"

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
    general_sensor = get_node(general_sensory_area)
    fof_sensor = get_node(fight_or_flight_area)
    danger_sensor = get_node(danger_interrupt_area)
    
    # Assert that we have a prime sensor
    assert(general_sensor != null, "General Sensor must be set as a node in the scene!")
    assert(fof_sensor != null, "Fight or Flight Sensor must be set as a node in the scene!")
    assert(danger_sensor != null, "Danger Interrupt Sensor must be set as a node in the scene!")
    
    # Connect all of the sensors to their wrapper functions
    general_sensor.connect("body_entered", self, "_on_general_sensor_body_entered")
    general_sensor.connect("body_exited", self, "_on_general_sensor_body_exited")
    fof_sensor.connect("body_entered", self, "_on_fof_sensor_body_entered")
    fof_sensor.connect("body_exited", self, "_on_fof_sensor_body_exited")
    danger_sensor.connect("body_entered", self, "_on_danger_sensor_body_entered")
    danger_sensor.connect("body_exited", self, "_on_danger_sensor_body_exited")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Integration functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# General Sensor Functions
#
func _on_general_sensor_body_entered(body):
    # Stick the body we just sensed in our "sensed_bodies" dictionary. Using the
    # node for both the key and value effectively makes the dictionary behave as
    # a set.
    _general_bodies[body] = body
    emit_signal("body_entered_general", body)

func _on_general_sensor_body_exited(body):
    # Now that the body has left our sensory area, we can remove it from the
    # dictionary.
    _general_bodies.erase(body)
    emit_signal("body_exited_general", body)

func has_bodies_general():
    # Just check and see if we have bodies
    return not _general_bodies.empty()
    
func get_bodies_general():
    # Return all of the keys. Techincally either keys or values would work.
    return _general_bodies.keys()

#
# Fight-or-Flight Sensor Functions
#
func _on_fof_sensor_body_entered(body):
    _fof_bodies[body] = body
    emit_signal("body_entered_fof", body)

func _on_fof_sensor_body_exited(body):
    _fof_bodies.erase(body)
    emit_signal("body_exited_fof", body)

func has_bodies_fof():
    return not _fof_bodies.empty()
    
func get_bodies_fof():
    return _fof_bodies.keys()

#
# Danger Sensor Functions
#
func _on_danger_sensor_body_entered(body):
    _danger_bodies[body] = body
    emit_signal("body_entered_danger", body)

func _on_danger_sensor_body_exited(body):
    _danger_bodies.erase(body)
    emit_signal("body_exited_danger", body)

func has_bodies_danger():
    return not _danger_bodies.empty()
    
func get_bodies_danger():
    return _danger_bodies.keys()
