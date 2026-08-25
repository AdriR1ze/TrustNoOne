extends Control
class_name LibroUi
## Vista de pagina del libro. Muestra el titulo de la pagina y, si la pagina
## lo pide, la lista de objetos anotados guardados en AnotacionesDb.

@onready var titulo_label: Label = %TituloLabel
@onready var contenido_box: VBoxContainer = %ContenidoBox
@onready var cerrar_button: Button = %CerrarButton


func _ready() -> void:
	cerrar_button.pressed.connect(_cerrar)
	visible = false


func mostrar_pagina(pagina: Page) -> void:
	titulo_label.text = pagina.titulo
	_limpiar_contenido()
	if pagina.mostrar_anotaciones:
		_mostrar_anotaciones()
	visible = true


func _mostrar_anotaciones() -> void:
	var ids := AnotacionesDb.todas()
	if ids.is_empty():
		_agregar_linea("No hay anotaciones todavia.")
		return
	for id_unico in ids:
		_agregar_linea("Objeto #" + str(id_unico))


func _agregar_linea(texto: String) -> void:
	var label := Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenido_box.add_child(label)


func _limpiar_contenido() -> void:
	for child in contenido_box.get_children():
		child.queue_free()


func _cerrar() -> void:
	visible = false
