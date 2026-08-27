extends StaticBody3D
class_name Objeto

## Nombre legible del objeto para mostrar en la UI de anotaciones.
## Si está vacío, se usará "Objeto #ID".
@export var nombre_objeto : String = ""

var id_unico : int

func _ready() -> void:
	id_unico = ObjectManager.get_nuevo_id()
	ObjectDb.registrar(self)

func _exit_tree() -> void:
	ObjectDb.eliminar(id_unico)
