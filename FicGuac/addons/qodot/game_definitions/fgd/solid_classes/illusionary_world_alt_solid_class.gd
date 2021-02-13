extends Spatial
tool

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
    if(properties != new_properties):
        properties = new_properties
        update_properties()

func update_properties():
    # This solid class has no use for properties.
    pass

# When we enter the scene...
func _ready():
    # Look through our children for meshes
    for possible_mesh in self.get_children():
        # If it's not a mesh, skip it!
        if not possible_mesh is Mesh:
            continue
        # If it is, set the visual layers to Obstacle Alternate
        possible_mesh.layers = 4 # Obstacle Alternate, Bit 2, Value 4
