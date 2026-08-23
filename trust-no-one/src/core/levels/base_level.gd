extends Node3D
class_name BaseLevel

func get_default_player_spawn() -> Vector3:
	var spawner := get_node_or_null("PlayerSpawner") as Node3D
	if spawner != null:
		return spawner.global_position
	return Vector3(10, 10, 10)
