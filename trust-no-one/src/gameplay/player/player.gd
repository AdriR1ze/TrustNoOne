extends CharacterBody3D
class_name Player

enum PlayerState {
	ZOOMING
}

@export var normal_fov := 75.0
@export var zoom_fov := 30.0
@export var zoom_duration := 0.25
@export var distancia_anotacion := 5.0

const RAY_THICKNESS := 0.04
const RAY_START_OFFSET := 0.6
const ETIQUETA_ALTURA := 1.5

@onready var camera: Camera3D = $Camera3D
@onready var ray_cast : RayCast3D = $RayCast3D

var ray_mesh: MeshInstance3D
var ray_tip: MeshInstance3D
var _beam_mesh := BoxMesh.new()
var _tip_mesh := SphereMesh.new()
var _beam_material := StandardMaterial3D.new()

var _objeto_mirado: Objeto = null
var _objeto_anotable: Objeto = null
var _etiqueta_anotar: Label3D

func _ready() -> void:
	add_to_group("player")
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.albedo_color = Color(1.0, 0.0, 0.0)
	_beam_material.emission_enabled = true
	_beam_material.emission = Color(1.0, 0.0, 0.0)
	_beam_material.emission_energy_multiplier = 2.0
	_beam_mesh.material = _beam_material
	_tip_mesh.radius = 0.07
	_tip_mesh.height = 0.14
	_tip_mesh.material = _beam_material
	ray_mesh = MeshInstance3D.new()
	ray_mesh.name = "RayMesh"
	ray_mesh.mesh = _beam_mesh
	add_child(ray_mesh)
	ray_tip = MeshInstance3D.new()
	ray_tip.name = "RayTip"
	ray_tip.mesh = _tip_mesh
	add_child(ray_tip)
	_crear_etiqueta_anotar()


func _crear_etiqueta_anotar() -> void:
	_etiqueta_anotar = Label3D.new()
	_etiqueta_anotar.name = "EtiquetaAnotar"
	_etiqueta_anotar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiqueta_anotar.no_depth_test = true
	_etiqueta_anotar.font_size = 96
	_etiqueta_anotar.outline_size = 20
	_etiqueta_anotar.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	_etiqueta_anotar.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_etiqueta_anotar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiqueta_anotar.text = _tecla_anotar() + " - Anotar"
	_etiqueta_anotar.visible = false
	add_child(_etiqueta_anotar)


func _tecla_anotar() -> String:
	for evento in InputMap.action_get_events("anotar_objeto"):
		if evento is InputEventKey:
			return OS.get_keycode_string(evento.physical_keycode)
	return "?"

func _physics_process(delta: float) -> void:
	ray_cast.global_rotation = camera.global_rotation
	_objeto_mirado = null
	if ray_cast.is_colliding():
		var colision := ray_cast.get_collider()
		if colision is Objeto:
			_objeto_mirado = colision as Objeto
	_actualizar_objeto_anotable()


func _actualizar_objeto_anotable() -> void:
	_objeto_anotable = null
	if _objeto_mirado == null:
		_etiqueta_anotar.visible = false
		return
	var distancia := ray_cast.global_position.distance_to(ray_cast.get_collision_point())
	if distancia <= distancia_anotacion and not AnotacionesDb.esta_anotado(_objeto_mirado.id_unico):
		_objeto_anotable = _objeto_mirado
		_etiqueta_anotar.global_position = _objeto_mirado.global_position + Vector3(0.0, ETIQUETA_ALTURA, 0.0)
		_etiqueta_anotar.visible = true
	else:
		_etiqueta_anotar.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("anotar_objeto"):
		_anotar_objeto_mirado()


func _anotar_objeto_mirado() -> void:
	if _objeto_anotable == null:
		print("No hay ningun objeto cercano para anotar")
		return
	var id := _objeto_anotable.id_unico
	if AnotacionesDb.anotar(id, _objeto_anotable.global_position):
		print("Objeto anotado: ", id)
		_etiqueta_anotar.visible = false
	else:
		print("El objeto ", id, " ya estaba anotado")

func _process(_delta: float) -> void:
	var origin := ray_cast.global_position
	var target := ray_cast.get_collision_point() if ray_cast.is_colliding() else ray_cast.to_global(ray_cast.target_position)
	var direction := (target - origin).normalized()
	var start := origin + direction * RAY_START_OFFSET
	var length := start.distance_to(target)
	if length <= 0.001:
		ray_mesh.visible = false
		ray_tip.visible = false
		return
	ray_mesh.visible = true
	ray_tip.visible = true
	_beam_mesh.size = Vector3(RAY_THICKNESS, RAY_THICKNESS, length)
	ray_mesh.global_position = (start + target) * 0.5
	if absf(direction.dot(Vector3.UP)) > 0.99:
		ray_mesh.look_at(target, Vector3.FORWARD)
	else:
		ray_mesh.look_at(target, Vector3.UP)
	ray_tip.global_position = target
