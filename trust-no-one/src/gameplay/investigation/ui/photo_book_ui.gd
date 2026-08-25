extends Control
## UI principal del libro de fotos.
## Muestra una grilla scrolleable con thumbnails de las fotos capturadas.
## Se abre/cierra con la acción toggle_photo_book (tecla B).


## Referencia al visor expandido.
var _viewer: PhotoViewerUI
var _grid: GridContainer
var _scroll: ScrollContainer
var _page_panel: PanelContainer
var _title_label: Label
var _empty_label: Label
var _count_label: Label
var _is_open: bool = false

## Colores del libro
const COLOR_PAGE := Color(0.96, 0.94, 0.90)         # Crema/papel
const COLOR_PAGE_BORDER := Color(0.78, 0.74, 0.68)   # Borde cuero
const COLOR_COVER := Color(0.18, 0.14, 0.12, 0.92)   # Fondo oscuro detrás
const COLOR_TITLE := Color(0.25, 0.20, 0.15)          # Título marrón oscuro
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)       # Subtextos
const COLOR_HINT := Color(0.65, 0.60, 0.52)           # Hints
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)         # Acento cálido


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

	# Fondo oscuro detrás del libro (simula escritorio)
	var bg_overlay := ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = COLOR_COVER
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg_overlay)

	# Panel "página" centrado (no ocupa toda la pantalla)
	_page_panel = PanelContainer.new()
	_page_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page_panel.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	# Márgenes para que parezca una página sobre el escritorio
	_page_panel.offset_left = 120
	_page_panel.offset_right = -120
	_page_panel.offset_top = 50
	_page_panel.offset_bottom = -50

	# Estilo de la página
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = COLOR_PAGE
	page_style.border_color = COLOR_PAGE_BORDER
	page_style.set_border_width_all(2)
	page_style.set_corner_radius_all(4)
	page_style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	page_style.shadow_size = 12
	page_style.shadow_offset = Vector2(4, 6)
	page_style.set_content_margin_all(40)
	_page_panel.add_theme_stylebox_override("panel", page_style)
	add_child(_page_panel)

	# Contenedor vertical dentro de la página
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	_page_panel.add_child(vbox)

	# === Encabezado ===
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	# Título estilo manuscrito/diario
	_title_label = Label.new()
	_title_label.text = "Fotografías"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", COLOR_TITLE)
	header.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	# Contador de fotos
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_count_label)

	# Botón cerrar discreto
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 18)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	close_style.set_content_margin_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.0, 0.0, 0.0, 0.08)
	close_hover.set_corner_radius_all(4)
	close_hover.set_content_margin_all(6)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_color_override("font_color", COLOR_SUBTITLE)
	close_btn.add_theme_color_override("font_hover_color", COLOR_TITLE)
	close_btn.pressed.connect(close_book)
	header.add_child(close_btn)

	# Línea separadora fina
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = COLOR_PAGE_BORDER
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line)

	# === Label vacío ===
	_empty_label = Label.new()
	_empty_label.text = "No hay fotografías aún.\nUsa el zoom (click derecho) y captura con click izquierdo."
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 16)
	_empty_label.add_theme_color_override("font_color", COLOR_HINT)
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(_empty_label)

	# === ScrollContainer con la grilla de fotos ===
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	_scroll.add_child(_grid)

	# === Pie de página ===
	var footer_line := ColorRect.new()
	footer_line.custom_minimum_size = Vector2(0, 1)
	footer_line.color = COLOR_PAGE_BORDER
	footer_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(footer_line)

	var hint_label := Label.new()
	hint_label.text = "[B] Cerrar    ·    Click en foto para ampliar    ·    ← → Navegar"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", COLOR_HINT)
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
	_count_label.text = "%d / %d fotos" % [photos.size(), PhotoStorage.MAX_PHOTOS]

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
