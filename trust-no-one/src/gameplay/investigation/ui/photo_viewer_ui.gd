class_name PhotoViewerUI
extends Control
## Vista expandida de una foto individual.
## Permite ver la foto a tamaño grande y navegar entre fotos con flechas.
## Estilo de página de libro con fondo crema.


## Emitida cuando el jugador quiere volver a la grilla.
signal back_requested

## Índice de la foto actualmente mostrada.
var _current_index: int = -1

var _photo_rect: TextureRect
var _photo_frame: PanelContainer
var _name_label: Label
var _info_label: Label
var _prev_button: Button
var _next_button: Button
var _back_button: Button
var _counter_label: Label
var _background: ColorRect

## Colores consistentes con el libro
const COLOR_PAGE := Color(0.96, 0.94, 0.90)
const COLOR_PAGE_BORDER := Color(0.78, 0.74, 0.68)
const COLOR_COVER := Color(0.12, 0.10, 0.08, 0.95)
const COLOR_TITLE := Color(0.25, 0.20, 0.15)
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	# Fondo oscuro
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = COLOR_COVER
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Panel página centrado
	var page := PanelContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	page.offset_left = 100
	page.offset_right = -100
	page.offset_top = 40
	page.offset_bottom = -40

	var page_style := StyleBoxFlat.new()
	page_style.bg_color = COLOR_PAGE
	page_style.border_color = COLOR_PAGE_BORDER
	page_style.set_border_width_all(2)
	page_style.set_corner_radius_all(4)
	page_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	page_style.shadow_size = 16
	page_style.shadow_offset = Vector2(4, 6)
	page_style.set_content_margin_all(32)
	page.add_theme_stylebox_override("panel", page_style)
	add_child(page)

	# Layout vertical
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	page.add_child(vbox)

	# === Barra superior ===
	var top_bar := HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_bar)

	_back_button = Button.new()
	_back_button.text = "← Volver al álbum"
	_back_button.add_theme_font_size_override("font_size", 14)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	back_style.set_content_margin_all(6)
	_back_button.add_theme_stylebox_override("normal", back_style)
	var back_hover := StyleBoxFlat.new()
	back_hover.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	back_hover.set_corner_radius_all(4)
	back_hover.set_content_margin_all(6)
	_back_button.add_theme_stylebox_override("hover", back_hover)
	_back_button.add_theme_color_override("font_color", COLOR_ACCENT)
	_back_button.add_theme_color_override("font_hover_color", COLOR_TITLE)
	_back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(_back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_counter_label = Label.new()
	_counter_label.add_theme_font_size_override("font_size", 15)
	_counter_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(_counter_label)

	# Línea
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = COLOR_PAGE_BORDER
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line)

	# === Zona de la imagen con navegación ===
	var image_row := HBoxContainer.new()
	image_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_row.alignment = BoxContainer.ALIGNMENT_CENTER
	image_row.add_theme_constant_override("separation", 16)
	vbox.add_child(image_row)

	# Botón anterior
	_prev_button = _create_nav_button("◀")
	_prev_button.pressed.connect(func(): _navigate(-1))
	image_row.add_child(_prev_button)

	# Marco de la foto (panel blanco con borde)
	_photo_frame = PanelContainer.new()
	_photo_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_photo_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color.WHITE
	frame_style.border_color = COLOR_PAGE_BORDER
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(2)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.1)
	frame_style.shadow_size = 4
	frame_style.shadow_offset = Vector2(1, 2)
	frame_style.set_content_margin_all(6)
	_photo_frame.add_theme_stylebox_override("panel", frame_style)
	image_row.add_child(_photo_frame)

	# Imagen principal
	_photo_rect = TextureRect.new()
	_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_photo_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_photo_frame.add_child(_photo_rect)

	# Botón siguiente
	_next_button = _create_nav_button("▶")
	_next_button.pressed.connect(func(): _navigate(1))
	image_row.add_child(_next_button)

	# Línea inferior
	var line2 := ColorRect.new()
	line2.custom_minimum_size = Vector2(0, 1)
	line2.color = COLOR_PAGE_BORDER
	line2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line2)

	# === Info de la foto ===
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", COLOR_TITLE)
	vbox.add_child(_name_label)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	vbox.add_child(_info_label)


func _create_nav_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(48, 48)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	btn_style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	btn_hover.set_corner_radius_all(24)
	btn_hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.add_theme_color_override("font_color", COLOR_SUBTITLE)
	btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
	return btn


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
