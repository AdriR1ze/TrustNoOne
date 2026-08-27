class_name PlayerNotesUI
extends Control
## Sección placeholder del libro de investigación para las notas del jugador.
## Se implementará con funcionalidad completa en una fase posterior.

@onready var _placeholder_label: Label = %PlaceholderLabel

## Colores consistentes con el libro
const COLOR_HINT := Color(0.65, 0.60, 0.52)
const COLOR_SUBTITLE := Color(0.50, 0.45, 0.38)
const COLOR_ACCENT := Color(0.55, 0.35, 0.20)


func _ready() -> void:
	pass


## Placeholder para futura funcionalidad.
func refresh() -> void:
	pass
