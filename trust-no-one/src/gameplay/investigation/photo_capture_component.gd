class_name PhotoCaptureComponent
extends Node
## Componente de captura de fotos. Se agrega como hijo del Player.
## Usa un SubViewport para renderizar lo que la cámara del jugador ve
## y capturarlo como imagen al presionar la acción take_photo.


## Emitida cuando se captura una foto exitosamente.
signal photo_captured(photo: PhotoData)

## Resolución de la captura.
@export var capture_width: int = 960
@export var capture_height: int = 540

var player: Player
var _sub_viewport: SubViewport
var _sub_camera: Camera3D
var _can_capture: bool = true


func _ready() -> void:
	player = get_parent() as Player
	if player == null:
		push_error("PhotoCaptureComponent: El padre debe ser un Player.")
		return

	_setup_sub_viewport()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("take_photo"):
		_try_capture()


func _process(_delta: float) -> void:
	_sync_sub_camera()


## Configura el SubViewport y la cámara secundaria para la captura.
func _setup_sub_viewport() -> void:
	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "CaptureViewport"
	_sub_viewport.size = Vector2i(capture_width, capture_height)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.transparent_bg = false
	# Usar las mismas settings del mundo principal
	_sub_viewport.world_3d = player.get_viewport().world_3d
	add_child(_sub_viewport)

	_sub_camera = Camera3D.new()
	_sub_camera.name = "CaptureCamera"
	_sub_viewport.add_child(_sub_camera)



## Sincroniza la cámara del SubViewport con la cámara del jugador.
func _sync_sub_camera() -> void:
	if _sub_camera == null or player == null or player.camera == null:
		return
	_sub_camera.global_transform = player.camera.global_transform
	_sub_camera.fov = player.camera.fov
	_sub_camera.near = player.camera.near
	_sub_camera.far = player.camera.far


## Intenta capturar una foto. Solo funciona durante el zoom.
func _try_capture() -> void:
	if not _can_capture:
		return

	# Solo permitir captura durante el zoom
	if not Input.is_action_pressed("zoom"):
		return

	if PhotoStorage.is_full():
		push_warning("PhotoCaptureComponent: Almacenamiento de fotos lleno.")
		return

	_capture_photo()


## Ejecuta la captura de foto.
func _capture_photo() -> void:
	_can_capture = false

	# Esperar un frame para que el SubViewport tenga contenido actualizado
	await RenderingServer.frame_post_draw

	var image: Image = _sub_viewport.get_texture().get_image()
	if image == null:
		push_error("PhotoCaptureComponent: No se pudo obtener imagen del SubViewport.")
		_can_capture = true
		return

	var photo := PhotoData.create(
		image,
		player.global_position
	)

	var success := PhotoStorage.add_photo(photo)
	if success:
		photo_captured.emit(photo)

	# Pequeño cooldown para evitar capturas múltiples accidentales
	await get_tree().create_timer(0.5).timeout
	_can_capture = true
