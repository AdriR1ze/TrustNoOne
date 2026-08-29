class_name PhotoThumbnail
extends PanelContainer
## Celda de thumbnail para la grilla del libro de fotos.
## Estilo polaroid: borde blanco grueso, sombra, nombre debajo.

## Emitida cuando el jugador hace click en el thumbnail.
signal thumbnail_clicked(photo_id: String)

@export var normal_style: StyleBox
@export var hover_style: StyleBox

var _photo_id: String = ""

@onready var _texture_rect: TextureRect = %TextureRect
@onready var _name_label: Label = %NameLabel
@onready var _button_overlay: Button = %ButtonOverlay


func _ready() -> void:
	_button_overlay.pressed.connect(_on_pressed)
	_button_overlay.mouse_entered.connect(_on_hover_enter)
	_button_overlay.mouse_exited.connect(_on_hover_exit)


## Configura el thumbnail con los datos de una foto.
func setup(photo: PhotoData) -> void:
	_photo_id = photo.photo_id
	if _texture_rect:
		_texture_rect.texture = photo.texture
	if _name_label:
		_name_label.text = photo.display_name


func _on_pressed() -> void:
	thumbnail_clicked.emit(_photo_id)


func _on_hover_enter() -> void:
	if hover_style:
		add_theme_stylebox_override("panel", hover_style)


func _on_hover_exit() -> void:
	if normal_style:
		add_theme_stylebox_override("panel", normal_style)
