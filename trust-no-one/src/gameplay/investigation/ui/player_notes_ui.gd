class_name PlayerNotesUI
extends Control
## Sección placeholder del libro de investigación para las notas del jugador.
## Se implementará con funcionalidad completa en una fase posterior.


var _placeholder_label: Label

## Colores consistentes con el libro
const COLOR_HINT := Color(0.65, 0.60, 0.52)
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	# Ícono grande
	var icon_label := Label.new()
	icon_label.text = "🔍"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(icon_label)

	# Título
	var title_label := Label.new()
	title_label.text = "Notas del Jugador"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	vbox.add_child(title_label)

	# Subtítulo placeholder
	_placeholder_label = Label.new()
	_placeholder_label.text = "Esta sección estará disponible próximamente.\nAquí podrás escribir tus propias notas de investigación."
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_label.add_theme_font_size_override("font_size", 15)
	_placeholder_label.add_theme_color_override("font_color", COLOR_HINT)
	vbox.add_child(_placeholder_label)


## Placeholder para futura funcionalidad.
func refresh() -> void:
	pass
