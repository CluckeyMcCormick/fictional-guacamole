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


signal state_entered(sender)
signal state_exited(sender)
signal state_updated(sender)
signal state_changed(sender)

export var active = false
export var has_regions = false
export var is_fallback = false
export(NodePath) var fsm_owner = null
export(NodePath) var animation_player = null

var target : Node = null
var anim_player : AnimationPlayer = null
var last_state : State = null
var fallback : State = null
var done_for_this_frame = false


#
# INIT
#
func _ready() -> void:
    if Engine.is_editor_hint():
        return
    if is_root() and active:
        if fsm_owner != null:
            target = get_node(fsm_owner)
        elif get_parent() != null:
            target = get_parent()

        if animation_player != null:
            anim_player = get_node(animation_player)
        elif get_parent() != null:
            for sibling in get_parent().get_children():
                if sibling is AnimationPlayer:
                    anim_player = sibling
                    break

        is_fallback = true
        last_state = self
        init_children_states(self, true)
        change_state("") # TODO remove


func _get_configuration_warning() -> String:
    for c in get_children():
        if c.get_class() != "State":
            return "Error : this Node has a non State child (%s)" % c.get_name()
    if is_root() and !active:
        return "Warning : Your root State is not active. It will not work"
    if is_root() and fsm_owner == null:
        return "Warning : Your root State has no target"
    if is_root() and animation_player == null:
        return "Warning : Your root State has no AnimationPlayer registered"
    return ""


func _physics_process(delta) -> void:
    if Engine.is_editor_hint():
        return
    if is_root() and active:
        reset_done_this_frame(false)
        update_active_states(delta)


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
    if done_for_this_frame:
        return

    # if empty, go to fallback or itself
    if new_state == "":
        if fallback != null:
            new_state = fallback.get_name()
        else:
            new_state = get_name()

    # finds the path to next state, return if null or active
    var new_state_node = find_state_node(new_state, null)
    if new_state_node == null:
        return
    if new_state != get_name() and new_state_node.active:
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
    if is_fallback:
        new_state_node.fallback = self
    else:
        new_state_node.fallback = fallback
    new_state_node.last_state = self

    # set "done this frame" to avoid another round of state change in this branch
    common_root.reset_done_this_frame(true)

    # signal the change
    emit_signal("state_changed", self)
#	print("'%s' -> '%s'" % [get_name(), new_state])


func is_active(name) -> bool:
    var s = find_state_node(name, null)
    if s == null:
        return false
    return s.find_state_node(name, null).active


func play(anim) -> void:
    if anim_player != null and anim_player.has_animation(anim):
        if anim_player.current_animation != anim:
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
        get_node(name).queue_free()
        get_node(name).set_name("to_delete")


func is_timer(name) -> bool:
    return has_node(name)

#
# PRIVATE FUNCTIONS
#
func init_children_states(root_state, first_branch) -> void:
    for c in get_children():
        if c.get_class() == "State":
            c.active = false
            if c.fsm_owner != null:
                c.target = c.get_node(c.fsm_owner)
            else:
                c.target = root_state.target
            if c.animation_player != null:
                c.anim_player = c.get_node(c.animation_player)
            else:
                c.anim_player = root_state.anim_player
            c.fallback = root_state
            if first_branch and ( has_regions or c == get_child(0)):
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
    var curr_path = get_path()
    var common_root_path = ""
    var i = 0
    while i < new_path.get_name_count() and i < curr_path.get_name_count():
        if new_path.get_name(i) != curr_path.get_name(i):
            break
        common_root_path = str(common_root_path, "/", new_path.get_name(i))
        i += 1
    var result: State = get_node(common_root_path)
    return result


func update(delta) -> void:
    if active:
        _on_update(delta)
        emit_signal("state_updated", self)


func update_active_states(delta) -> void:
    update(delta)
    for c in get_children():
        if c.get_class() == "State" and c.active and !c.done_for_this_frame:
            c.update_active_states(delta)
    _after_update(delta)


func exit() -> void:
    active = false
    _on_exit()
    emit_signal("state_exited", self)


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
    return get_parent().get_class() != "State"
