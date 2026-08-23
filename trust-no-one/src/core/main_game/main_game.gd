extends Node


var _current_level : BaseLevel
var _is_respawning := false


const LEVELS: Array[String] = []

var _current_level_index := 0


@onready var entity_root: Node3D = %EntityRoot
@onready var effects_root: Node3D = %EffectsRoot
@onready var level_root: Node3D = %LevelRoot


@onready var hud_layer: CanvasLayer = $HudLayer
@onready var hud_root: Control = $HudLayer/HudRoot
@onready var pause_root: Control = %PauseRoot
@onready var transition_root: Control = %TransitionRoot

var player: Player = null

func _ready() -> void:
	_init_player()


func _init_player() -> void:

	var player_scene: PackedScene = ResourceLoader.load("res://src/gameplay/player/player.tscn"	)

	if player_scene == null:
		push_error("Error opening the Player Scene")
		return

	player = player_scene.instantiate() as Player

	if player == null:
		push_error("Loaded player doesn't work")
		return

	player.died.connect(_on_player_died)

	entity_root.add_child(player)


func load_level(level_scene: String) -> void:
	print(level_scene)
	_current_level_index = LEVELS.find(level_scene)
	_deferred_load_level.call_deferred(
		level_scene
	)






func _deferred_load_level(level_scene: String) -> void:
	if _current_level != null:
		_stop_current_level()
		_current_level.queue_free()
		_current_level = null

	await get_tree().process_frame

	var new_level: PackedScene = ResourceLoader.load(
		level_scene,
		"PackedScene"
	) as PackedScene

	if new_level == null:
		push_error("Couldn't load new level")
		return

	_current_level = new_level.instantiate() as BaseLevel

	if _current_level == null:
		push_error("Couldn't instantiate the current level")
		return

	_current_level.level_completed.connect(_on_level_completed)

	level_root.add_child(_current_level)

	if _build_hud != null:
		_build_hud.visible = not _is_tutorial_level(level_scene)

	await get_tree().process_frame

	if player != null:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.is_building = false

	_place_player_at_level_spawn()


func _place_player_at_level_spawn() -> void:

	if player == null:
		push_error("Cannot place player in level because player is null")
		return

	if _current_level == null:
		push_error("Cannot place player in level because level is null")
		return

	player.global_position = (_current_level.get_default_player_spawn())
