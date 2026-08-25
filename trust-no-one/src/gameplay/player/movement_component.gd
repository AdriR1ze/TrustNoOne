class_name MovementComponent
extends Node


@export var move_speed := 5.0
@export var gravity := 9.8

var player: Player


func _ready() -> void:
	player = get_parent() as Player


func _physics_process(delta: float) -> void:
	var move_axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_apply_movement(move_axis)
	_apply_gravity(delta)
	player.move_and_slide()


func _apply_movement(move_axis: Vector2) -> void:
	if move_axis == Vector2.ZERO:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		return

	var forward := -player.camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := player.camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var direction := forward * -move_axis.y + right * move_axis.x
	direction = direction.normalized()

	player.velocity.x = direction.x * move_speed
	player.velocity.z = direction.z * move_speed


func _apply_gravity(delta: float) -> void:
	if player.is_on_floor():
		if player.velocity.y < 0.0:
			player.velocity.y = 0.0
	else:
		player.velocity.y -= gravity * delta
