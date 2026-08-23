extends Node3D
class_name BaseLevel

func get_default_player_spawn() -> Vector2:
	var spawner := get_node_or_null("PlayerSpawner") as Node2D
	if spawner != null:
		return spawner.global_position
	return Vector2(10, 10)
