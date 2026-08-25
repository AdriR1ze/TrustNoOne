extends Control
## UI principal del libro de fotos.
## Muestra una grilla scrolleable con thumbnails de las fotos capturadas.
## Se abre/cierra con la acción toggle_photo_book (tecla B).


## Referencia al visor expandido.
var _viewer: PhotoViewerUI
var _grid: GridContainer
var _scroll: ScrollContainer
var _background: ColorRect
var _title_label: Label
var _empty_label: Label
var _count_label: Label
var _is_open: bool = false




func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()
	_build_viewer()

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


## Abre el libro de fotos.
func open_book() -> void:
	if _is_open:
		return

	_is_open = true
	visible = true
	_refresh_grid()

	# Mostrar cursor y pausar movimiento
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


## Cierra el libro de fotos.
func close_book() -> void:
	if not _is_open:
		return

	_viewer.close()
	_is_open = false
	visible = false

	# Recapturar mouse y reanudar
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Fondo
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = Color(0.08, 0.06, 0.1, 0.92)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Contenedor principal
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 50)
	add_child(vbox)

	# Barra de título
	var title_bar := HBoxContainer.new()
	title_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_bar)

	_title_label = Label.new()
	_title_label.text = "📷 Fotografías"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 18)
	_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	title_bar.add_child(_count_label)

	var close_btn := Button.new()
	close_btn.text = "✕ Cerrar"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(close_book)
	title_bar.add_child(close_btn)

	# Separador
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 20)
	vbox.add_child(sep)

	# Label de "vacío"
	_empty_label = Label.new()
	_empty_label.text = "No hay fotografías aún.\nUsa el zoom (click derecho) y captura con click izquierdo."
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(_empty_label)

	# ScrollContainer con la grilla
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_scroll.add_child(_grid)

	# Hint inferior
	var hint_label := Label.new()
	hint_label.text = "[B] Cerrar  |  Click en foto para ampliar  |  ← → Navegar"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(hint_label)


func _build_viewer() -> void:
	_viewer = PhotoViewerUI.new()
	_viewer.name = "PhotoViewer"
	add_child(_viewer)
	_viewer.back_requested.connect(_on_viewer_back)


func _refresh_grid() -> void:
	# Limpiar grilla
	for child in _grid.get_children():
		child.queue_free()

	var photos := PhotoStorage.get_all_photos()
	_empty_label.visible = photos.is_empty()
	_scroll.visible = not photos.is_empty()
	_count_label.text = "%d / %d" % [photos.size(), PhotoStorage.MAX_PHOTOS]

	for i in range(photos.size()):
		var photo := photos[i]
		var thumbnail := PhotoThumbnail.new()
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
	if _is_open:
		_refresh_grid()


func _on_photo_removed(_photo_id: String) -> void:
	if _is_open:
		_refresh_grid()
