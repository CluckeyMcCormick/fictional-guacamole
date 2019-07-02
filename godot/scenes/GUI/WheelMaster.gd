extends Control

# Is our "Laying Process" engaged (are we)?
var layproc_engaged = false

# Grab our "LAYPROC" label. We'll hide the text depending on whether the
# fictional laying process is enabled or disabled
onready var layproc_label = $Label_LAYPROC

# Called when the node enters the scene tree for the first time.
func _ready():
    # Ensure our 
    layproc_label.hide()
    layproc_engaged = false

# What do we do when the wheel is pressed?
func _on_TraverseWheel_button_down():
    layproc_label.show()
    layproc_engaged = true

# What do we do when the wheel is released?
func _on_TraverseWheel_button_up():
    layproc_label.hide()
    layproc_engaged = false

func _input(event):
    # If lay process isn't engaged or the event isn't a mouse motion, then back out
    if not layproc_engaged or not event is InputEventMouseMotion:
        return
    