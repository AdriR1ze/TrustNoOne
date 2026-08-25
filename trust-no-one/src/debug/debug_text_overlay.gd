extends Control

@onready var fps_label: Label = %FpsLabel
@onready var level_label: Label = %LevelLabel

func _process(_delta: float) -> void:
	fps_label.text = "FPS " + str(Engine.get_frames_per_second())
	var main_game := get_tree().get_first_node_in_group("main_game")
	var level_name = main_game.current_level_name if main_game != null else "?"
	level_label.text = "LEVEL " + level_name
