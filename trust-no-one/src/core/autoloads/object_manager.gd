extends Node

var object_id : int = 0

func get_nuevo_id():
	object_id += 1
	print(object_id)
	return object_id
