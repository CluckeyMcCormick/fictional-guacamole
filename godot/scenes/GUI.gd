extends MarginContainer

# Whenever the wheel "button" is pressed or released, we'll send out these
# signals (as appropriate). Basically just a passthrough of the wheel's
# signal
signal wheel_press
signal wheel_release

# Grab our "LAYPROC" label. We'll hide the text depending on whether the
# fictional laying process is enabled or disabled
onready var layproc_label = $BoxMargins/BoxDivider/WheelMaster/Label_LAYPROC

# Called when the node enters the scene tree for the first time.
func _ready():
    layproc_label.hide()

# What do we do when the wheel is pressed?
func _on_Wheel_button_down():
    layproc_label.show()
    emit_signal("wheel_press")

# What do we do when the wheel is released?
func _on_Wheel_button_up():
    layproc_label.hide()
    emit_signal("wheel_release")
