class_name AnnotationConnectionsCanvas
extends Control
## Lienzo para dibujar círculos y flechas estilo boceto manuscrito entre anotaciones.

const COLOR_INK_RED := Color(0.82, 0.22, 0.18, 0.90)
const COLOR_PREVIEW_RED := Color(0.82, 0.22, 0.18, 0.60)

var _entries_map: Dictionary = {}  # id_unico -> AnnotationEntry
var _connecting_from_id: int = -1
var _mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_entries(entries_map: Dictionary) -> void:
	_entries_map = entries_map
	queue_redraw()


func set_connecting_from(id_unico: int) -> void:
	_connecting_from_id = id_unico
	queue_redraw()


func update_mouse_position(pos: Vector2) -> void:
	_mouse_pos = pos
	if _connecting_from_id != -1:
		queue_redraw()


func _draw() -> void:
	var connections: Array = AnotacionesDb.obtener_conexiones()

	# Recopilar todos los IDs que están conectados para dibujarles un círculo
	var connected_ids: Dictionary = {}
	for conn in connections:
		var from_id: int = conn.get("from", -1)
		var to_id: int = conn.get("to", -1)
		if from_id != -1:
			connected_ids[from_id] = true
		if to_id != -1:
			connected_ids[to_id] = true

	# Si hay una conexión en curso, incluir el origen
	if _connecting_from_id != -1:
		connected_ids[_connecting_from_id] = true

	# 1. Dibujar círculos dibujados a mano alrededor de cada anotación conectada
	for id_unico in connected_ids.keys():
		if _entries_map.has(id_unico):
			var entry: AnnotationEntry = _entries_map[id_unico]
			if entry and is_instance_valid(entry):
				var center := entry.get_center_in_parent()
				var rx := (entry.size.x / 2.0) + 12.0
				var ry := (entry.size.y / 2.0) + 8.0
				_draw_hand_drawn_ellipse(center, rx, ry, COLOR_INK_RED, 2.2, id_unico)

	# 2. Dibujar flechas entre las anotaciones conectadas
	for conn in connections:
		var from_id: int = conn.get("from", -1)
		var to_id: int = conn.get("to", -1)
		if _entries_map.has(from_id) and _entries_map.has(to_id):
			var entry_a: AnnotationEntry = _entries_map[from_id]
			var entry_b: AnnotationEntry = _entries_map[to_id]
			if entry_a and entry_b and is_instance_valid(entry_a) and is_instance_valid(entry_b):
				var center_a := entry_a.get_center_in_parent()
				var rx_a := (entry_a.size.x / 2.0) + 12.0
				var ry_a := (entry_a.size.y / 2.0) + 8.0

				var center_b := entry_b.get_center_in_parent()
				var rx_b := (entry_b.size.x / 2.0) + 12.0
				var ry_b := (entry_b.size.y / 2.0) + 8.0

				var seed_val := from_id * 31 + to_id
				_draw_hand_drawn_arrow(center_a, rx_a, ry_a, center_b, rx_b, ry_b, COLOR_INK_RED, 2.2, seed_val)

	# 3. Dibujar flecha de previsualización en progreso hacia el mouse
	if _connecting_from_id != -1 and _entries_map.has(_connecting_from_id):
		var entry_from: AnnotationEntry = _entries_map[_connecting_from_id]
		if entry_from and is_instance_valid(entry_from):
			var center_from := entry_from.get_center_in_parent()
			var rx_from := (entry_from.size.x / 2.0) + 12.0
			var ry_from := (entry_from.size.y / 2.0) + 8.0
			_draw_preview_arrow(center_from, rx_from, ry_from, _mouse_pos, COLOR_PREVIEW_RED)


