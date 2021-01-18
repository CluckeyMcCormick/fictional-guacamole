# MIT LICENSE Copyright 2020 Etienne Blanc - ATN
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
tool
class_name State
extends Node

# To use this plugin, you should inherit this class to add scripts to your nodes
# This kind of an implementation https://statecharts.github.io
# The two main differences with a classic fsm are:
#   The composition of states and substates
#   The regions (sibling states that stay active at the same time)
#
# Your script can implement those abstract functions:
#  func _on_enter() -> void:
#  func _after_enter() -> void:
#  func _on_update(_delta) -> void:
#  func _after_update(_delta) -> void:
#  func _before_exit() -> void:
#  func _on_exit() -> void:
#  func _on_timeout(_name) -> void:
#
# Call a method to your State in the intended track of AnimationPlayer
# if you want to act (ie change State) after or during an animation
#
# In those scripts, you can call the public functions:
#  change_state("MyState")
#   "MyState" is the name of an existing Node State
#  is_active("MyState") -> bool
#   returns true if a state "MyState" is active in this xsm
#  play("Anim")
#   plays the animation "Anim" of the State's AnimationPlayer
#  stop()
#   stops the current animation
#  is_playing("Anim)
#   returns true if "Anim" is playing
#  add_timer("Name", time)
#   adds a timer named "Name" and returns this timer
#   when the time is out, the function _on_timeout(_name) is called
#  del_timer("Name")
#   deletes the timer "Name"
#  is_timer("Name")
#   returns true if there is a Timer "Name" running in this State
#  get_active_substate()
#   returns the active substate (all the children if has_regions)


signal state_entered(sender)
signal state_exited(sender)
signal state_updated(sender)
signal state_changed(sender)
signal disabled()
signal enabled()

export var disabled = false setget set_disabled
export var has_regions = false
#export var is_fallback = false
export(NodePath) var fsm_owner = null
export(NodePath) var animation_player = null

var active = false
var state_root = null
var target : Node = null
var anim_player : AnimationPlayer = null
var last_state : State = null
var done_for_this_frame = false
var state_in_update = false

#
# INIT
#
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if fsm_owner != null:
		target = get_node(fsm_owner)
	if animation_player != null:
		anim_player = get_node(animation_player)



func _get_configuration_warning() -> String:
	for c in get_children():
		if c.get_class() != "State":
			return "Error : this Node has a non State child (%s)" % c.get_name()
	return ""


func set_disabled(new_disabled) -> void:
	disabled = new_disabled
	if disabled:
		emit_signal("disabled")
	else:
		emit_signal("enabled")


#
# FUNCTIONS TO INHERIT
#
func _on_enter() -> void:
	pass


func _after_enter() -> void:
	pass


func _on_update(_delta) -> void:
	pass


func _after_update(_delta) -> void:
	pass


func _before_exit() -> void:
	pass


func _on_exit() -> void:
	pass


func _on_timeout(_name) -> void:
	pass


#
# FUNCTIONS TO CALL IN INHERITED STATES
#
func change_state(new_state) -> void:
	if not state_in_update:
		state_root.new_pending_state(new_state)

	if done_for_this_frame:
		return

	# if empty, go to itself
	if new_state == "":
		new_state = get_name()

	# finds the path to next state, return if null or active
	var new_state_node = find_state_node(new_state, null)
	if new_state_node == null:
		return
	if new_state != get_name() and new_state_node.active:
		return
	if new_state_node.disabled:
		return

	# compare the current path and the new one -> get the common_root
	var common_root = get_common_root(new_state_node)

	# exits all active children of the old branch,
	# from farthest to common_root (excluded)
	common_root.exit_children()
	# enters the nodes of the new branch from the parent to the next_state
	# enters the first leaf of each following branch
	common_root.enter_children(new_state_node.get_path())

	# sets this State as last_state for the new one
	new_state_node.last_state = self

	# set "done this frame" to avoid another round of state change in this branch
	common_root.reset_done_this_frame(true)

	# signal the change
	emit_signal("state_changed", self)
	state_root.emit_signal("substate_changed", self)
#	print("'%s' -> '%s'" % [get_name(), new_state])


# New function name
func goto_state(new_state) -> void:
	change_state(new_state)


func is_active(name) -> bool:
	var s = find_state_node(name, null)
	if s == null:
		return false
	return s.find_state_node(name, null).active


# returns the first active substate or all children if has_regions
func get_active_substate():
	if has_regions and active:
		return get_children()
	else:
		for c in get_children():
			if c.active:
				return c
	return null


