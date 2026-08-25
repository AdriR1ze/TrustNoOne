extends Node3D
class_name BaseLevel
@export var posicion : Vector3
func get_default_player_spawn() -> Vector3:
	var spawner := get_node_or_null("PlayerSpawner") as Node3D
	if spawner != null:
		return spawner.global_position
	return posicion
