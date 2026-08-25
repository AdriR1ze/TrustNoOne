class_name PhotoThumbnail
extends PanelContainer
## Celda de thumbnail para la grilla del libro de fotos.
## Estilo polaroid: borde blanco grueso, sombra, nombre debajo.


## Emitida cuando el jugador hace click en el thumbnail.
signal thumbnail_clicked(photo_id: String)

var _photo_id: String = ""
var _texture_rect: TextureRect
var _name_label: Label
var _button_overlay: Button

## Colores
const COLOR_CARD_BG := Color(1.0, 1.0, 1.0)
const COLOR_CARD_BORDER := Color(0.82, 0.78, 0.72)
const COLOR_CARD_NAME := Color(0.35, 0.30, 0.25)
const COLOR_HOVER := Color(0.95, 0.92, 0.87)


func _ready() -> void:
	custom_minimum_size = Vector2(240, 210)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Estilo del panel (tarjeta blanca con sombra)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COLOR_CARD_BG
	card_style.border_color = COLOR_CARD_BORDER
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(3)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	card_style.shadow_size = 6
	card_style.shadow_offset = Vector2(2, 3)
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", card_style)

	# Layout vertical: imagen + nombre
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Imagen
	_texture_rect = TextureRect.new()
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texture_rect.custom_minimum_size = Vector2(0, 140)
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_texture_rect)

	# Nombre debajo de la foto
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", COLOR_CARD_NAME)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)

	# Botón invisible encima de todo para captar clicks
	_button_overlay = Button.new()
	_button_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button_overlay.flat = true
	_button_overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button_overlay.focus_mode = Control.FOCUS_ALL
	_button_overlay.pressed.connect(_on_pressed)
	add_child(_button_overlay)

	# Hover: cambiar color del panel
	_button_overlay.mouse_entered.connect(_on_hover_enter)
	_button_overlay.mouse_exited.connect(_on_hover_exit)


## Configura el thumbnail con los datos de una foto.
func setup(photo: PhotoData) -> void:
	_photo_id = photo.photo_id
	_texture_rect.texture = photo.texture
	_name_label.text = photo.display_name


func _on_pressed() -> void:
	thumbnail_clicked.emit(_photo_id)


func _on_hover_enter() -> void:
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = COLOR_HOVER
	hover_style.border_color = Color(0.55, 0.35, 0.20, 0.6)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(3)
	hover_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2(2, 4)
	hover_style.content_margin_left = 10
	hover_style.content_margin_right = 10
	hover_style.content_margin_top = 10
	hover_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", hover_style)


func _on_hover_exit() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_CARD_BG
	normal_style.border_color = COLOR_CARD_BORDER
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(2, 3)
	normal_style.content_margin_left = 10
	normal_style.content_margin_right = 10
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", normal_style)
