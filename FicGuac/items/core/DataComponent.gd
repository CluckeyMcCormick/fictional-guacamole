extends Spatial

# The rotation of the item when it is being stored and stowed.
export(String) var _resource_string setget set_resource_string
var _resource

# The group strings, typically of a particular item. Stored here so we the group
# strings can be dynamically updated on the Physics Item - then, the tags can be
# carried through the VisualItemShell
var _group_strings = []

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Godot Processing - _ready, _process, etc.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ready():
    # Load the brand new resource. We do this in the _ready string to avoid
    # loading this resource again when we spawn the Physics Item scene as a
    # replacement.
    _resource = load(_resource_string)

# --------------------------------------------------------
#
# Setters
#
# --------------------------------------------------------
func set_resource_string(new_resource_string):
    # Set the new rotation
    _resource_string = new_resource_string
    
    # If we're not in the Editor...
    if not Engine.editor_hint:
        var msg = "Updating the Resource Item String during runtime is not "
        msg += " recommended. Also, it doesn't work. It's mostly a configurable"
        msg += " that should be constructed/decided ahead of time."
        push_warning(msg)

# --------------------------------------------------------
#
# Utility functions
#
# --------------------------------------------------------
func assert_groups(node : Node):
    # First, clear all the groups from the Node
    for grp in node.get_groups():
        node.remove_from_group(grp)
    
    # Then, add all of the groups we have to this Node
    for grp in self._group_strings:
        node.add_to_group(grp)
