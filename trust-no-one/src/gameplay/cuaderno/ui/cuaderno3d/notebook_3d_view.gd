class_name Notebook3DView
extends SubViewportContainer
## Componente que renderiza el cuaderno 3D dentro de un SubViewport.
## Se integra en la UI del libro de investigación para dar fondo 3D
## y expone métodos para reproducir la animación de pasar hojas.

const NOTEBOOK_MODEL_PATH = "res://assets/Cuaderno.glb"

signal page_turn_finished
signal notebook_rect_ready(rect: Rect2)

## Rectángulo normalizado (0-1) donde el cuaderno se proyecta en pantalla
var notebook_screen_rect := Rect2()

var _viewport: SubViewport
var _camera: Camera3D
var _key_light: DirectionalLight3D
var _rim_light: DirectionalLight3D
var _notebook_instance: Node3D

## Los nodos de las páginas (meshes) que vamos a rotar directamente
var _page_nodes: Array[Node3D] = []

## Tracking de sección actual (0 = Fotos, 1 = Objetos, 2 = Notas)
var _current_page_index: int = 0


func _ready() -> void:
	# Configurar este contenedor para ser transparente al input de mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true

	_setup_viewport()
	_setup_camera()
	_setup_lighting()
	_load_notebook_model()


func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = SubViewport.MSAA_4X
	add_child(_viewport)


func _setup_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "NotebookCamera"
	# Vista frontal mirando hacia abajo sobre el cuaderno rotado 90° (landscape)
	# El cuaderno está en el plano XZ (suelo), así que la cámara mira desde arriba (+Y)
	_camera.position = Vector3(0.0, 0.15, 0.0)
	_camera.rotation_degrees = Vector3(-90, 0, 0)
	_camera.fov = 45.0
	_camera.near = 0.01
	_camera.far = 10.0
	_viewport.add_child(_camera)


func _setup_lighting() -> void:
	# Warm key light (detective desk lamp feel)
	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	_key_light.light_energy = 3.2
	_key_light.light_color = Color(1.0, 0.94, 0.82)
	_key_light.rotation_degrees = Vector3(-45, 20, 35)
	_key_light.shadow_enabled = true
	_viewport.add_child(_key_light)

	# Cool rim light for silhouette definition
	_rim_light = DirectionalLight3D.new()
	_rim_light.name = "RimLight"
	_rim_light.light_energy = 1.5
	_rim_light.light_color = Color(0.55, 0.72, 0.95)
	_rim_light.rotation_degrees = Vector3(50, -30, -145)
	_viewport.add_child(_rim_light)

	# Ambient environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.13, 0.12)
	env.ambient_light_energy = 0.8

	var world := World3D.new()
	world.environment = env
	_viewport.world_3d = world


