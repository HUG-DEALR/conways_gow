extends Control

@onready var speed_slider: VSlider = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Speed_Slider
@onready var zoom_slider: HSlider = $MarginContainer/VBoxContainer/Control/HBoxContainer/Zoom_Slider
@onready var play_generations: Button = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations
@onready var step_generation: Button = $MarginContainer/VBoxContainer/Step_Generation
@onready var hint_button: Button = $MarginContainer/VBoxContainer/Hint_Button
@onready var restart: Button = $MarginContainer/VBoxContainer/Restart
@onready var generation_counter: Label = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations/HBoxContainer/Generation_Counter

var speed_slider_tween: Tween
var zoom_slider_tween: Tween
var playing_generations: bool = false
var mouse_over_speed_options: bool = false
var mouse_over_zoom_options: bool = false

func _ready() -> void:
	speed_slider.visible = false
	zoom_slider.visible = false
	
	await get_tree().process_frame
	Global.world_scene.generation_itterated.connect(_on_generation_itterated)
	Global.generations_reset_to_0.connect(set_generation_number)

func set_gui_visible(set_to_visible: bool) -> void:
	self.visible = set_to_visible
	set_generation_number(Global.generation_number)
	
	if Global.world_scene.level_info_dict["hint_arrows"].is_empty() and Global.world_scene.level_info_dict["hint_text_boxes"].is_empty():
		hint_button.visible = false
	else:
		hint_button.visible = true

func toggle_expand_speed_slider(set_to_expand: bool) -> void:
	if speed_slider_tween:
		speed_slider_tween.kill()
	speed_slider_tween = get_tree().create_tween()
	speed_slider_tween.pause()
	speed_slider_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
		speed_slider_tween.tween_property(speed_slider, "custom_minimum_size", Vector2(20.0,100.0), 0.1)
		speed_slider.visible = true
		speed_slider_tween.play()
	else:
		speed_slider_tween.tween_property(speed_slider, "custom_minimum_size", Vector2(20.0,0.0), 0.1)
		speed_slider_tween.play()
		await speed_slider_tween.finished
		speed_slider.visible = false

func toggle_expand_zoom_slider(set_to_expand: bool) -> void:
	if zoom_slider_tween:
		zoom_slider_tween.kill()
	zoom_slider_tween = get_tree().create_tween()
	zoom_slider_tween.pause()
	zoom_slider_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
		zoom_slider_tween.tween_property(zoom_slider, "custom_minimum_size", Vector2(100.0,50.0), 0.1)
		zoom_slider.value = Global.game_camera.zoom.x
		zoom_slider.visible = true
		zoom_slider_tween.play()
	else:
		zoom_slider_tween.tween_property(zoom_slider, "custom_minimum_size", Vector2(0.0,50.0), 0.1)
		zoom_slider_tween.play()
		await zoom_slider_tween.finished
		zoom_slider.visible = false

func set_play_pause_display(set_to_play: bool) -> void:
	if set_to_play:
		play_generations.text = "◼"
		playing_generations = true
	else:
		play_generations.text = "❯❯"
		playing_generations = false

func set_generation_number(generation_num: int = Global.generation_number) -> void:
	if generation_num > 0:
		generation_counter.text = str(generation_num)
	else:
		generation_counter.text = ""

func _on_speed_slider_value_changed(value: float) -> void:
	Global.world_scene.generation_timer.wait_time = 1.0 / speed_slider.value

func _on_step_generation_pressed() -> void:
	Global.world_scene.iterate_generation()
	set_generation_number(Global.generation_number)
	Global.world_scene.set_play_pause(false)

func _on_generation_itterated() -> void:
	# connected by a function in _ready()
	set_generation_number(Global.generation_number)

func _on_play_generations_pressed() -> void:
	Global.world_scene.set_play_pause(!playing_generations, 1.0 / speed_slider.value)

func _on_auto_play_container_mouse_entered() -> void:
	mouse_over_speed_options = true
	toggle_expand_speed_slider(true)

func _on_left_GUI_container_mouse_exited() -> void:
	mouse_over_speed_options = false
	if not mouse_over_zoom_options:
		toggle_expand_speed_slider(false)
		toggle_expand_zoom_slider(false)
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func _on_zoom_options_container_mouse_entered() -> void:
	mouse_over_zoom_options = true
	toggle_expand_zoom_slider(true)

func _on_zoom_options_container_mouse_exited() -> void:
	mouse_over_zoom_options = false
	if not mouse_over_speed_options:
		toggle_expand_speed_slider(false)
		toggle_expand_zoom_slider(false)
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func _on_increase_zoom_pressed() -> void:
#	camera.set_zoom_clamped(1.1,true) # zoom slider signal function handles set_zoom
	zoom_slider.value = Global.game_camera.zoom.x * 1.1

func _on_decrease_zoom_pressed() -> void:
#	camera.set_zoom_clamped(1.0/1.1,true) # zoom slider signal function handles set_zoom
	zoom_slider.value = Global.game_camera.zoom.x / 1.1

func _on_zoom_slider_value_changed(value: float) -> void:
	Global.game_camera.set_zoom_clamped(value, false)

func _on_restart_pressed() -> void:
	Global.world_scene.full_populate_level(Global.world_scene.pre_loaded_level_info_dict, true)
	Global.reset_generation_to_0()
	Global.world_scene.set_play_pause(false)

func _on_hint_button_pressed() -> void:
	Global.world_scene.hint_requested()
