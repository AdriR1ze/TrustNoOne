class_name PhotoData
extends Resource
## Modelo de datos de una fotografía capturada por el jugador.
## Estructura extensible para futuras funcionalidades (tags, pistas, eventos).


## Identificador único de la fotografía.
var photo_id: String = ""

## Imagen capturada (raw).
var image: Image = null

## Textura generada a partir de la imagen (para UI).
var texture: ImageTexture = null

## Fecha/hora de captura (resultado de Time.get_datetime_dict_from_system()).
var capture_time: Dictionary = {}

## Posición global en el escenario donde se capturó la foto.
var capture_position: Vector3 = Vector3.ZERO

## Nombre legible para mostrar en la UI.
var display_name: String = ""

# --- Campos de extensibilidad futura ---

## Etiquetas asignadas por el jugador.
var tags: Array[String] = []

## IDs de pistas vinculadas a esta foto.
var linked_clue_ids: Array[String] = []

## IDs de eventos vinculados a esta foto.
var linked_event_ids: Array[String] = []

## Notas del jugador sobre esta foto.
var notes: String = ""


## Crea un PhotoData completo con imagen, posición y nombre.
static func create(p_image: Image, p_position: Vector3, p_name: String = "") -> PhotoData:
	var photo := PhotoData.new()
	photo.photo_id = _generate_id()
	photo.image = p_image
	photo.texture = ImageTexture.create_from_image(p_image)
	photo.capture_time = Time.get_datetime_dict_from_system()
	photo.capture_position = p_position
	photo.display_name = p_name if p_name != "" else "Foto_%s" % photo.photo_id.left(8)
	return photo


## Genera un ID único basado en unix time + random.
static func _generate_id() -> String:
	var time_part := str(Time.get_unix_time_from_system()).replace(".", "")
	var rand_part := str(randi() % 99999).pad_zeros(5)
	return "%s_%s" % [time_part, rand_part]
