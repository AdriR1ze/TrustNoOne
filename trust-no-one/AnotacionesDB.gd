extends Node
## Base de datos persistente de objetos anotados y sus conexiones.
## Guarda en disco los objetos que el jugador anota
## para que las anotaciones sobrevivan al cierre del juego.

const ARCHIVO := "user://anotaciones.json"

var _anotados : Dictionary = {}
var _conexiones : Array = []


func _ready() -> void:
	_anotados.clear()
	_conexiones.clear()


func anotar(id_unico : int, posicion : Vector3 = Vector3.ZERO) -> bool:
	if id_unico == 0 or _anotados.has(id_unico):
		return false
	_anotados[id_unico] = {
		"pos_x": posicion.x,
		"pos_y": posicion.y,
		"pos_z": posicion.z,
	}
	guardar()
	return true


func actualizar_posicion_ui(id_unico: int, ui_x: float, ui_y: float) -> void:
	if _anotados.has(id_unico):
		_anotados[id_unico]["ui_x"] = ui_x
		_anotados[id_unico]["ui_y"] = ui_y
		guardar()


func desanotar(id_unico : int) -> bool:
	if not _anotados.erase(id_unico):
		return false
	# Eliminar conexiones asociadas
	_conexiones = _conexiones.filter(func(c): return c.get("from") != id_unico and c.get("to") != id_unico)
	guardar()
	return true


func esta_anotado(id_unico : int) -> bool:
	return _anotados.has(id_unico)


func obtener(id_unico : int):
	return _anotados.get(id_unico, null)


func todas() -> Array:
	return _anotados.keys()


func cantidad() -> int:
	return _anotados.size()


func agregar_conexion(from_id: int, to_id: int) -> bool:
	if from_id == to_id or not _anotados.has(from_id) or not _anotados.has(to_id):
		return false
	for conn in _conexiones:
		if conn.get("from") == from_id and conn.get("to") == to_id:
			return false
	_conexiones.append({"from": from_id, "to": to_id})
	guardar()
	return true


func eliminar_conexion(from_id: int, to_id: int) -> bool:
	for i in range(_conexiones.size()):
		var conn: Dictionary = _conexiones[i]
		if conn.get("from") == from_id and conn.get("to") == to_id:
			_conexiones.remove_at(i)
			guardar()
			return true
	return false


func obtener_conexiones() -> Array:
	return _conexiones.duplicate()


func limpiar() -> void:
	_anotados.clear()
	_conexiones.clear()
	guardar()


func guardar() -> void:
	var archivo := FileAccess.open(ARCHIVO, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar anotaciones: " + ARCHIVO)
		return
	var save_data := {
		"anotados": _anotados,
		"conexiones": _conexiones
	}
	archivo.store_string(JSON.stringify(save_data, "  "))
	archivo.close()


func cargar() -> void:
	if not FileAccess.file_exists(ARCHIVO):
		return
	var archivo := FileAccess.open(ARCHIVO, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo cargar anotaciones: " + ARCHIVO)
		return
	var datos = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if datos is Dictionary:
		_anotados.clear()
		_conexiones.clear()
		if datos.has("anotados"):
			var anotados_dict: Dictionary = datos.get("anotados", {})
			for clave in anotados_dict:
				_anotados[int(clave)] = anotados_dict[clave]
			var conns = datos.get("conexiones", [])
			if conns is Array:
				_conexiones = conns
		else:
			for clave in datos:
				_anotados[int(clave)] = datos[clave]
