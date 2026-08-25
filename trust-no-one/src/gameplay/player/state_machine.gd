class_name StateMachine
extends Node


@onready var zoom_state: BaseState = $ZoomState

var current_state: BaseState


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("zoom"):
		change_state(zoom_state)
	else:
		change_state(null)

	if current_state != null:
		current_state.physics_update(delta)


func change_state(new_state: BaseState) -> void:
	if current_state == new_state:
		return

	if current_state != null:
		current_state.exit()

	current_state = new_state

	if current_state != null:
		current_state.enter()
