class_name PhotoThumbnail
extends TextureButton
## Celda de thumbnail para la grilla del libro de fotos.
## Muestra un preview de la foto y su nombre.


## Emitida cuando el jugador hace click en el thumbnail.
signal thumbnail_clicked(photo_id: String)

var _photo_id: String = ""
var _name_label: Label


func _ready() -> void:
	# Configurar el botón
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	custom_minimum_size = Vector2(200, 150)

	# Configurar focus visual
	focus_mode = Control.FOCUS_ALL

	# Crear label para el nombre
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	pressed.connect(_on_pressed)


## Configura el thumbnail con los datos de una foto.
func setup(photo: PhotoData) -> void:
	_photo_id = photo.photo_id
	texture_normal = photo.texture
	_name_label.text = photo.display_name


func _on_pressed() -> void:
	thumbnail_clicked.emit(_photo_id)
