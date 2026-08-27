class_name AnnotationListUI
extends Control
## Sección del libro de investigación que muestra los objetos anotados.
## Lee de AnotacionesDb + ObjectDb para construir la lista visual.


var _scroll: ScrollContainer
var _list: VBoxContainer
var _empty_label: Label

## Colores consistentes con el libro
const COLOR_PAGE := Color(0.96, 0.94, 0.90)
const COLOR_PAGE_BORDER := Color(0.78, 0.74, 0.68)
const COLOR_TITLE := Color(0.25, 0.20, 0.15)
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)
const COLOR_HINT := Color(0.65, 0.60, 0.52)
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)
const COLOR_CARD_BG := Color(1.0, 1.0, 1.0)
const COLOR_DANGER := Color(0.72, 0.25, 0.20)
const COLOR_DANGER_HOVER := Color(0.85, 0.30, 0.22)
const COLOR_CHECK := Color(0.30, 0.65, 0.35)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()


func _build_ui() -> void:
	# Label de vacío
	_empty_label = Label.new()
	_empty_label.text = "No has anotado ningún objeto aún.\nAcércate a un objeto y presiona Q para anotarlo."
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 16)
	_empty_label.add_theme_color_override("font_color", COLOR_HINT)
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_empty_label)

	# Scroll con la lista
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)


## Reconstruye la lista de anotaciones desde la base de datos.
func refresh() -> void:
	# Limpiar lista
	for child in _list.get_children():
		child.queue_free()

	var ids := AnotacionesDb.todas()
	_empty_label.visible = ids.is_empty()
	_scroll.visible = not ids.is_empty()

	for id_unico in ids:
		var entry := _create_entry(id_unico)
		_list.add_child(entry)


## Crea una entrada visual para un objeto anotado.
func _create_entry(id_unico: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Estilo de la tarjeta
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.border_color = COLOR_PAGE_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.08)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Ícono de check
	var icon_label := Label.new()
	icon_label.text = "✓"
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.add_theme_color_override("font_color", COLOR_CHECK)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info del objeto
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	# Nombre del objeto
	var nombre := _obtener_nombre(id_unico)
	var name_label := Label.new()
	name_label.text = nombre
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", COLOR_TITLE)
	info_vbox.add_child(name_label)

	# Posición donde se anotó
	var datos = AnotacionesDb.obtener(id_unico)
	if datos != null:
		var pos_label := Label.new()
		var px: float = datos.get("pos_x", 0.0)
		var py: float = datos.get("pos_y", 0.0)
		var pz: float = datos.get("pos_z", 0.0)
		pos_label.text = "Posición: (%.0f, %.0f, %.0f)" % [px, py, pz]
		pos_label.add_theme_font_size_override("font_size", 13)
		pos_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
		info_vbox.add_child(pos_label)

	# Botón desanotar
	var remove_btn := Button.new()
	remove_btn.text = "✕"
	remove_btn.tooltip_text = "Quitar anotación"
	remove_btn.custom_minimum_size = Vector2(36, 36)
	remove_btn.add_theme_font_size_override("font_size", 16)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	btn_normal.set_content_margin_all(6)
	remove_btn.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(COLOR_DANGER.r, COLOR_DANGER.g, COLOR_DANGER.b, 0.12)
	btn_hover.set_corner_radius_all(4)
	btn_hover.set_content_margin_all(6)
	remove_btn.add_theme_stylebox_override("hover", btn_hover)

	remove_btn.add_theme_color_override("font_color", COLOR_HINT)
	remove_btn.add_theme_color_override("font_hover_color", COLOR_DANGER)

	var captured_id := id_unico
	remove_btn.pressed.connect(func(): _on_remove_pressed(captured_id))
	hbox.add_child(remove_btn)

	return panel


## Obtiene el nombre legible de un objeto por su id_unico.
func _obtener_nombre(id_unico: int) -> String:
	var objeto = ObjectDb.obtener(id_unico)
	if objeto != null and objeto is Objeto:
		if objeto.nombre_objeto != "":
			return objeto.nombre_objeto
	return "Objeto #%d" % id_unico


## Quita una anotación y refresca la lista.
func _on_remove_pressed(id_unico: int) -> void:
	AnotacionesDb.desanotar(id_unico)
	refresh()