## Dibuja una elipse estilo boceto dibujado a mano con ligera doble pasada y variaciones.
func _draw_hand_drawn_ellipse(center: Vector2, rx: float, ry: float, color: Color, line_width: float, seed_val: int) -> void:
	var points: PackedVector2Array = []
	var num_points := 36
	var total_angle := TAU + 0.35  # Ligero solapamiento para simular el trazo manual cerrado

	for i in range(num_points + 1):
		var t := float(i) / float(num_points)
		var angle := t * total_angle
		var jitter := sin(angle * 3.0 + float(seed_val) * 1.7) * 2.2 + cos(angle * 5.0 + float(seed_val) * 2.3) * 1.2
		var p := center + Vector2(cos(angle) * (rx + jitter), sin(angle) * (ry + jitter * 0.7))
		points.append(p)

	draw_polyline(points, color, line_width, true)

	# Segunda pasada más suave
	var points2: PackedVector2Array = []
	for i in range(num_points + 1):
		var t := float(i) / float(num_points)
		var angle := t * total_angle + 0.12
		var jitter2 := sin(angle * 4.0 + float(seed_val) * 3.1) * 1.4
		var p2 := center + Vector2(cos(angle) * (rx - 0.8 + jitter2), sin(angle) * (ry - 0.6 + jitter2 * 0.6))
		points2.append(p2)

	var softer_color := Color(color.r, color.g, color.b, color.a * 0.55)
	draw_polyline(points2, softer_color, line_width * 0.75, true)


## Dibuja una flecha con curva orgánica y punta estilizada entre dos elementos.
func _draw_hand_drawn_arrow(start_center: Vector2, start_rx: float, start_ry: float, end_center: Vector2, end_rx: float, end_ry: float, color: Color, line_width: float, seed_val: int) -> void:
	var diff := end_center - start_center
	var dist := diff.length()
	if dist < 20.0:
		return

	var dir := diff / dist
	var perp := Vector2(-dir.y, dir.x)

	# Puntos en el borde de las elipses
	var p_start := start_center + Vector2(dir.x * start_rx, dir.y * start_ry)
	var p_end := end_center - Vector2(dir.x * end_rx, dir.y * end_ry)

	# Punto de control con ligera curvatura orgánica
	var bend_amount := sin(float(seed_val) * 4.31) * 18.0
	if abs(bend_amount) < 6.0:
		bend_amount = 12.0
	var mid := (p_start + p_end) / 2.0 + perp * bend_amount

	# Puntos de la curva Bezier con pequeñas irregularidades
	var curve_points: PackedVector2Array = []
	var num_segments := 24
	for i in range(num_segments + 1):
		var t := float(i) / float(num_segments)
		var pt := (1.0 - t) * (1.0 - t) * p_start + 2.0 * (1.0 - t) * t * mid + t * t * p_end
		if i > 0 and i < num_segments:
			var w := sin(t * PI)
			var jitter := sin(t * 14.0 + float(seed_val) * 2.0) * 1.3 * w
			pt += perp * jitter
		curve_points.append(pt)

	draw_polyline(curve_points, color, line_width, true)

	# Punta de la flecha en p_end
	var tangent := (p_end - mid).normalized()
	var head_perp := Vector2(-tangent.y, tangent.x)
	var head_len := 16.0
	var head_width := 9.0

	var wing1 := p_end - tangent * head_len + head_perp * head_width
	var wing2 := p_end - tangent * head_len - head_perp * head_width

	var arrow_pts1 := PackedVector2Array([wing1, p_end])
	var arrow_pts2 := PackedVector2Array([wing2, p_end])

	draw_polyline(arrow_pts1, color, line_width + 0.4, true)
	draw_polyline(arrow_pts2, color, line_width + 0.4, true)


## Dibuja la línea de previsualización en progreso hacia el cursor.
func _draw_preview_arrow(start_center: Vector2, start_rx: float, start_ry: float, target_pos: Vector2, color: Color) -> void:
	var diff := target_pos - start_center
	var dist := diff.length()
	if dist < 10.0:
		return

	var dir := diff / dist
	var p_start := start_center + Vector2(dir.x * start_rx, dir.y * start_ry)

	var pts := PackedVector2Array([p_start, target_pos])
	draw_polyline(pts, color, 1.8, true)
