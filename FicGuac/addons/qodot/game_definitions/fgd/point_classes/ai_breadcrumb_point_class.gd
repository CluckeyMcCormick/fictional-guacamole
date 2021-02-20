extends Spatial
tool

export(Dictionary) var properties setget set_properties

var _internal_group = ""

func set_properties(new_properties : Dictionary) -> void:
    if(properties != new_properties):
        properties = new_properties
        update_properties()

func update_properties():
    if "group_name" in properties:
        # Remove this node from the old group
        self.remove_from_group(_internal_group)
        
        # Retrieve the property
        _internal_group = properties["group_name"]
        
        # Add this node to the new group, with persistence enabled
        self.add_to_group(_internal_group, true)
