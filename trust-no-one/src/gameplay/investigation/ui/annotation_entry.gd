class_name AnnotationEntry
extends PanelContainer
## Texto manuscrito del nombre del objeto anotado, arrastrable en la página.

signal right_clicked(id_unico: int)
signal left_clicked(id_unico: int)
signal drag_moved(id_unico: int, new_position: Vector2)
signal drag_ended(id_unico: int, new_position: Vector2)

var _id_unico: int = -1
var _dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_pos: Vector2 = Vector2.ZERO
var _has_dragged_significantly: bool = false

@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func get_id() -> int:
	return _id_unico


func get_center_in_parent() -> Vector2:
	return position + (size / 2.0)


func get_bounds_in_parent() -> Rect2:
	return Rect2(position, size)


## Configura el texto del objeto anotado y su posición.
func setup(id_unico: int, default_pos: Vector2 = Vector2.ZERO) -> void:
	_id_unico = id_unico

	var nombre := _obtener_nombre(id_unico)
	_name_label.text = nombre

	# Ligera inclinación natural manuscrita basada en su ID
	rotation_degrees = sin(float(id_unico) * 7.91) * 3.5

	# Posición guardada o por defecto
	var datos = AnotacionesDb.obtener(id_unico)
	if datos != null and datos.has("ui_x") and datos.has("ui_y"):
		position = Vector2(datos["ui_x"], datos["ui_y"])
	else:
		position = default_pos
		AnotacionesDb.actualizar_posicion_ui(_id_unico, position.x, position.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_clicked.emit(_id_unico)
			accept_event()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_has_dragged_significantly = false
				_drag_start_mouse = get_global_mouse_position()
				_drag_start_pos = position
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				move_to_front()
				left_clicked.emit(_id_unico)
				accept_event()
			else:
				if _dragging:
					_dragging = false
					mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					if _has_dragged_significantly:
						AnotacionesDb.actualizar_posicion_ui(_id_unico, position.x, position.y)
						drag_ended.emit(_id_unico, position)
					accept_event()

	elif event is InputEventMouseMotion and _dragging:
		var delta := get_global_mouse_position() - _drag_start_mouse
		if delta.length_squared() > 16.0:
			_has_dragged_significantly = true

		var new_pos := _drag_start_pos + delta

		var parent_ctrl := get_parent_control()
		if parent_ctrl:
			new_pos.x = clampf(new_pos.x, 0.0, maxf(0.0, parent_ctrl.size.x - size.x))
			new_pos.y = clampf(new_pos.y, 0.0, maxf(0.0, parent_ctrl.size.y - size.y))

		position = new_pos
		drag_moved.emit(_id_unico, position)
		accept_event()


func _obtener_nombre(id_unico: int) -> String:
	var objeto = ObjectDb.obtener(id_unico)
	if objeto != null and objeto is Objeto:
		if objeto.nombre_objeto != "":
			return objeto.nombre_objeto
	return "Objeto #%d" % id_unico
