extends Camera2D

@onready var world_parent: Node2D = self.get_parent()

const move_speed: int = 500

var max_zoom: float = 10.0
var min_zoom: float = 0.1
var drift_tween: Tween

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var mouse_pos_before_zoom: Vector2 = get_global_mouse_position()
			set_zoom_clamped(1.1,true)
			move_after_zoom(mouse_pos_before_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var mouse_pos_before_zoom: Vector2 = get_global_mouse_position()
			set_zoom_clamped(1.0/1.1,true)
			move_after_zoom(mouse_pos_before_zoom)

func _process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	global_position += input_direction * move_speed * delta / zoom.x

func set_zoom_clamped(zoom_level: float, relative_multiplicative: bool = true) -> void:
	if relative_multiplicative:
		zoom = clamp(zoom*zoom_level, min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)
	else:
		zoom = clamp(zoom_level * Vector2.ONE, min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)

func move_after_zoom(prior_mouse_position: Vector2) -> void:
	global_position += (prior_mouse_position - get_global_mouse_position())
	drift_back_to_grid()

func drift_back_to_grid() -> void:
	var grid_center_position: Vector2 = (10.0) * Global.world_scene.level_info_dict["grid_dimensions"]/2.0
	var displacement: Vector2 = position - grid_center_position
	if displacement.length() > 1.25 * grid_center_position.length():
		var end_position: Vector2 = displacement.normalized() * 1.0 * grid_center_position.length() + grid_center_position
		if drift_tween:
			drift_tween.kill()
		drift_tween = create_tween()
		drift_tween.pause()
		drift_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		drift_tween.tween_property(self, "position", end_position, 1.5)
		drift_tween.play()
		await drift_tween.finished
		if drift_tween:
			drift_tween.kill()
