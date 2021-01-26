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


signal some_state_changed(sender, new_state_node)
signal pending_state_changed(added_state_node)
signal pending_state_added(new_state_name)
signal active_state_list_changed(active_states_list)

var pending_states := []
var state_map := {}
var duplicate_names := {} # Stores number of times a state_name is duplicated
var active_states := {}


#
# INIT
#
func _ready():
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
func _physics_process(delta) -> void:
	if Engine.is_editor_hint():
		return
	if not disabled:
		reset_done_this_frame(false)
		while pending_states.size() > 0:
			state_in_update = true
			var new_state = pending_states.pop_front()
			var new_state_node = change_state(new_state)
			emit_signal("pending_state_changed", new_state_node)
			state_in_update = false
		update_active_states(delta)


#
# FUNCTIONS TO CALL IN INHERITED STATES
#
func new_pending_state(new_state_name) -> void:
	pending_states.append(new_state_name)
	emit_signal("pending_state_added", new_state_name)


#
# PRIVATE FUNCTIONS
#
func is_root() -> bool:
	return true


func remove_active_state(state_to_erase) -> void:
	active_states.erase(state_to_erase)
	emit_signal("active_state_list_changed", active_states)


func add_active_state(state_to_add) -> void:
	var state_name = state_to_add.name
	var name_in_state_map = state_name
	if not state_map.has(state_name):
		var parent_name = state_to_add.get_parent().name
		name_in_state_map = str("%s/%s" % [parent_name, state_name])
	active_states[state_to_add] = name_in_state_map
	emit_signal("active_state_list_changed", active_states)
