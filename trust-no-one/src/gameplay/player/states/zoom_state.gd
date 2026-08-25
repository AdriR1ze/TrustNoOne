extends BaseState


var _tween: Tween


func enter() -> void:
	_tween = player.create_tween()
	_tween.tween_property(player.camera, "fov", player.zoom_fov, player.zoom_duration)


func exit() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = player.create_tween()
	_tween.tween_property(player.camera, "fov", player.normal_fov, player.zoom_duration)
