extends Control
## Vista expandida de una foto individual.
## Permite ver la foto a tamaño grande y navegar entre fotos con flechas.


## Emitida cuando el jugador quiere volver a la grilla.
signal back_requested

## Índice de la foto actualmente mostrada.
var _current_index: int = -1

var _photo_rect: TextureRect
var _name_label: Label
var _info_label: Label
var _prev_button: Button
var _next_button: Button
var _back_button: Button
var _counter_label: Label
var _background: ColorRect


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()


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


func _build_ui() -> void:
	# Fondo oscuro semitransparente
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = Color(0.05, 0.05, 0.08, 0.95)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Contenedor principal vertical
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Barra superior con botón volver y contador
	var top_bar := HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_bar)

	_back_button = Button.new()
	_back_button.text = "← Volver"
	_back_button.add_theme_font_size_override("font_size", 16)
	_back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(_back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_counter_label = Label.new()
	_counter_label.add_theme_font_size_override("font_size", 16)
	_counter_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	top_bar.add_child(_counter_label)

	# Separador
	vbox.add_child(_create_spacer(10))

	# Contenedor de la imagen con navegación
	var image_row := HBoxContainer.new()
	image_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(image_row)

	# Botón anterior
	_prev_button = Button.new()
	_prev_button.text = "◀"
	_prev_button.add_theme_font_size_override("font_size", 24)
	_prev_button.custom_minimum_size = Vector2(50, 50)
	_prev_button.pressed.connect(func(): _navigate(-1))
	image_row.add_child(_prev_button)

	# Imagen principal
	_photo_rect = TextureRect.new()
	_photo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_photo_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_row.add_child(_photo_rect)

	# Botón siguiente
	_next_button = Button.new()
	_next_button.text = "▶"
	_next_button.add_theme_font_size_override("font_size", 24)
	_next_button.custom_minimum_size = Vector2(50, 50)
	_next_button.pressed.connect(func(): _navigate(1))
	image_row.add_child(_next_button)

	# Separador
	vbox.add_child(_create_spacer(10))

	# Nombre de la foto
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_name_label)

	# Info adicional (posición, hora)
	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(_info_label)

	vbox.add_child(_create_spacer(20))


func _create_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer


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
	_info_label.text = "Pos: (%.0f, %.0f, %.0f)" % [pos.x, pos.y, pos.z]
	if time_str != "":
		_info_label.text += "  |  %s" % time_str

	# Actualizar estado de botones
	var total := PhotoStorage.get_photo_count()
	_prev_button.disabled = total <= 1
	_next_button.disabled = total <= 1


func _on_back_pressed() -> void:
	close()
	back_requested.emit()