func play(anim) -> void:
	if active and anim_player != null and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.stop()
			anim_player.play(anim)


func stop() -> void:
	if anim_player != null:
		anim_player.stop()


func is_playing(anim) -> bool:
	if anim_player != null:
		return anim_player.current_animation == anim
	else:
		return false


func add_timer(name, time) -> Timer:
	del_timer(name)
	var timer = Timer.new()
	add_child(timer)
	timer.set_name(name)
	timer.set_one_shot(true)
	timer.start(time)
	timer.connect("timeout",self,"_on_timer_timeout",[name])
	return timer


func del_timer(name) -> void:
	if has_node(name):
		get_node(name).stop()
		get_node(name).queue_free()
		get_node(name).set_name("to_delete")


func del_timers() -> void:
	for c in get_children():
		if c is Timer:
			c.stop()
			c.queue_free()
			c.set_name("to_delete")


func has_timer(name) -> bool:
	return has_node(name)

#
# PRIVATE FUNCTIONS
#
func init_children_states(root_state, first_branch) -> void:
	for c in get_children():
		if c.get_class() == "State":
			c.active = false
			c.state_root = root_state
			if c.target == null:
				c.target = root_state.target
			if c.anim_player == null:
				c.anim_player = root_state.anim_player
			if first_branch and ( has_regions or c == get_child(0) ):
				c.active = true
				c.last_state = root_state
				c.init_children_states(root_state, true)
			else:
				c.init_children_states(root_state, false)


func find_state_node(new_state, just_done) -> State:
	if get_name() == new_state:
		return self
	var found = null
	for c in get_children():
		if c.get_class() == "State" and c != just_done:
			found = c.find_state_node(new_state,self)
			if found != null:
				return found
	var parent = get_parent()
	if parent != null and parent.get_class() == "State" and parent != just_done:
		found = parent.find_state_node(new_state, self)
		if found != null:
			return found
	return found


func get_common_root(new_state) -> State:
	var new_path = new_state.get_path()
	# TODO should compare with the current ACTIVE path
	# Get the active path
	var result: State = new_state
	while not result.active and not result.is_root():
		result = result.get_parent()
	return result


func update(delta) -> void:
	if active:
		_on_update(delta)
		emit_signal("state_updated", self)
		state_root.emit_signal("substate_updated", self)


func update_active_states(delta) -> void:
	if disabled:
		return
	state_in_update = true
	update(delta)
	for c in get_children():
		if c.get_class() == "State" and c.active and !c.done_for_this_frame:
			c.update_active_states(delta)
	_after_update(delta)
	state_in_update = false


func exit() -> void:
	active = false
	del_timers()
	_on_exit()
	emit_signal("state_exited", self)
	state_root.emit_signal("substate_exited", self)


func exit_children() -> void:
	for c in get_children():
		if c.get_class() == "State" and c.active:
			c._before_exit()
			c.exit_children()
			c.exit()


func enter() -> void:
	active = true
	_on_enter()
	emit_signal("state_entered", self)
	state_root.emit_signal("substate_entered", self)


func enter_children(new_state_path) -> void:
	# if hasregions, enter all children and that's all
	# if newstate's path tall enough, enter child that fits newstate's current lvl
	# else newstate's path smaller than here, enter first child
	if has_regions:
		for c in get_children():
			c.enter()
			c.enter_children(new_state_path)
			c._after_enter()
		return

	var new_state_lvl = new_state_path.get_name_count()
	var current_lvl = get_path().get_name_count()
	if new_state_lvl > current_lvl:
		for c in get_children():
			var current_name = new_state_path.get_name(current_lvl)
			if c.get_class() == "State" and c.get_name() == current_name:
				c.enter()
				c.enter_children(new_state_path)
				c._after_enter()
	else:
		if get_child_count() > 0:
			var c = get_child(0)
			if get_child(0).get_class() == "State":
				c.enter()
				c.enter_children(new_state_path)
				c._after_enter()


func _on_timer_timeout(name) -> void:
	del_timer(name)
	_on_timeout(name)


func reset_done_this_frame(new_done) -> void:
	done_for_this_frame = new_done
	if not is_atomic():
		for c in get_children():
			if c.get_class() == "State":
				c.reset_done_this_frame(new_done)


func get_class() -> String:
	return "State"


func is_atomic() -> bool:
	return get_child_count() == 0


func is_root() -> bool:
	return false
