extends Node
## Base de datos persistente de objetos anotados.
## Guarda en disco los objetos que el jugador anota
## para que las anotaciones sobrevivan al cierre del juego.

const ARCHIVO := "user://anotaciones.json"

var _anotados : Dictionary = {}


func _ready() -> void:
	_anotados.clear()


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


func desanotar(id_unico : int) -> bool:
	if not _anotados.erase(id_unico):
		return false
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


func limpiar() -> void:
	_anotados.clear()
	guardar()


func guardar() -> void:
	var archivo := FileAccess.open(ARCHIVO, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar anotaciones: " + ARCHIVO)
		return
	archivo.store_string(JSON.stringify(_anotados, "  "))
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
		for clave in datos:
			_anotados[int(clave)] = datos[clave]
