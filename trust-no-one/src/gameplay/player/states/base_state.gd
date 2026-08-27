class_name BaseState
extends Node


var player: Player
var state_machine: StateMachine


func _ready() -> void:
	state_machine = get_parent() as StateMachine
	player = state_machine.get_parent() as Player


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
