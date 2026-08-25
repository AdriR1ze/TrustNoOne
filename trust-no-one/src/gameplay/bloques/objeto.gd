extends Node
class_name Objeto

var id_unico : int

func _ready() -> void:
	id_unico = ObjectManager.get_nuevo_id()
