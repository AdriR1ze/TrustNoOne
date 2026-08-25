extends Node


var _current_level: BaseLevel
var _is_respawning := false

const LEVEL_1 := "res://src/core/levels/level_1.tscn"

const LEVELS: Array[String] = [
	LEVEL_1,
]

var _current_level_index := 0


@onready var entity_root: Node3D = %EntityRoot
@onready var effects_root: Node3D = %EffectsRoot
@onready var level_root: Node3D = %LevelRoot


@onready var hud_layer: CanvasLayer = $HudLayer
@onready var hud_root: Control = $HudLayer/HudRoot
@onready var pause_root: Control = %PauseRoot
@onready var transition_root: Control = %TransitionRoot
@onready var libro: Libro = $System/Libro
@onready var libro_ui: LibroUi = $HudLayer/LibroUi
@onready var abrir_libro_button: Button = $HudLayer/HudRoot/AbrirLibroButton

var player: Player = null
var current_level_name := ""

func _ready() -> void:
	add_to_group("main_game")
	abrir_libro_button.pressed.connect(_abrir_pagina_tres)
	_init_player()
	load_level(LEVEL_1)


func _abrir_pagina_tres() -> void:
	libro.current_page = libro.pagina_3
	libro_ui.mostrar_pagina(libro.pagina_3)


func _init_player() -> void:
	var player_scene: PackedScene = ResourceLoader.load("res://src/gameplay/player/player.tscn")

	if player_scene == null:
		push_error("Error opening the Player Scene")
		return

	player = player_scene.instantiate() as Player

	if player == null:
		push_error("Loaded player doesn't work")
		return

	entity_root.add_child(player)


func load_level(level_scene: String) -> void:
	print("Loading level: ", level_scene)
	_current_level_index = LEVELS.find(level_scene)
	_deferred_load_level.call_deferred(level_scene)


func _deferred_load_level(level_scene: String) -> void:
	if _current_level != null:
		_current_level.queue_free()
		_current_level = null

	await get_tree().process_frame

	var new_level: PackedScene = ResourceLoader.load(level_scene, "PackedScene") as PackedScene

	if new_level == null:
		push_error("Couldn't load new level: " + level_scene)
		return

	_current_level = new_level.instantiate() as BaseLevel

	if _current_level == null:
		push_error("Couldn't instantiate the current level")
		return

	current_level_name = _current_level.name

	level_root.add_child(_current_level)

	await get_tree().process_frame

	_place_player_at_level_spawn()


func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level because player is null")
		return

	if _current_level == null:
		push_error("Cannot place player in level because level is null")
		return

	player.global_position = _current_level.get_default_player_spawn()
