tool
class_name SensorySortCore
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Pri(ority) Area constants. Used to communicate priority (i.e. which area was
# entered) in our signals.
enum PRI_AREA { GENERAL = 0, FOF = 1, INTERACT = 2, DANGER = 3 }

# G(roup) C(ategory) constants - we use this to communicate the type of body
# that has just been sensed.
enum {
    GC_GOAL = 0, GC_THREAT = 1
}

# What's our General Sensory area? This is the broadest area, made for detecting
# any and all objects.
export(NodePath) var general_sensory_area setget set_general_sensory_area
# We resolve the node path into this variable.
var general_sensor

# What's our Fight-or-Flight area? This is a smaller area, meant to catch
# imminent dangers to an integrating body. So named because it should trigger a
# fight-or-flight response.
export(NodePath) var fight_or_flight_area setget set_fight_or_flight_area
# We resolve the node path into this variable.
var fof_sensor

# What's our interaction range area? Smaller than the fight-or-flight area,
# this area is just for detecting when an item, interactble, or even another
# agent is in reach - in other words, when entites can be interacted with.
export(NodePath) var interaction_range_area setget set_interaction_range_area
# We resolve the node path into this variable.
var interact_sensor

# What's our Danger Interrupt area? This is the smallest area - it should be
# barely bigger than the integrating body's collision shape. This is to stop it
# from, say, walking into a fire.
export(NodePath) var danger_interrupt_area setget set_danger_interrupt_area
# We resolve the node path into this variable.
var danger_sensor

# The GroupSortMatrix that helps the SensorySortCore do the "sorting" part of
# it's job. 
export(Resource) var group_sort_matrix setget set_group_sort_matrix

# We track all bodies that we've sensed in this variable. This monsterous
# variable. This is a dictionary of dictionaries of dictionaries. Each Priority
# Area gets its own dictionary. These priority area dictionaries contain
# dictionaries for each group category. These general-category dictionaries are
# what actually contain the bodies. Because this data structure is so
# complicated, please use the has_bodies and get_bodies function - as well as
# the signals - to monitor and check what bodies the sensory sort core is
# tracking.
var _bodies = {}

# Signals for whenever a body enters or exits one of the areas we're tracking.
# Provides the body, the priority area (a constant, shows which area it
# entered) and the group category (a constant, shows what category the body is).
# This will only emit ONCE for a body entering an area - only the highest
# priority group catergory will be emitted.
signal body_entered(body, priority_area, group_category)
signal body_exited(body, priority_area, group_category)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the general sensory area we'll be working with.
func set_general_sensory_area(new_general_sensory_area):
    var old_val = general_sensory_area
    
    general_sensory_area = new_general_sensory_area
    if Engine.editor_hint:
        update_configuration_warning()
    elif old_val == null:
        var warning = "Changing the general sensory area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Set the fight-or-flight area we'll be working with.
func set_fight_or_flight_area(new_fight_or_flight_area):
    var old_val = fight_or_flight_area
    
    fight_or_flight_area = new_fight_or_flight_area
    if Engine.editor_hint:
        update_configuration_warning()
    elif old_val == null:
        var warning = "Changing the fight or flight area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Set the interaction area we'll be working with.
func set_interaction_range_area(new_interaction_range_area):
    var old_val = interaction_range_area
    
    interaction_range_area = new_interaction_range_area
    if Engine.editor_hint:
        update_configuration_warning()
    elif old_val == null:
        var warning = "Changing the interaction range area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Set the danger interrupt area we'll be working with.
func set_danger_interrupt_area(new_danger_interrupt_area):
    var old_val = danger_interrupt_area
    
    danger_interrupt_area = new_danger_interrupt_area
    if Engine.editor_hint:
        update_configuration_warning()
    elif old_val == null:
        var warning = "Changing the danger interrupt area during runtime is "
        warning += "not recommended. Also, it doesn't do anything."
        push_warning(warning)

# Sets the group sort matrix. Triggers a re-appraisal of the currently tracked
# bodies becuase theses bodies may fall under new categories.
func set_group_sort_matrix(new_group_sort_matrix):
    # Set it!
    group_sort_matrix = new_group_sort_matrix
    # Update our configuration warning (if applicable)
    if Engine.editor_hint:
        update_configuration_warning()
    
    # Let's run a check real quick - if the _bodies dict is empty, then
    # something has gone wacky and trying to check it will just be pointless
    # (not to mention crashy). So, if the _bodies dict is empty, just regenerate
    # and then back out
    if _bodies.empty():
        _bodies = _generate_empty_body_dict()
        return
    
    # Okay, now we have to do our reappraisal. First, we're gonna put all of the
    # bodies out of the _bodies dictionary into these sets, separated by the
    # priority area.
    var wd_general = {}
    var wd_fof = {}
    var wd_interact = {}
    var wd_danger = {}
    
    for subdict_key in _bodies[PRI_AREA.GENERAL]:
        for body in _bodies[PRI_AREA.GENERAL][subdict_key]:
            wd_general[body] = body

    for subdict_key in _bodies[PRI_AREA.FOF]:
        for body in _bodies[PRI_AREA.FOF][subdict_key]:
            wd_fof[body] = body

    for subdict_key in _bodies[PRI_AREA.INTERACT]:
        for body in _bodies[PRI_AREA.INTERACT][subdict_key]:
            wd_interact[body] = body
         
    for subdict_key in _bodies[PRI_AREA.DANGER]:
        for body in _bodies[PRI_AREA.DANGER][subdict_key]:
            wd_danger[body] = body

    # Next, reset the bodies dictionary
    _bodies = _generate_empty_body_dict()

    # Now, we'll go through and add the bodies, starting with the general
    # sensory priority and working up to the danger priority.
    for body in wd_general:
        _add_body(body, PRI_AREA.GENERAL)

    for body in wd_fof:
        _add_body(body, PRI_AREA.FOF)

    for body in wd_interact:
        _add_body(body, PRI_AREA.INTERACT)
        
    for body in wd_general:
        _add_body(body, PRI_AREA.DANGER)

# Technically this "gets" a new dict. Technically not a getter - SUE ME!
func _generate_empty_body_dict():
    # The priority area keys
    var pri_area_keys = [
        PRI_AREA.GENERAL, PRI_AREA.FOF, PRI_AREA.INTERACT, PRI_AREA.DANGER
    ]
    # The group category keys
    var group_cat_keys = [ GC_GOAL, GC_THREAT ]
    
    # The dictionary we're working in
    var make_dict = {}
    
    # For each priority area...
    for PAK in pri_area_keys:
        # Make a dictionary
        make_dict[PAK] = {}
        # Then, for each group category...
        for GCK in group_cat_keys:
            # put ANOTHER dictionary in there
            make_dict[PAK][GCK] = {}
    
    # Return the awful frankenstein we've made
    return make_dict
  
# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the SensoryCore is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the general area - but only if we have a area to get!
    var general : Node = null
    if general_sensory_area != "":
        general = get_node(general_sensory_area)
    # Test 1: Check if we have a node
    if general == null:
        wrnstr += "No General Sensory Area specified, or path is invalid!\n"
    # Test 2: Check if the type is right
    if not general is Area:
        wrnstr += "General Sensory Area must be an Area!\n"

    # Get the figt or flight area - but only if we have a area to get!
    var fof : Node = null
    if fight_or_flight_area != "":
        fof = get_node(fight_or_flight_area)
    # Test 3: Check if we have a node
    if fof == null:
        wrnstr += "No Fight or Flight Area specified, or path is invalid!\n"
    # Test 4: Check if the type is right
    if not fof is Area:
        wrnstr += "Fight or Flight Area must be an Area!\n"

    # Get the interaction area - but only if we have a area to get!
    var interact : Node = null
    if interaction_range_area != "":
        interact = get_node(interaction_range_area)
    # Test 5: Check if we have a node
    if interact == null:
        wrnstr += "No Interaction Range Area specified, or path is invalid!\n"
    # Test 6: Check if the type is right
    if not interact is Area:
        wrnstr += "Interaction Range Area must be an Area!\n"

    # Get the danger body - but only if we have a body to get!
    var danger : Node = null
    if danger_interrupt_area != "":
        danger = get_node(danger_interrupt_area)
    # Test 7: Check if we have a node
    if danger == null:
        wrnstr += "No Danger Interrupt Area specified, or path is invalid!\n"
    # Test 8: Check if the type is right
    if not danger is Area:
        wrnstr += "Danger Interrupt Area must be an Area!\n"

    # Test 9: Check if a resource was actually provided for the group sort
    # matrix
    if group_sort_matrix == null:
        wrnstr += "No Group Sort Matrix found!\n"
    # Test 10: Ensure the resource is actually a GroupSortMatrix
    elif not group_sort_matrix is GroupSortMatrix:
        wrnstr += "Group Sort Matrix must be a GroupSortMatrix resource!\n"

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
        
    # Put together the _bodies dict
    _bodies = _generate_empty_body_dict()
        
    # Get the different sensor nodes we'll be monitoring.
    general_sensor = get_node(general_sensory_area)
    fof_sensor = get_node(fight_or_flight_area)
    interact_sensor = get_node(interaction_range_area)
    danger_sensor = get_node(danger_interrupt_area)
    
    # Assert that we have all of the sensors we'll need.
    assert(general_sensor != null, "General Sensor must be set as a node in the scene!")
    assert(fof_sensor != null, "Fight or Flight Sensor must be set as a node in the scene!")
    assert(interact_sensor != null, "Interaction Sensor must be set as a node in the scene!")
    assert(danger_sensor != null, "Danger Interrupt Sensor must be set as a node in the scene!")
    # Assert that we have the Group Sort Matrix
    assert(group_sort_matrix != null, "Group Sort Matrix resource required!")
    
    # Connect all of the sensors to their wrapper functions
    general_sensor.connect("body_entered", self, "_on_general_sensor_body_entered")
    general_sensor.connect("body_exited", self, "_on_general_sensor_body_exited")
    fof_sensor.connect("body_entered", self, "_on_fof_sensor_body_entered")
    fof_sensor.connect("body_exited", self, "_on_fof_sensor_body_exited")
    interact_sensor.connect("body_entered", self, "_on_interact_sensor_body_entered")
    interact_sensor.connect("body_exited", self, "_on_interact_sensor_body_exited")
    danger_sensor.connect("body_entered", self, "_on_danger_sensor_body_entered")
    danger_sensor.connect("body_exited", self, "_on_danger_sensor_body_exited")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Integration functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Sensor-signal Response Functions
#
func _on_general_sensor_body_entered(body):
    _add_body(body, PRI_AREA.GENERAL)

func _on_general_sensor_body_exited(body):
    _remove_body(body, PRI_AREA.GENERAL)

func _on_fof_sensor_body_entered(body):
    _add_body(body, PRI_AREA.FOF)
    
func _on_fof_sensor_body_exited(body):
    _remove_body(body, PRI_AREA.FOF)

func _on_interact_sensor_body_entered(body):
    _add_body(body, PRI_AREA.INTERACT)
    
func _on_interact_sensor_body_exited(body):
    _remove_body(body, PRI_AREA.INTERACT)

func _on_danger_sensor_body_entered(body):
    _add_body(body, PRI_AREA.DANGER)

func _on_danger_sensor_body_exited(body):
    _remove_body(body, PRI_AREA.DANGER)

func _get_group_category_strings(group_category):
    
    var strings
    
    match group_category:
        GC_GOAL:
            strings = group_sort_matrix.goal_groups
        GC_THREAT:
            strings = group_sort_matrix.threat_groups
    
    return strings

#
# Add and Remove Body Utility Functions
#
func _add_body(body, priority_area):
    # We only emit a "body_entered" signal once, even if a body exists in
    # multiple group categories. The highest priority group category is the
    # category that gets emitted.
    var already_emitted = false
    
    # Iterate over our categories, in order of priority.
    for category in [GC_THREAT, GC_GOAL]:
        
        # If the body has already been tracked at this priority area and group
        # category, then skip this category. This will prevent us from sending
        # redundant entry and exit signals - believe it or not, that could have
        # some dangerous consequences...
        if body in _bodies[priority_area][category]:
            continue
        
        # For each string (each group name) in this current category...
        for curr_grp_str in _get_group_category_strings(category):
            # If this body is a member of that group...
            if body.is_in_group(curr_grp_str):
                # Stick it in the appropriate body bucket
                _bodies[priority_area][category][body] = body
                # Emit the signal! ...if we haven't already
                if not already_emitted:
                    emit_signal("body_entered", body, priority_area, category)
                    already_emitted = true
                # Break out of the category strings loop - we only needed
                # membership in ONE of the goal groups for this to be valid.
                break;

func _remove_body(body, priority_area):
    var already_emitted = false
    
    # Iterate over our categories, in order of priority. Higher priority goes
    # first.
    for category in [GC_THREAT, GC_GOAL]:
        
        # If the body has already been removed at this priority area and group
        # category, then skip this category. This will prevent us from sending
        # redundant entry and exit signals - believe it or not, that could have
        # some dangerous consequences...
        if not body in _bodies[priority_area][category]:
            continue
        
        # For each string (each group name) in this current category...
        for curr_grp_str in _get_group_category_strings(category):
            # If this body is a member of that group...
            if body.is_in_group(curr_grp_str):
                # Stick it in the appropriate body bucket
                _bodies[priority_area][category].erase(body)
                # Emit the signal! ...if we haven't already
                if not already_emitted:
                    emit_signal("body_exited", body, priority_area, category)
                    already_emitted = true
                # Break out of the category strings loop - we only needed
                # membership in ONE of the goal groups for this to be valid.
                break;

#
# Body Status Check Functions
#
func has_bodies(priority_area, group_category):
    # Just check and see if we have bodies for the given priority area and group
    # category.
    return not _bodies[priority_area][group_category].empty()

func has_specific_body(body, priority_area):
    # Iterate over our categories
    for category in [GC_THREAT, GC_GOAL]:
        # If the body exists in this category,
        if body in _bodies[priority_area][category]:
            # Then we found it! Return true
            return true
    # Otherwise... Nope! No body! Return false
    return false

func get_bodies(priority_area, group_category):
    # Return all of the keys for the given priority area and group category.
    # Techincally either keys or values would work.
    return _bodies[priority_area][group_category].keys()

