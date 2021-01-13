tool
extends State
# This is an empty template for an inherited States of XSM
# In this class, you can call the public functions:
# change_state("MyState")
#   "MyState" is the name of a State
# is_active("MyState") -> bool
#   returns true if a state "MyState" is active in this xsm
# play("Anim")
#   plays the animation "anim" of the State's AnimationPlayer
# stop()
#   stops the current animation
# is_playing("Anim) -> bool
#   returns true if "Anim" is playing
# add_timer("Name", time) -> Timer
#   adds a timer named "Name" and returns this timer
#   when the time is out, the function _on_timeout(_name) is called
# del_timer("Name")
#   delete the timer "Name"
# is_timer("Name") -> bool
#   returns true if there is a Timer "Name" running in this State
#
# FUNCTIONS AVAILABLE TO INHERIT
#
#func _on_enter() -> void:
#	pass
#
#func _after_enter() -> void:
#	pass
#
#func _on_update(_delta) -> void:
#	pass
#
#func _after_update(_delta) -> void:
#	pass
#
#func _before_exit() -> void:
#	pass
#
#func _on_exit() -> void:
#	pass
#
#func _on_timeout(_name) -> void:
#	pass