func _load_notebook_model() -> void:
	var scene := load(NOTEBOOK_MODEL_PATH) as PackedScene
	if not scene:
		push_error("Notebook3DView: No se pudo cargar el modelo del cuaderno: %s" % NOTEBOOK_MODEL_PATH)
		return

	_notebook_instance = scene.instantiate()
	_notebook_instance.name = "NotebookModel"

	# Rotar 90 grados en Y para orientación landscape (anillas a la izquierda)
	_notebook_instance.rotation_degrees = Vector3(0, -90, 0)

	_viewport.add_child(_notebook_instance)

	# --- Auto-centrado basado en el AABB real del modelo ---
	# Esperar un frame para que las transforms globales se actualicen
	await get_tree().process_frame

	var aabb := _get_combined_aabb(_notebook_instance)
	var center := aabb.get_center()

	# Mover el modelo para que su centro geométrico quede en el origen (0,0,0)
	_notebook_instance.position -= center
	# Mantener Y en 0 (el modelo debe quedar en el suelo, la cámara mira desde arriba)
	_notebook_instance.position.y = 0.0

	# Posicionar la cámara para encuadrar el modelo automáticamente.
	# La cámara mira hacia -Y (rotación -90° en X), así que la altura determina el zoom.
	var model_extent := maxf(aabb.size.x, aabb.size.z)
	var half_fov_rad := deg_to_rad(_camera.fov * 0.5)
	# Distancia necesaria para que el modelo entre en el frustum, con un margen ajustado
	var required_height := (model_extent * 0.5 * 0.92) / tan(half_fov_rad)
	_camera.position = Vector3(0.0, required_height, 0.0)

	print("Notebook3DView: AABB center=%s  size=%s  camera_height=%.4f" % [center, aabb.size, required_height])

	# --- Calcular el rectángulo de pantalla normalizado del cuaderno ---
	# La cámara mira hacia -Y. En este setup:
	#   Mundo X → Pantalla horizontal
	#   Mundo Z → Pantalla vertical (invertido)
	# El frustum visible en el plano Y=0:
	var half_visible_v := required_height * tan(half_fov_rad)
	var aspect := float(_viewport.size.x) / float(_viewport.size.y)
	var half_visible_h := half_visible_v * aspect

	# El AABB ya fue centrado en el origen, recalcular después del desplazamiento
	var recalc_aabb := _get_combined_aabb(_notebook_instance)
	var nb_left := recalc_aabb.position.x
	var nb_right := recalc_aabb.position.x + recalc_aabb.size.x
	var nb_front := recalc_aabb.position.z  # Z negativo = arriba en pantalla
	var nb_back := recalc_aabb.position.z + recalc_aabb.size.z

	# Convertir coordenadas 3D a normalizadas (0-1) en pantalla
	var screen_left := 0.5 + (nb_left / (2.0 * half_visible_h))
	var screen_right := 0.5 + (nb_right / (2.0 * half_visible_h))
	var screen_top := 0.5 - (nb_back / (2.0 * half_visible_v))   # Z+ → arriba en pantalla
	var screen_bottom := 0.5 - (nb_front / (2.0 * half_visible_v))

	notebook_screen_rect = Rect2(
		screen_left, screen_top,
		screen_right - screen_left, screen_bottom - screen_top
	)
	print("Notebook3DView: screen_rect = %s" % notebook_screen_rect)
	notebook_rect_ready.emit(notebook_screen_rect)

	# Buscar los nodos de las páginas directamente por nombre
	# El GLB tiene: Notebook_Page_01 y Notebook_Page_02
	var p1 = _find_node_by_name(_notebook_instance, "Notebook_Page_01")
	var p2 = _find_node_by_name(_notebook_instance, "Notebook_Page_02")

	if p1:
		_page_nodes.append(p1)
		print("Notebook3DView: Encontrada Notebook_Page_01")
	else:
		push_warning("Notebook3DView: No se encontró Notebook_Page_01")

	if p2:
		_page_nodes.append(p2)
		print("Notebook3DView: Encontrada Notebook_Page_02")
	else:
		push_warning("Notebook3DView: No se encontró Notebook_Page_02")


## Calcula el AABB combinado de todas las MeshInstance3D hijas de un nodo.
func _get_combined_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			var child_aabb := mesh_inst.get_aabb()
			# Transformar el AABB local al espacio del root
			var child_transform := mesh_inst.global_transform
			var corners: Array[Vector3] = []
			for i in range(8):
				corners.append(child_transform * child_aabb.get_endpoint(i))
			for corner in corners:
				if first:
					combined = AABB(corner, Vector3.ZERO)
					first = false
				else:
					combined = combined.expand(corner)
		if child is Node3D:
			var sub_aabb := _get_combined_aabb(child as Node3D)
			if sub_aabb.size != Vector3.ZERO:
				if first:
					combined = sub_aabb
					first = false
				else:
					combined = combined.merge(sub_aabb)
	return combined


func _find_node_by_name(root: Node, target_name: String) -> Node3D:
	if root.name == target_name and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	return null


func _print_tree(node: Node, indent: String) -> void:
	print(indent + str(node.name) + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_tree(child, indent + "  ")


func _on_page_turn_finished() -> void:
	page_turn_finished.emit()


## Reproduce la animación de pasar hoja hacia adelante.
## Rotamos el nodo completo de la página alrededor del eje de las anillas (eje Z local del cuaderno).
func play_page_turn(page_index: int) -> void:
	if page_index < 0 or page_index >= _page_nodes.size():
		page_turn_finished.emit()
		return

	var page_node = _page_nodes[page_index]

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# La hoja necesita girar 360 grados sobre el eje de las anillas.
	# El eje correcto depende de cómo se orientó la mesh en Blender.
	# Probamos con X (eje local de la hoja en dirección de las anillas).
	var start_rot = page_node.rotation_degrees
	tween.tween_method(
		func(angle: float):
			page_node.rotation_degrees.x = start_rot.x + angle,
		0.0, 360.0, 0.8
	)

	tween.finished.connect(_on_page_turn_finished)


## Reproduce la animación de pasar hoja en reversa (devolver hoja).
func play_page_turn_reverse(page_index: int) -> void:
	if page_index < 0 or page_index >= _page_nodes.size():
		page_turn_finished.emit()
		return

	var page_node = _page_nodes[page_index]

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var start_rot = page_node.rotation_degrees
	tween.tween_method(
		func(angle: float):
			page_node.rotation_degrees.x = start_rot.x + angle,
		0.0, -360.0, 0.8
	)

	tween.finished.connect(_on_page_turn_finished)


## Resetea la animación al frame 0 (cuaderno con páginas sin girar).
func reset() -> void:
	_current_page_index = 0
	for page in _page_nodes:
		page.rotation_degrees = Vector3.ZERO
