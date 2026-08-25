extends Node
class_name Libro

var pagina_1 := preload("res://src/core/main_game/pagina_1.tres")
var pagina_2 := preload("res://src/core/main_game/pagina_2.tres")
var pagina_3 := preload("res://src/core/main_game/pagina_3.tres")
var paginas = [pagina_1,pagina_2,pagina_3]
var current_page : Page = pagina_1

func _init_pages():
	var b = null
	for a in paginas:
		a.previous_page = b
		if a == paginas[len(paginas)-1]:
			a.next_page = paginas[0]
		a.next_page = b
		b = a
func change_to_next_page():
	current_page = current_page.get_next_page()
func change_to_previous_page():
	current_page = current_page.get_previous_page()
