## StateMachine – lightweight state machine used by scene scripts.
## States are Nodes added as children. Call transition() to change state.
class_name StateMachine
extends Node

var current_state: Node = null

signal state_changed(old_state: Node, new_state: Node)

func _ready() -> void:
	# Deactivate all child states; the owner must call start().
	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED

func start(state_name: String) -> void:
	var target := find_child(state_name, false, false)
	if target == null:
		push_error("[StateMachine] State not found: " + state_name)
		return
	_enter(target)

func transition(state_name: String) -> void:
	var target := find_child(state_name, false, false)
	if target == null:
		push_error("[StateMachine] State not found: " + state_name)
		return
	var old := current_state
	if old != null:
		if old.has_method("on_exit"):
			old.on_exit()
		old.process_mode = Node.PROCESS_MODE_DISABLED
	_enter(target)
	state_changed.emit(old, target)

func _enter(state: Node) -> void:
	current_state = state
	state.process_mode = Node.PROCESS_MODE_INHERIT
	if state.has_method("on_enter"):
		state.on_enter()
	print("[StateMachine] → ", state.name)
