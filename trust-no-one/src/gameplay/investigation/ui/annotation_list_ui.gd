class_name AnnotationListUI
extends Control
## Sección del libro de investigación que muestra los objetos anotados como textos manuscritos arrastrables
## y permite conectarlos con círculos y flechas dibujadas a mano (Click derecho en uno, click izquierdo en otro).

const ANNOTATION_ENTRY_SCENE = preload("res://src/gameplay/investigation/ui/annotation_entry.tscn")

signal connection_state_changed(is_connecting: bool)

@onready var _canvas_area: Control = %CanvasArea
@onready var _connections_canvas: AnnotationConnectionsCanvas = %ConnectionsCanvas
@onready var _entries_container: Control = %EntriesContainer
@onready var _empty_label: Label = %EmptyLabel

var _entries_map: Dictionary = {}  # id_unico -> AnnotationEntry
var _connecting_from_id: int = -1


func _ready() -> void:
	_canvas_area.gui_input.connect(_on_canvas_gui_input)


func _process(_delta: float) -> void:
	if _connecting_from_id != -1 and visible:
		var mouse_pos := _canvas_area.get_local_mouse_position()
		_connections_canvas.update_mouse_position(mouse_pos)


## Reconstruye los textos manuscritos de anotaciones en el lienzo libre y sus conexiones.
func refresh() -> void:
	_connecting_from_id = -1
	_entries_map.clear()

	# Limpiar lienzo
	for child in _entries_container.get_children():
		child.queue_free()

	var ids := AnotacionesDb.todas()
	_empty_label.visible = ids.is_empty()
	_canvas_area.visible = not ids.is_empty()

	for i in range(ids.size()):
		var id_unico: int = ids[i]
		var entry: AnnotationEntry = ANNOTATION_ENTRY_SCENE.instantiate()
		_entries_container.add_child(entry)
		_entries_map[id_unico] = entry

		# Posición inicial si nunca se movió
		var col := i % 3
		var row := int(i / 3)
		var default_pos := Vector2(40.0 + col * 220.0, 40.0 + row * 60.0)

		entry.setup(id_unico, default_pos)
		entry.right_clicked.connect(_on_entry_right_clicked)
		entry.left_clicked.connect(_on_entry_left_clicked)
		entry.drag_moved.connect(_on_entry_drag_moved)
		entry.drag_ended.connect(_on_entry_drag_ended)

	_connections_canvas.set_entries(_entries_map)
	_connections_canvas.set_connecting_from(-1)


func _on_entry_right_clicked(id_unico: int) -> void:
	if _connecting_from_id == id_unico:
		# Cancelar modo de conexión
		_connecting_from_id = -1
	else:
		# Iniciar modo de conexión desde este elemento
		_connecting_from_id = id_unico

	_connections_canvas.set_connecting_from(_connecting_from_id)
	connection_state_changed.emit(_connecting_from_id != -1)


func _on_entry_left_clicked(id_unico: int) -> void:
	if _connecting_from_id != -1:
		if _connecting_from_id != id_unico:
			# Conectar el origen con este destino
			var from_id := _connecting_from_id
			var to_id := id_unico

			# Si ya existía, toggle/eliminar; si no, agregar
			var conns := AnotacionesDb.obtener_conexiones()
			var exists := false
			for c in conns:
				if c.get("from") == from_id and c.get("to") == to_id:
					exists = true
					break

			if exists:
				AnotacionesDb.eliminar_conexion(from_id, to_id)
			else:
				AnotacionesDb.agregar_conexion(from_id, to_id)

			_connecting_from_id = -1
			_connections_canvas.set_connecting_from(-1)
			connection_state_changed.emit(false)
		else:
			# Click en el mismo elemento: cancelar
			_connecting_from_id = -1
			_connections_canvas.set_connecting_from(-1)
			connection_state_changed.emit(false)


func _on_entry_drag_moved(_id_unico: int, _pos: Vector2) -> void:
	_connections_canvas.queue_redraw()


func _on_entry_drag_ended(_id_unico: int, _pos: Vector2) -> void:
	_connections_canvas.queue_redraw()


func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _connecting_from_id != -1:
			_connecting_from_id = -1
			_connections_canvas.set_connecting_from(-1)
			connection_state_changed.emit(false)
