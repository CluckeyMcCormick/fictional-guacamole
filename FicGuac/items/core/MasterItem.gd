class_name MasterItem
extends RigidBody

onready var visual_scene = preload("res://items/core/VisualItemShell.tscn")

# --------------------------------------------------------
#
# Utility Functions
#
# --------------------------------------------------------
func initialize(new_visual, new_data):
    # First, get our visual and data nodes
    var visual = $VisualComponent
    var data = $DataComponent

    # If we have a visual component, remove and destroy it
    if visual != null:
        self.remove_child(visual)
        visual.queue_free()
    
    # If we have a data component, remove and destroy it
    if data != null:
        self.remove_child(data)
        data.queue_free()
        
    # Add in the data and visual components
    self.add_child(new_visual)
    self.add_child(new_data)
    new_visual.set_owner(self)
    new_data.set_owner(self)

    # Assert the groups
    new_data.assert_groups(self)
    
    # All done!

func _to_visual_item():
    # First, get our visual and data nodes
    var visual = $VisualComponent
    var data = $DataComponent
    
    # If we don't have one of those, then something's off. Just return null so
    # whatever called this function knows something messed up.
    if visual == null or data == null:
        return null
    
    # Save the groups
    data._group_strings = self.get_groups()
    
    # Create a new visual instance
    var visual_instance = visual_scene.instance()
    
    # Detach the visual and data components
    self.remove_child(visual)
    self.remove_child(data)
    
    # Initialize the visual instance
    visual_instance.initialize(visual, data)
    
    # Free ourselves from our own parent
    self.get_parent().remove_child(self)
    
    # Free the physical item
    self.queue_free()
    
    # Return the visual instance
    return visual_instance
