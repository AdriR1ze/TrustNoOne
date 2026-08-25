extends CharacterBody3D
class_name Player

enum PlayerState {
	ZOOMING
}

@export var normal_fov := 75.0
@export var zoom_fov := 30.0
@export var zoom_duration := 0.25

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	add_to_group("player")
