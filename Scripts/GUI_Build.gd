extends Control

@onready var speed_slider: VSlider = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Speed_Slider
@onready var zoom_slider: HSlider = $Right_GUI_Root/VBoxContainer/Control/Zoom_Options_Container/Zoom_Slider
@onready var generation_timer: Timer = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations/GenerationTimer
@onready var play_generations: Button = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations
@onready var step_generation: Button = $Right_GUI_Root/VBoxContainer/Step_Generation
@onready var restart: Button = $Right_GUI_Root/VBoxContainer/Restart
@onready var save_as_button: Button = $"Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/Save As"
@onready var save_button: Button = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/Save
@onready var open_button: Button = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/Open
@onready var new_file_button: Button = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/New_File
@onready var file_name_label: Label = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/File_name

@onready var add_item_panel: PanelContainer = $Left_GUI_Root/VBoxContainer/Add_Item/Add_item_window/Add_item_panel
@onready var add_item_window: HBoxContainer = $Left_GUI_Root/VBoxContainer/Add_Item/Add_item_window
@onready var file_options_window: HBoxContainer = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window

var speed_slider_tween: Tween
var zoom_slider_tween: Tween
var new_item_window_tween: Tween
var file_options_window_tween: Tween
var playing_generations: bool = false
var mouse_over_speed_options: bool = false
var mouse_over_zoom_options: bool = false
var active_directory: String = ""

func _ready() -> void:
	speed_slider.visible = false
	zoom_slider.visible = false
	add_item_window.visible = false
	file_options_window.visible = false

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

func toggle_expand_new_item_window(set_to_expand: bool) -> void:
	if new_item_window_tween:
		new_item_window_tween.kill()
	new_item_window_tween = get_tree().create_tween()
	new_item_window_tween.pause()
	new_item_window_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(0.0,0.21), 0.0)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(1.0,0.21), 0.2)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2.ONE, 0.2)
		add_item_window.visible = true
		new_item_window_tween.play()
	else:
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(1.0,0.21), 0.2)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(0.0,0.21), 0.2)
		new_item_window_tween.play()
		await new_item_window_tween.finished
		add_item_window.visible = false

func toggle_expand_file_options_window(set_to_expand: bool) -> void:
	if file_options_window_tween:
		file_options_window_tween.kill()
	file_options_window_tween = get_tree().create_tween()
	file_options_window_tween.pause()
	file_options_window_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
		file_options_window_tween.tween_property(file_options_window, "scale", Vector2(0.0,1.0), 0.0)
		file_options_window_tween.tween_property(file_options_window, "scale", Vector2.ONE, 0.2)
		file_options_window.visible = true
		file_options_window_tween.play()
	else:
		file_options_window_tween.tween_property(file_options_window, "scale", Vector2(0.0,1.0), 0.2)
		file_options_window_tween.play()
		await file_options_window_tween.finished
		file_options_window.visible = false

func save_level(level_data: Dictionary) -> void:
	if active_directory:
		Global.save_to_file(level_data, active_directory)
	else:
		save_level_as(level_data)

func save_level_as(level_data: Dictionary) -> void:
	active_directory = await Global.prompt_user_for_file_path()
	var extension: String = active_directory.get_extension()
	if extension != "cgow":
		active_directory += ".cgow"
	Global.save_to_file(level_data, active_directory)

func open_level_from_local() -> void:
	var open_from_directory: String = await Global.prompt_user_for_file_path("Open", "", "", ["*.cgow"], false)
	var loaded_file = Global.load_from_file(open_from_directory)
	if loaded_file:
		active_directory = open_from_directory
		file_name_label.text = active_directory.get_file()
	else:
		print("Could not open file: " + open_from_directory + "\n" + loaded_file)
		return
	Global.world_scene.populate_cells(Vector2i(50,50), loaded_file, true)

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

func _on_add_item_pressed() -> void:
	toggle_expand_new_item_window(!add_item_window.visible)

func _on_add_item_window_mouse_exited() -> void:
	if add_item_window.scale == Vector2.ONE:
		toggle_expand_new_item_window(false)

func _on_file_options_pressed() -> void:
	toggle_expand_file_options_window(!file_options_window.visible)

func _on_file_options_window_mouse_exited() -> void:
	toggle_expand_file_options_window(false)

func _on_open_file_pressed() -> void:
	open_level_from_local()

func _on_save_pressed() -> void:
	save_level(Global.world_scene.live_cells_dict)
