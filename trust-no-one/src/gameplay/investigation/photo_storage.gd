extends Node
## Singleton (autoload) que gestiona la colección de fotografías del jugador.
## Almacena fotos en memoria. Emite señales para que la UI reaccione.


## Emitida cuando se agrega una foto nueva.
signal photo_added(photo: PhotoData)

## Emitida cuando se elimina una foto.
signal photo_removed(photo_id: String)

## Emitida cuando se alcanza el límite de fotos.
signal storage_full


## Cantidad máxima de fotos que el jugador puede almacenar.
const MAX_PHOTOS: int = 20

## Colección interna de fotos indexada por ID.
var _photos: Dictionary = {}

## Orden de inserción para navegación secuencial.
var _photo_order: Array[String] = []


## Agrega una foto al almacenamiento. Retorna true si se agregó exitosamente.
func add_photo(photo: PhotoData) -> bool:
	if photo == null:
		push_warning("PhotoStorage: Se intentó agregar una foto null.")
		return false

	if _photos.size() >= MAX_PHOTOS:
		storage_full.emit()
		push_warning("PhotoStorage: Almacenamiento lleno (%d/%d)." % [_photos.size(), MAX_PHOTOS])
		return false

	if _photos.has(photo.photo_id):
		push_warning("PhotoStorage: Foto con ID '%s' ya existe." % photo.photo_id)
		return false

	_photos[photo.photo_id] = photo
	_photo_order.append(photo.photo_id)
	photo_added.emit(photo)
	return true


## Elimina una foto del almacenamiento por su ID.
func remove_photo(photo_id: String) -> bool:
	if not _photos.has(photo_id):
		push_warning("PhotoStorage: No existe foto con ID '%s'." % photo_id)
		return false

	_photos.erase(photo_id)
	_photo_order.erase(photo_id)
	photo_removed.emit(photo_id)
	return true


## Obtiene una foto por su ID. Retorna null si no existe.
func get_photo(photo_id: String) -> PhotoData:
	return _photos.get(photo_id, null)


## Retorna todas las fotos en orden de captura.
func get_all_photos() -> Array[PhotoData]:
	var result: Array[PhotoData] = []
	for id in _photo_order:
		if _photos.has(id):
			result.append(_photos[id])
	return result


## Cantidad de fotos almacenadas.
func get_photo_count() -> int:
	return _photos.size()


## Retorna true si el almacenamiento está lleno.
func is_full() -> bool:
	return _photos.size() >= MAX_PHOTOS


## Retorna el índice de una foto en el orden de captura. -1 si no existe.
func get_photo_index(photo_id: String) -> int:
	return _photo_order.find(photo_id)


## Obtiene una foto por su índice en el orden de captura. Retorna null si el índice es inválido.
func get_photo_at_index(index: int) -> PhotoData:
	if index < 0 or index >= _photo_order.size():
		return null
	return _photos.get(_photo_order[index], null)
