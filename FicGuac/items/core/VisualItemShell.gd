class_name VisualItem
extends Spatial

# --------------------------------------------------------
#
# Getter
#
# --------------------------------------------------------
# Is the current item 3D? This only exists because getting the child node under
# this would be tough to work out in whatever node handles this one
func is_3D():
    return $VisualComponent.is_3D

# --------------------------------------------------------
#
# Utility Functions
#
# --------------------------------------------------------
func initialize(visual, data):
    # Add in the data and visual components
    self.add_child(visual)
    self.add_child(data)
    visual.set_owner(self)
    data.set_owner(self)
    
    # If the visual component is 3D, we use the offset translation - just to
    # make sure things look right.
    if visual.is_3D:
        self.translation = visual.visualized_offset_3D

func _to_physical_item():
    # First, get our visual and data nodes
    var visual = $VisualComponent
    var data = $DataComponent
    
    # If we don't have one of those, then something's off. Just return null so
    # whatever called this function knows something messed up.
    if visual == null or data == null:
        return null
    
    # Create a new physical instance
    var physical_instance = data._resource.instance()
    
    # Detach the visual and data components
    self.remove_child(visual)
    self.remove_child(data)
    
    # Initialize the physical instance
    physical_instance.initialize(visual, data)
    
    # Free ourselves from our own parent
    self.get_parent().remove_child(self)
    
    # Free the visual item
    self.queue_free()
    
    # Return the visual instance
    return physical_instance
