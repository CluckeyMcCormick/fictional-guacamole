extends Area
tool

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
    if(properties != new_properties):
        properties = new_properties
        update_properties()

func update_properties():
    # Force the collision layer
    self.collision_layer = 16 # Bit 4, Value 16 is hazard layer
    self.collision_mask = 0 # Collides with nothing (YET!!!)
