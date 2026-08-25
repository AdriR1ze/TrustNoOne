extends Resource
class_name Page

@export var titulo : String = ""
@export var mostrar_anotaciones : bool = false

var previous_page : Page
var next_page : Page

func get_next_page():
	return next_page
func get_previous_page():
	return previous_page
