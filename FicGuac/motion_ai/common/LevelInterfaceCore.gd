tool
extends Node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Variable Declarations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# In order to navigate the world, we need a dedicated mesh to work against. What
# mesh-node will we use?
export(NodePath) var navigation_node setget set_navigation_node
# We resolve the node path into this variable.
var nav_node

# When our machine drops items, we need a parent to place the items under. What
# should that item be?
export(NodePath) var item_parent_node setget set_item_parent_node
# We resolve the node path into this variable.
var item_node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Setters and Getters
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Set the navigation node. Unlike most cores, we actually resolve the node path
# whenever it gets set. Also updates our configuration warning.
func set_navigation_node(new_navigation_node):
    navigation_node = new_navigation_node
        
    # If we're in the engine, update our configuration warning
    if Engine.editor_hint:
        update_configuration_warning()
    # Otherwise, update the nav node
    else:
        nav_node = get_node(navigation_node)

# Set the item parent node. Unlike most cores, we actually resolve the node path
# whenever it gets set. Also updates our configuration warning.
func set_item_parent_node(new_item_parent_node):
    item_parent_node = new_item_parent_node
    
    # If we're in the engine, update our configuration warning
    if Engine.editor_hint:
        update_configuration_warning()
    # Otherwise, update the drop node
    else:
        item_node = get_node(item_parent_node)

# This function is very ugly, but it serves a very specific purpose: it allows
# us to generate warnings in the editor in case the KinematicDriver is
# misconfigured.
func _get_configuration_warning():
    # (W)a(RN)ing (STR)ing
    var wrnstr= ""
    
    # Get the navigation node - but only if we have a node to get!
    if navigation_node != "":
        nav_node = get_node(navigation_node)

    # Test 1: Check if we have a navigation node
    if nav_node == null:
        wrnstr += "No Navigation Node specified, or path is invalid!\n"
        wrnstr += "Level Interface Core does allow for runtime configuration\n"
        wrnstr += "via set_navigation_node if preconfiguring is impractical.\n"

    # Get the item drop parent node - but only if we have a node to get!
    if item_parent_node != "":
        item_node = get_node(item_parent_node)

    # Test 2: Check if we have a item parent node
    if item_node == null:
        wrnstr += "No Item Parent Node specified, or path is invalid!\n"
        wrnstr += "Level Interface Core does allow for runtime configuration\n"
        wrnstr += "via set_item_parent_node if preconfiguring is impractical.\n"
    
    return wrnstr

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ready():
    # If we have a navigation node...
    if navigation_node:
        # Get it! This may not have been resolved yet, since this node may have
        # not been in the scene tree before now
        nav_node = get_node(navigation_node)

    # If we have an item parent node...
    if item_parent_node:
        # Get it! This may not have been resolved yet, since this node may have
        # not been in the scene tree before now
        item_node = get_node(item_parent_node)

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
    if nav_node is Navigation:
        adjusted = nav_node.get_closest_point(curr_pos)
    
    # Otherwise, if it's a spatial, we don't have any recourse but to ASSUME
    # that we're dealing with a DetourNavigationMesh.
    elif nav_node is Spatial:
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
        push_warning("LIC couldn't get adjusted position due to invalid/null nav_node.")
    
    return adjusted

func path_between(from : Vector3, to : Vector3):
    var path

    # If we're using a navigation node, we can just use get_simple_path. Easy!
    if nav_node is Navigation:
        # Get the path
        path = Array(nav_node.get_simple_path(from, to))
    
    # Otherwise, if it's a spatial, we don't have any recourse but to ASSUME
    # that we're dealing with a DetourNavigationMesh.
    elif nav_node is Spatial:
        # Get the path
        path = nav_node.find_path(from, to)
        path = Array(path["points"])
    
    # Otherwise... Guess I have no idea what's happening. Let's just not path.
    else:
        path = []
        push_warning("LIC couldn't generate path because of invalid/null nav_node.")
        
    return path
