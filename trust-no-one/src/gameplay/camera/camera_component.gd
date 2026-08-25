class_name CameraComponent
extends Node


@export_group("Sensitivity")
## Sensibilidad del mouse (radianes por pixel).
@export var mouse_sensitivity := 0.002

@export_group("Vertical Clamp")
## Angulo maximo mirando hacia arriba (grados).
@export var pitch_max := 80.0
## Angulo maximo mirando hacia abajo (grados).
@export var pitch_min := -80.0

var player: Player
var camera: Camera3D
var _pitch := 0.0  # rotacion vertical acumulada (radianes)


func _ready() -> void:
	player = get_parent() as Player
	camera = player.get_node("Camera3D") as Camera3D
	# Inicializar _pitch con la rotacion actual de la camara para no hacer snap
	_pitch = camera.rotation.x
	# Captura el mouse al iniciar
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotate_camera(event.relative)

	# Presionar Escape libera / recaptura el cursor
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rotate_camera(mouse_delta: Vector2) -> void:
	# Rotacion horizontal: rota el Player en Y (yaw)
	player.rotate_y(-mouse_delta.x * mouse_sensitivity)

	# Rotacion vertical: rota solo la camara en X (pitch) con clamp
	_pitch -= mouse_delta.y * mouse_sensitivity
	_pitch = clamp(_pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	camera.rotation.x = _pitch
