tool
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each driver needs a node to move around - what node will this drive move?
export(NodePath) var navigation_node setget set_navigation_node
# We resolve the node path into this variable.
var nav_node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the drive body. Unlike most cores, we actually resolve the node path
# whenever it gets set. Also updates our configuration warning.
func set_navigation_node(new_navigation_node):
    navigation_node = new_navigation_node
    nav_node = get_node(navigation_node)
    
    print("New navigation node path: ", new_navigation_node)
    print("Node actual: ", nav_node)
    
    if Engine.editor_hint:
        update_configuration_warning()

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the KinematicDriver is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the body - but only if we have a body to get!
    if navigation_node != "":
        nav_node = get_node(navigation_node)
    
    # Test 1: Check if we have a node
    if nav_node == null:
        wrnstr += "No Navigation Node specified, or path is invalid!\n"
        wrnstr += "Pathing Interface Core does allow for runtime configuration\n"
        wrnstr += "via set_navigation_node if preconfiguring is impractical.\n"
    
    return wrnstr

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Core functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Get the "algorithmic" position. This is most often used for goal checking -
# i.e. seeing where we are from a world-mesh perspective
func get_adjusted_position(in_body : Spatial):
    # Get our current position
    var curr_pos = in_body.global_transform.origin
    # What's our adjusted vector?
    var adjusted = Vector3.ZERO
    
    # If we're using a navigation node, we can just use get_closest_point. Easy!
    if typeof(nav_node) == typeof(Navigation):
        adjusted = nav_node.get_closest_point(curr_pos)
    
    # Otherwise, if it's a spatial, we don't have any recourse but to ASSUME
    # that we're dealing with a DetourNavigationMesh.
    elif typeof(nav_node) == typeof(Spatial):
        # This mesh doesn't actually give us a method to easily access where we
        # are on the mesh. So, we'll cheat. We'll just path FROM our current
        # position TO our current position. I don't know the performance
        # ramifications of this, but HOPEFULLY its small. Or some update saves
        # us from this madness...
        adjusted = nav_node.find_path(curr_pos, curr_pos)
        # Unpack what we got back, since we want the first value of a
        # PoolVector3 array stored in a dict.
        adjusted = Array(adjusted["points"])[0]
    
    # Otherwise... Guess I have no idea what's happening. Let's just use the
    # current position.
    else:
        adjusted = curr_pos
    
    return adjusted

func path_between(from : Vector3, to : Vector3):
    var path

    # If we're using a navigation node, we can just use get_closest_point. Easy!
    if typeof(nav_node) == typeof(Navigation):
        # Get the path
        path = Array(nav_node.get_simple_path(from, to))
        # Okay, for some reason Godot's vanilla navigation starts with the END
        # point (to) at the FRONT of the array. I don't know why. To get around
        # that, we'll invert the array.
        path.invert()
    
    # Otherwise, if it's a spatial, we don't have any recourse but to ASSUME
    # that we're dealing with a DetourNavigationMesh.
    elif typeof(nav_node) == typeof(Spatial):
        # Get the path
        path = nav_node.find_path(from, to)
        path = Array(path["points"])
    
    # Otherwise... Guess I have no idea what's happening. Let's just use the
    # current position.
    else:
        path = []
        
    return path
