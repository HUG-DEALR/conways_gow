extends Control

@onready var background_reset_timer: Timer = $BackgroundResetTimer

const menu_background_level: Dictionary = {
	105: ["alive", 0], 155: ["alive", 0], 205: ["alive", 0], 204: ["alive", 0], 153: ["alive", 0],
	144: ["alive", 0], 194: ["alive", 0], 244: ["alive", 0], 245: ["alive", 0], 196: ["alive", 0],
	139: ["alive", 0], 189: ["alive", 0], 239: ["alive", 0], 240: ["alive", 0], 191: ["alive", 0],
	395: ["alive", 0], 444: ["alive", 0], 494: ["alive", 0], 495: ["alive", 0], 496: ["alive", 0],
	537: ["alive", 0], 587: ["alive", 0], 637: ["alive", 0], 638: ["alive", 0], 589: ["alive", 0],
	2395: ["alive", 0], 2295: ["alive", 0], 2345: ["alive", 0], 2296: ["alive", 0], 2347: ["alive", 0],
	2191: ["alive", 0], 2141: ["alive", 0], 2091: ["alive", 0], 2092: ["alive", 0], 2143: ["alive", 0],
	1845: ["alive", 0], 1895: ["alive", 0], 1946: ["alive", 0], 1846: ["alive", 0], 1847: ["alive", 0],
	2385: ["alive", 0], 2335: ["alive", 0], 2336: ["alive", 0], 2337: ["alive", 0], 2436: ["alive", 0],
	2202: ["alive", 0], 2203: ["alive", 0], 2204: ["alive", 0], 2254: ["alive", 0], 2303: ["alive", 0],
	2309: ["alive", 0], 2259: ["alive", 0], 2209: ["alive", 0], 2208: ["alive", 0], 2257: ["alive", 0],
	2054: ["alive", 0], 2005: ["alive", 0], 1955: ["alive", 0], 1954: ["alive", 0], 1953: ["alive", 0],
	405: ["alive", 0], 455: ["alive", 0], 505: ["alive", 0], 504: ["alive", 0], 453: ["alive", 0],
	160: ["alive", 0], 211: ["alive", 0], 212: ["alive", 0], 162: ["alive", 0], 112: ["alive", 0] }

func _ready() -> void:
	await get_tree().process_frame
	Global.world_scene.populate_cells(Vector2i(50,50), menu_background_level, false)
	Global.world_scene.set_play_pause(true)
	Global.menu_camera.get_parent().position = Vector2(250,250)
	Global.menu_camera.zoom = Vector2(4,4)
	background_reset_timer.start()
	entry_animation()
	
	
	if true:
		return # Seperates the code for the bool evaluation
	
	var expression: Expression = Expression.new()
	var expr_string: String = "(bool_1 and bool_2) or (not bool_3 and bool_2) or false"
	var error = expression.parse(expr_string, ["bool_1", "bool_2", "bool_3"])
	if error != OK:
		push_error(expression.get_error_text())
		return
	var bool_1 = true
	var bool_2 = false
	var bool_3 = false
	var bool_values: Array = [bool_1, bool_2, bool_3]
	
	var result = expression.execute(bool_values)
	print(result)

func entry_animation() -> void:
	var tween: Tween = get_tree().root.create_tween()
	tween.pause()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	self.position.y = -1 * (get_viewport().size.y + self.size.y)
	tween.tween_property(self, "position", Vector2.ZERO, 0.75)
	tween.play()
	tween.tween_callback(func():
		tween.kill()
		)

func _on_levels_pressed() -> void:
	Global.world_scene.button_signal("levels")

func _on_settings_pressed() -> void:
	Global.world_scene.button_signal("settings")

func _on_build_pressed() -> void:
	Global.world_scene.button_signal("build")

func _on_exit_pressed() -> void:
	Global.world_scene.button_signal("exit")

func _on_background_reset_timer_timeout() -> void:
	var current_submenu: String = Global.world_scene.current_sub_menu
	if current_submenu == "main" or current_submenu == "levels" or current_submenu == "settings":
		Global.world_scene.populate_cells(Vector2i(50,50), menu_background_level, false)
		background_reset_timer.start(randi_range(6,12))
