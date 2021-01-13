tool
extends EditorPlugin


func _enter_tree():
     add_custom_type("State", "Node", preload("state.gd"), preload("icon_statecharts.png"))
     pass





func _exit_tree():
     remove_custom_type("State")
     pass
