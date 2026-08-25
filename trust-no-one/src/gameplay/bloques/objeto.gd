extends StaticBody3D
class_name Objeto

var id_unico : int

func _ready() -> void:
	id_unico = ObjectManager.get_nuevo_id()
	ObjectDb.registrar(self)

func _exit_tree() -> void:
	ObjectDb.eliminar(id_unico)
