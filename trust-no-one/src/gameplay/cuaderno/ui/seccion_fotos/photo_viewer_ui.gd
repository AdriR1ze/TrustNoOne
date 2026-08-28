class_name PhotoViewerUI
extends Control
## Vista expandida de una foto individual.
## Permite ver la foto a tamaño grande y navegar entre fotos con flechas.
## Estilo de página de libro con fondo crema.

## Emitida cuando el jugador quiere volver a la grilla.
signal back_requested

## Índice de la foto actualmente mostrada.
var _current_index: int = -1

@onready var _photo_rect: TextureRect = %PhotoRect
@onready var _name_label: Label = %NameLabel
@onready var _info_label: Label = %InfoLabel
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton
@onready var _back_button: Button = %BackButton
@onready var _counter_label: Label = %CounterLabel

## Colores consistentes con el libro
const COLOR_PAGE := Color(0.96, 0.94, 0.90)
const COLOR_PAGE_BORDER := Color(0.78, 0.74, 0.68)
const COLOR_COVER := Color(0.12, 0.10, 0.08, 0.95)
const COLOR_TITLE := Color(0.25, 0.20, 0.15)
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)


func _ready() -> void:
	visible = false
	_back_button.pressed.connect(_on_back_pressed)
	_prev_button.pressed.connect(func(): _navigate(-1))
	_next_button.pressed.connect(func(): _navigate(1))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_navigate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_navigate(1)
		get_viewport().set_input_as_handled()


## Abre el visor mostrando la foto en el índice dado.
func open(photo_index: int) -> void:
	_current_index = photo_index
	_update_display()
	visible = true


## Cierra el visor.
func close() -> void:
	visible = false
	_current_index = -1


func _navigate(direction: int) -> void:
	var total := PhotoStorage.get_photo_count()
	if total == 0:
		return

	_current_index = wrapi(_current_index + direction, 0, total)
	_update_display()


func _update_display() -> void:
	var photo := PhotoStorage.get_photo_at_index(_current_index)
	if photo == null:
		close()
		return

	_photo_rect.texture = photo.texture
	_name_label.text = photo.display_name
	_counter_label.text = "%d / %d" % [_current_index + 1, PhotoStorage.get_photo_count()]

	# Info de captura
	var time_str := ""
	if photo.capture_time.has("hour"):
		time_str = "%02d:%02d" % [photo.capture_time.get("hour", 0), photo.capture_time.get("minute", 0)]
	var pos := photo.capture_position
	_info_label.text = "Posición: (%.0f, %.0f, %.0f)" % [pos.x, pos.y, pos.z]
	if time_str != "":
		_info_label.text += "    ·    %s" % time_str

	# Actualizar estado de botones
	var total := PhotoStorage.get_photo_count()
	_prev_button.disabled = total <= 1
	_next_button.disabled = total <= 1


func _on_back_pressed() -> void:
	close()
	back_requested.emit()
