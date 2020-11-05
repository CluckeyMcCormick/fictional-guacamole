tool
extends Spatial

# Wrapper for the label text, so we don't have to go down to the label just to
# edit something
export(String, MULTILINE) var label_text = "Sample Text" setget set_label_text

export(Vector2) var quad_size = Vector2(5, 1) setget set_quad_size

export(int) var gui_scale = 50 setget set_gui_scale

func set_label_text(new_text):
    # If we don't have a label to set, then back out
    if not $Viewport/CenterGUI/Label:
        return
    label_text = new_text    
    
    # Otherwise, it's just fire and forget
    $Viewport/CenterGUI/Label.text = new_text

func set_quad_size(new_size):
    # If we don't have a label to set, then back out
    if not $Quad or not $Viewport or not $Viewport/CenterGUI:
        return
        
    quad_size = new_size    
    
    # Now, adjust for minimums
    if quad_size.x < .05:
        quad_size.x = .05
    if quad_size.y < .05:
        quad_size.y = .05
    
    # Set that size!
    $Quad.mesh.size = quad_size
    
    # Now the set the size for the Viewport and CenterGUI
    $Viewport.size = quad_size * gui_scale
    $Viewport/CenterGUI.rect_size = quad_size * gui_scale

func set_gui_scale(new_scale):
    # If we don't have a label to set, then back out
    if not $Viewport or not $Viewport/CenterGUI:
        return
        
    # Capture the current
    # First, just set the value
    gui_scale = new_scale
    
    if gui_scale < 1:
        gui_scale = 1
    
    # Now the set the size for the Viewport and CenterGUI
    $Viewport.size = quad_size * gui_scale
    $Viewport/CenterGUI.rect_size = quad_size * gui_scale
