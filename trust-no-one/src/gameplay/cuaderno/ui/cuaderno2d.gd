extends Control
## UI principal del libro de investigación.
## Contiene 3 secciones organizadas por pestañas:
## 1. Fotografías — Grilla de fotos capturadas
## 2. Objetos — Lista de objetos anotados
## 3. Notas — Notas del jugador
## Se abre/cierra con la acción toggle_photo_book (tecla B).

const PHOTO_THUMBNAIL_SCENE = preload("res://src/gameplay/cuaderno/ui/seccion_fotos/photo_thumbnail.tscn")

@export var tab_active_style: StyleBox
@export var tab_inactive_style: StyleBox

## Pestañas (Secciones)
enum Section { PHOTOS, ANNOTATIONS, NOTES }
var _current_section: Section = Section.PHOTOS
var _max_sections: int = 3
var _is_open: bool = false

## Referencias a nodos de la escena 
@onready var _notebook_3d: Notebook3DView = %Notebook3DView
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
@onready var _prev_button: Button = %PrevButton
@onready var _next_button: Button = %NextButton
@onready var _page_panel: Control = $PagePanel

## Colores del libro
const COLOR_TITLE := Color(0.25, 0.20, 0.15)          # Título marrón oscuro
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)       # Subtextos


func _ready() -> void:
	visible = false

	_prev_button.pressed.connect(_on_prev_pressed)
	_next_button.pressed.connect(_on_next_pressed)

	_close_button.pressed.connect(close_book)
	_viewer.back_requested.connect(_on_viewer_back)
	_annotations_ui.connection_state_changed.connect(_on_annotation_connection_state_changed)

	# Conectar señales del storage
	PhotoStorage.photo_added.connect(_on_photo_added)
	PhotoStorage.photo_removed.connect(_on_photo_removed)

	# Conectar la señal del cuaderno 3D para alinear la UI 2D
	_notebook_3d.notebook_rect_ready.connect(_on_notebook_rect_ready)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_photo_book"):
		if _is_open:
			close_book()
		else:
			open_book()
		get_viewport().set_input_as_handled()

	# Si el libro está abierto, manejar flechas para pasar hojas o ESC para cerrar
	if _is_open:
		if event.is_action_pressed("ui_cancel"):
			if _viewer.visible:
				return  # El viewer maneja su propio ESC
			close_book()
			get_viewport().set_input_as_handled()
		elif not _viewer.visible and not _is_animating:
			if event.is_action_pressed("ui_left"):
				_on_prev_pressed()
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_right"):
				_on_next_pressed()
				get_viewport().set_input_as_handled()


## Abre el libro de investigación.
func open_book() -> void:
	if _is_open:
		return

	_is_open = true
	visible = true
	
	if _notebook_3d:
		_notebook_3d.reset()
	_switch_to_section(_current_section, true)

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


## Alinea el PagePanel al rectángulo proyectado del cuaderno 3D.
## Posiciona el contenido 2D dentro de la zona visible del cuaderno,
## en la parte superior para que actúe como "título" de cada página.
func _on_notebook_rect_ready(rect: Rect2) -> void:
	# Pequeño margen interior para que el texto no pegue contra los bordes del cuaderno
	var inset := 0.02
	_page_panel.anchor_left = rect.position.x + inset
	_page_panel.anchor_right = rect.position.x + rect.size.x - inset
	# Colocar en la parte superior del cuaderno (primer 60% del alto del notebook)
	_page_panel.anchor_top = rect.position.y + inset
	_page_panel.anchor_bottom = rect.position.y + rect.size.y * 0.6
	# Resetear offsets para que los anchors manden
	_page_panel.offset_left = 0
	_page_panel.offset_top = 0
	_page_panel.offset_right = 0
	_page_panel.offset_bottom = 0
	print("cuaderno2d: PagePanel alineado a rect=%s" % rect)





var _is_animating: bool = false

## Cambia la sección activa del libro.
func _switch_to_section(section: Section, force_instant: bool = false) -> void:
	if _current_section == section and not force_instant:
		return
	if _is_animating:
		return

	var old_section = _current_section
	_current_section = section

	var forwards = section > old_section
	var page_idx = int(section) - 1 if forwards else int(section)

	# Ocultar contenido mientras se anima (excepto al abrir por primera vez)
	if not force_instant and visible:
		_photos_container.visible = false
		_annotations_ui.visible = false
		_notes_ui.visible = false
		
		_is_animating = true
		if forwards:
			_notebook_3d.play_page_turn(page_idx)
		else:
			_notebook_3d.play_page_turn_reverse(page_idx)
		
		await _notebook_3d.page_turn_finished
		_is_animating = false

	# Actualizar visibilidad de la nueva sección
	_photos_container.visible = section == Section.PHOTOS
	_annotations_ui.visible = section == Section.ANNOTATIONS
	_notes_ui.visible = section == Section.NOTES

	# Actualizar controles de navegación
	_prev_button.visible = section > 0
	_next_button.visible = int(section) < _max_sections - 1

	# Actualizar contenido y título según sección
	match section:
		Section.PHOTOS:
			_title_label.text = "Fotografías"
			_refresh_grid()
			_hint_label.text = "[B] Cerrar  ·  [<][>] Navegar Hojas  ·  Click en foto para ampliar"
		Section.ANNOTATIONS:
			_title_label.text = "Objetos Anotados"
			_annotations_ui.refresh()
			_count_label.text = "%d objetos anotados" % AnotacionesDb.cantidad()
			_hint_label.text = "[B] Cerrar  ·  [<][>] Navegar Hojas  ·  Click derecho para conectar  ·  Arrastrar para mover"
		Section.NOTES:
			_title_label.text = "Notas Personales"
			_notes_ui.refresh()
			_count_label.text = ""
			_hint_label.text = "[B] Cerrar  ·  [<][>] Navegar Hojas"

func _on_prev_pressed() -> void:
	if int(_current_section) > 0 and not _is_animating:
		_switch_to_section(_current_section - 1 as Section)

func _on_next_pressed() -> void:
	if int(_current_section) < _max_sections - 1 and not _is_animating:
		_switch_to_section(_current_section + 1 as Section)


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
