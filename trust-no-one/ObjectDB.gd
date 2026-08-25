extends Node
## Base de datos simple de objetos.
## Guarda objetos por su id_unico y permite buscarlos, listarlos y eliminarlos.

var _objetos : Dictionary = {}

func registrar(objeto) -> bool:
	if objeto.id_unico == 0:
		return false
	_objetos[objeto.id_unico] = objeto
	return true

func obtener(id_unico : int):
	return _objetos.get(id_unico, null)

func contiene(id_unico : int) -> bool:
	return _objetos.has(id_unico)

func eliminar(id_unico : int) -> void:
	_objetos.erase(id_unico)

func todos() -> Array:
	return _objetos.values()

func cantidad() -> int:
	return _objetos.size()

func limpiar() -> void:
	_objetos.clear()
