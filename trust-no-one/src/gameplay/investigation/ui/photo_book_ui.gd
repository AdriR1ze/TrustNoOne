extends Control
## UI principal del libro de investigación.
## Contiene 3 secciones organizadas por pestañas:
## 1. Fotografías — Grilla de fotos capturadas
## 2. Objetos — Lista de objetos anotados
## 3. Notas — Notas del jugador
## Se abre/cierra con la acción toggle_photo_book (tecla B).

const PHOTO_THUMBNAIL_SCENE = preload("res://src/gameplay/investigation/ui/photo_thumbnail.tscn")

@export var tab_active_style: StyleBox
@export var tab_inactive_style: StyleBox

## Pestañas
enum Section { PHOTOS, ANNOTATIONS, NOTES }
var _current_section: Section = Section.PHOTOS
var _is_open: bool = false

## Referencias a nodos de la escena
@onready var _viewer: PhotoViewerUI = %PhotoViewer
@onready var _photos_container: Control = %PhotosContainer
@onready var _annotations_ui: AnnotationListUI = %AnnotationsList
@onready var _notes_ui: PlayerNotesUI = %PlayerNotes
@onready var _grid: GridContainer = %GridContainer
@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _title_label: Label = %TitleLabel
@onready var _empty_label: Label = %EmptyLabel
@onready var _count_label: Label = %CountLabel
@onready var _hint_label: Label = %HintLabel
@onready var _close_button: Button = %CloseButton
@onready var _photos_tab_btn: Button = %PhotosTabButton
@onready var _annot_tab_btn: Button = %AnnotationsTabButton
@onready var _notes_tab_btn: Button = %NotesTabButton

var _tab_buttons: Array[Button] = []

## Colores del libro
const COLOR_TITLE := Color(0.25, 0.20, 0.15)          # Título marrón oscuro
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)       # Subtextos
const COLOR_TAB_INACTIVE := Color(0.60, 0.55, 0.48)   # Texto pestaña inactiva


func _ready() -> void:
	visible = false
	_tab_buttons = [_photos_tab_btn, _annot_tab_btn, _notes_tab_btn]

	_photos_tab_btn.pressed.connect(func(): _switch_to_section(Section.PHOTOS))
	_annot_tab_btn.pressed.connect(func(): _switch_to_section(Section.ANNOTATIONS))
	_notes_tab_btn.pressed.connect(func(): _switch_to_section(Section.NOTES))

	_close_button.pressed.connect(close_book)
	_viewer.back_requested.connect(_on_viewer_back)
	_annotations_ui.connection_state_changed.connect(_on_annotation_connection_state_changed)

	# Conectar señales del storage
	PhotoStorage.photo_added.connect(_on_photo_added)
	PhotoStorage.photo_removed.connect(_on_photo_removed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_photo_book"):
		if _is_open:
			close_book()
		else:
			open_book()
		get_viewport().set_input_as_handled()

	# Si el libro está abierto, ESC lo cierra
	if _is_open and event.is_action_pressed("ui_cancel"):
		if _viewer.visible:
			return  # El viewer maneja su propio ESC
		close_book()
		get_viewport().set_input_as_handled()


## Abre el libro de investigación.
func open_book() -> void:
	if _is_open:
		return

	_is_open = true
	visible = true
	_switch_to_section(_current_section)

	# Mostrar cursor y pausar movimiento
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


## Cierra el libro de investigación.
func close_book() -> void:
	if not _is_open:
		return

	_viewer.close()
	_is_open = false
	visible = false

	# Recapturar mouse y reanudar
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _apply_tab_style_active(btn: Button) -> void:
	if tab_active_style:
		btn.add_theme_stylebox_override("normal", tab_active_style)
		btn.add_theme_stylebox_override("hover", tab_active_style)
		btn.add_theme_stylebox_override("pressed", tab_active_style)
	btn.add_theme_color_override("font_color", COLOR_TITLE)
	btn.add_theme_color_override("font_hover_color", COLOR_TITLE)
	btn.add_theme_color_override("font_pressed_color", COLOR_TITLE)


func _apply_tab_style_inactive(btn: Button) -> void:
	if tab_inactive_style:
		btn.add_theme_stylebox_override("normal", tab_inactive_style)
		btn.add_theme_stylebox_override("hover", tab_inactive_style)
		btn.add_theme_stylebox_override("pressed", tab_inactive_style)
	btn.add_theme_color_override("font_color", COLOR_TAB_INACTIVE)
	btn.add_theme_color_override("font_hover_color", COLOR_SUBTITLE)
	btn.add_theme_color_override("font_pressed_color", COLOR_SUBTITLE)


## Cambia la sección activa del libro.
func _switch_to_section(section: Section) -> void:
	_current_section = section

	# Actualizar visibilidad
	_photos_container.visible = section == Section.PHOTOS
	_annotations_ui.visible = section == Section.ANNOTATIONS
	_notes_ui.visible = section == Section.NOTES

	# Actualizar estilos de pestañas
	for i in range(_tab_buttons.size()):
		if i == int(section):
			_apply_tab_style_active(_tab_buttons[i])
		else:
			_apply_tab_style_inactive(_tab_buttons[i])

	# Actualizar contenido según sección
	match section:
		Section.PHOTOS:
			_refresh_grid()
			_hint_label.text = "[B] Cerrar    ·    Click en foto para ampliar    ·    ← → Navegar"
		Section.ANNOTATIONS:
			_annotations_ui.refresh()
			_count_label.text = "%d objetos anotados" % AnotacionesDb.cantidad()
			_hint_label.text = "[B] Cerrar    ·    Click derecho para conectar    ·    Arrastrar para mover"
		Section.NOTES:
			_notes_ui.refresh()
			_count_label.text = ""
			_hint_label.text = "[B] Cerrar"


func _on_annotation_connection_state_changed(is_connecting: bool) -> void:
	if _current_section == Section.ANNOTATIONS:
		if is_connecting:
			_hint_label.text = "Click izquierdo en otro objeto para trazar la flecha    ·    Click derecho para cancelar"
		else:
			_hint_label.text = "[B] Cerrar    ·    Click derecho para conectar    ·    Arrastrar para mover"


func _refresh_grid() -> void:
	# Limpiar grilla
	for child in _grid.get_children():
		child.queue_free()

	var photos := PhotoStorage.get_all_photos()
	_empty_label.visible = photos.is_empty()
	_scroll.visible = not photos.is_empty()
	_count_label.text = "%d / %d fotos" % [photos.size(), PhotoStorage.MAX_PHOTOS]

	for i in range(photos.size()):
		var photo := photos[i]
		var thumbnail: PhotoThumbnail = PHOTO_THUMBNAIL_SCENE.instantiate()
		thumbnail.name = "Thumb_%s" % photo.photo_id.left(8)
		_grid.add_child(thumbnail)
		thumbnail.setup.call_deferred(photo)
		var idx := i
		thumbnail.thumbnail_clicked.connect(func(_id: String): _open_viewer(idx))


func _open_viewer(photo_index: int) -> void:
	_viewer.open(photo_index)


func _on_viewer_back() -> void:
	_refresh_grid()


func _on_photo_added(_photo: PhotoData) -> void:
	if _is_open and _current_section == Section.PHOTOS:
		_refresh_grid()


func _on_photo_removed(_photo_id: String) -> void:
	if _is_open and _current_section == Section.PHOTOS:
		_refresh_grid()
