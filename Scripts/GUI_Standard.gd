extends Control

@onready var speed_slider: VSlider = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Speed_Slider
@onready var zoom_slider: HSlider = $MarginContainer/VBoxContainer/Control/HBoxContainer/Zoom_Slider
@onready var generation_timer: Timer = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations/GenerationTimer
@onready var play_generations: Button = $MarginContainer/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations
@onready var step_generation: Button = $MarginContainer/VBoxContainer/Step_Generation
@onready var restart: Button = $MarginContainer/VBoxContainer/Restart
#@onready var decrease_zoom: Button = $MarginContainer/VBoxContainer/Control/HBoxContainer/Decrease_zoom
#@onready var increase_zoom: Button = $MarginContainer/VBoxContainer/Control/HBoxContainer/Increase_zoom

var speed_slider_tween: Tween
var zoom_slider_tween: Tween
var playing_generations: bool = false
var mouse_over_speed_options: bool = false
var mouse_over_zoom_options: bool = false

func _ready() -> void:
	speed_slider.visible = false
	zoom_slider.visible = false

func set_gui_visible(set_to_visible: bool) -> void:
	self.visible = set_to_visible

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
		zoom_slider.visible = true
		zoom_slider_tween.play()
	else:
		zoom_slider_tween.tween_property(zoom_slider, "custom_minimum_size", Vector2(0.0,50.0), 0.1)
		zoom_slider_tween.play()
		await zoom_slider_tween.finished
		zoom_slider.visible = false

func set_play_pause(set_to_play: bool) -> void:
	if set_to_play:
		play_generations.text = "◼"
		playing_generations = true
		generation_timer.start(1.0 / speed_slider.value)
	else:
		play_generations.text = "❯❯"
		playing_generations = false
		generation_timer.stop()

func _on_speed_slider_value_changed(value: float) -> void:
	generation_timer.wait_time = 1.0 / speed_slider.value

func _on_step_generation_pressed() -> void:
	Global.world_scene.iterate_generation()
	set_play_pause(false)

func _on_generation_timer_timeout() -> void:
	Global.world_scene.iterate_generation()

func _on_play_generations_pressed() -> void:
	set_play_pause(!playing_generations)

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
	Global.world_scene.clear_grid()
	set_play_pause(false)
