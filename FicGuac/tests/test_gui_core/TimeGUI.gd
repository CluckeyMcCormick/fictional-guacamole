extends VBoxContainer

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Signal Handlers
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

func _on_Slider_value_changed(value):
    $TimeScale/Value.text = str(value)
    Engine.set_time_scale(value)


func _on_TimeGUI_tree_exiting():
    # Reset the time scale so that other things don't get messed up by this GUI
    # nonsense.
    Engine.set_time_scale(1.0)
