# MIT LICENSE Copyright 2020-2021 Etienne Blanc - ATN
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
class_name StateRoot
extends State

# This is the necessary manager node for any XSM. This is a special State that
# can handle change requests outside of XSM's logic. See the example to get it!
# This node will probably expand a bit in the next versions of XSM


signal some_state_changed(sender_node, new_state_node)
signal pending_state_changed(added_state_node)
signal pending_state_added(new_state_name)
signal active_state_list_changed(active_states_list)


export(int, 0, 1024) var history_size := 12

var state_map := {}
var duplicate_names := {} # Stores number of times a state_name is duplicated
var pending_states := []

var active_states := {}
var active_states_history := []


#
# INIT
#
func _ready() -> void:
	state_root = self
	if fsm_owner == null and get_parent() != null:
		target = get_parent()
	init_state_map()
	init_children_states(self, true)
	set_active(true)


func _get_configuration_warning() -> String:
	if disabled:
		return "Warning : Your root State is disabled. It will not work"
	if fsm_owner == null:
		return "Warning : Your root State has no target"
	if animation_player == null:
		return "Warning : Your root State has no AnimationPlayer registered"
	return ._get_configuration_warning()


# Careful, if your substates have the same name,
# their parents'names must be different
func init_state_map() -> void:
	state_map[name] = self
	init_children_state_map(state_map, self)


#
# PROCESS
#
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not disabled:
		reset_done_this_frame(false)
		add_to_active_states_history(active_states.duplicate())
		while pending_states.size() > 0:
			state_in_update = true
			var new_state_with_args = pending_states.pop_front()
			var new_state: String = new_state_with_args[0]
			var arg1 = new_state_with_args[1]
			var arg2 = new_state_with_args[2]
			var arg3 = new_state_with_args[3]
			var arg4 = new_state_with_args[4]
			var new_state_node: State = change_state(new_state,
					arg1, arg2, arg3, arg4)
			emit_signal("pending_state_changed", new_state_node)
			state_in_update = false
#			pending_states.clear()
		update_active_states(delta)


#
# FUNCTIONS TO CALL IN INHERITED STATES
#
# Careful, only the last one added in this frame will be change in xsm
func new_pending_state(new_state_name: String, args_on_enter = null,
		args_after_enter = null, args_before_exit = null,
		args_on_exit = null) -> void:
	var new_state_array := []
	new_state_array.append(new_state_name)
	new_state_array.append(args_on_enter)
	new_state_array.append(args_after_enter)
	new_state_array.append(args_before_exit)
	new_state_array.append(args_on_exit)
	pending_states.append(new_state_array)
	emit_signal("pending_state_added", new_state_name)


#
# PUBLIC FUNCTIONS
#
func in_active_states(state_name: String) -> bool:
	return active_states.has(state_name)


func get_previous_active_states(history_id: int = 0) -> Dictionary:
	if active_states_history.size() <= history_id:
		return Dictionary()
	return active_states_history[history_id]


# CAREFUL IF YOU HAVE TWO STATES WITH THE SAME NAME, THE "state_name"
# SHOULD BE OF THE FORM "ParentName/ChildName"
func was_state_active(state_name: String, history_id: int = 0) -> bool:
	return get_previous_active_states(history_id).has(state_name)


func is_root() -> bool:
	return true


#
# PRIVATE FUNCTIONS
#
func add_to_active_states_history(new_active_states: Dictionary) -> void:
	active_states_history.push_front(new_active_states)
	while active_states_history.size() > history_size:
		var _last: Dictionary = active_states_history.pop_back()


func remove_active_state(state_to_erase: State) -> void:
	var state_name: String = state_to_erase.name
	var name_in_state_map: String = state_name
	if not state_map.has(state_name):
		var parent_name: String = state_to_erase.get_parent().name
		name_in_state_map = str("%s/%s" % [parent_name, state_name])
	active_states.erase(name_in_state_map)
	emit_signal("active_state_list_changed", active_states)


func add_active_state(state_to_add: State) -> void:
	var state_name: String = state_to_add.name
	var name_in_state_map: String = state_name
	if not state_map.has(state_name):
		var parent_name: String = state_to_add.get_parent().name
		name_in_state_map = str("%s/%s" % [parent_name, state_name])
	active_states[name_in_state_map] = state_to_add
	emit_signal("active_state_list_changed", active_states)
