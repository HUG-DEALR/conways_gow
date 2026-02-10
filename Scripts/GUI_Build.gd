extends Control

@onready var speed_slider: VSlider = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Speed_Slider
@onready var zoom_slider: HSlider = $Right_GUI_Root/VBoxContainer/Control/Zoom_Options_Container/Zoom_Slider
@onready var generation_timer: Timer = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations/GenerationTimer
@onready var play_generations: Button = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations
@onready var step_generation: Button = $Right_GUI_Root/VBoxContainer/Step_Generation
@onready var generation_counter: Label = $Right_GUI_Root/VBoxContainer/Auto_Play_Container/VBoxContainer/Play_Generations/HBoxContainer/Generation_Counter
@onready var restart: Button = $Right_GUI_Root/VBoxContainer/Restart
@onready var file_name_label: Label = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window/File_name
@onready var reset_options_container: HBoxContainer = $Right_GUI_Root/VBoxContainer/Restart/Reset_Options_Container
@onready var level_settings_root: PanelContainer = $Level_Settings_Root
@onready var logic_settings_root: PanelContainer = $Logic_Settings_Root
@onready var logic_terms_vbox: VBoxContainer = $Logic_Settings_Root/VBoxContainer/ScrollContainer/VBoxContainer
@onready var grid_width_line_edit: LineEdit = $Level_Settings_Root/VBoxContainer/Resize_Grid_HBoxContainer/Grid_Width_Line_Edit
@onready var grid_height_line_edit: LineEdit = $Level_Settings_Root/VBoxContainer/Resize_Grid_HBoxContainer/Grid_Height_Line_Edit
@onready var add_item_panel: PanelContainer = $Left_GUI_Root/VBoxContainer/Add_Item/Add_item_window/Add_item_panel
@onready var add_item_window: HBoxContainer = $Left_GUI_Root/VBoxContainer/Add_Item/Add_item_window
@onready var file_options_window: HBoxContainer = $Left_GUI_Root/VBoxContainer/File_Options/File_Options_Window
@onready var reset_to_saved_button: Button = $Right_GUI_Root/VBoxContainer/Restart/Reset_Options_Container/Reset_To_Saved
@onready var generic_zone = preload("res://Scenes/Props/zone_polygon.tscn")

const logic_term_path: String = "res://Scenes/Menus/logic_term.tscn"

var speed_slider_tween: Tween
var zoom_slider_tween: Tween
var reset_options_tween: Tween
var new_item_window_tween: Tween
var file_options_window_tween: Tween
var level_settings_tween: Tween
var logic_settings_tween: Tween
var playing_generations: bool = false
var mouse_over_speed_options: bool = false
var mouse_over_zoom_options: bool = false
var mouse_over_reset_options: bool = false
#var active_directory: String = ""
var logic_terms: Dictionary = {} # Format is node: [String ( Outcome ) , String( eval_text )]
var logic_structure: Dictionary = {} # format is arbitrary_index: [outcome_index, [object_index, [selection_indexes], [child_A_info], [child_B_info]]]

func _ready() -> void:
	speed_slider.visible = false
	zoom_slider.visible = false
	reset_options_container.visible = false
	reset_options_container.scale.x = 0.0
	add_item_window.visible = false
	file_options_window.visible = false
	reset_to_saved_button.disabled = true
	level_settings_root.visible = false
	logic_settings_root.visible = false
	
	_on_new_bool_pressed()

func set_gui_visible(set_to_visible: bool) -> void:
	self.visible = set_to_visible
	set_generation_number(Global.generation_number)

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

func toggle_expand_reset_options(set_to_expand: bool) -> void:
	if reset_options_tween:
		reset_options_tween.kill()
	reset_options_tween = get_tree().create_tween()
	reset_options_tween.pause()
	reset_options_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
	#	reset_options_tween.tween_property(reset_options_container, "scale", Vector2(0.0,1.0), 0.0)
		reset_options_tween.tween_property(reset_options_container, "scale", Vector2.ONE, 0.15)
		reset_options_container.visible = true
		reset_options_tween.play()
	else:
		reset_options_tween.tween_property(reset_options_container, "scale", Vector2(0.0,1.0), 0.15)
		reset_options_tween.play()
		await reset_options_tween.finished
		reset_options_container.visible = false

func set_play_pause(set_to_play: bool) -> void:
	if set_to_play:
		play_generations.text = "◼"
		playing_generations = true
		generation_timer.start(1.0 / speed_slider.value)
	else:
		play_generations.text = "❯❯"
		playing_generations = false
		generation_timer.stop()

func set_generation_number(generation_num: int) -> void:
	if generation_num > 0:
		generation_counter.text = str(generation_num)
	else:
		generation_counter.text = ""

func toggle_expand_new_item_window(set_to_expand: bool) -> void:
	if new_item_window_tween:
		new_item_window_tween.kill()
	new_item_window_tween = get_tree().create_tween()
	new_item_window_tween.pause()
	new_item_window_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if set_to_expand:
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(0.0,0.21), 0.0)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(1.0,0.21), 0.1)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2.ONE, 0.1)
		add_item_window.visible = true
		new_item_window_tween.play()
	else:
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(1.0,0.21), 0.1)
		new_item_window_tween.tween_property(add_item_panel, "scale", Vector2(0.0,0.21), 0.1)
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

func toggle_expand_level_settings(set_to_expand: bool) -> void:
	if level_settings_tween:
		level_settings_tween.kill()
	level_settings_tween = get_tree().create_tween()
	level_settings_tween.pause()
	level_settings_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	level_settings_root.pivot_offset = level_settings_root.size/2.0
	if set_to_expand:
		update_level_settings_display()
		level_settings_tween.tween_property(level_settings_root, "scale", Vector2.ZERO, 0.0)
		level_settings_tween.tween_property(level_settings_root, "scale", Vector2.ONE, 0.2)
		level_settings_root.visible = true
		level_settings_tween.play()
	else:
		level_settings_tween.tween_property(level_settings_root, "scale", Vector2.ZERO, 0.2)
		level_settings_tween.play()
		await level_settings_tween.finished
		level_settings_root.visible = false

func toggle_expand_logic_settings(set_to_expand: bool) -> void:
	if logic_settings_tween:
		logic_settings_tween.kill()
	logic_settings_tween = get_tree().create_tween()
	logic_settings_tween.pause()
	logic_settings_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	logic_settings_root.pivot_offset = logic_settings_root.size/2.0
	if set_to_expand:
		update_level_settings_display()
		logic_settings_tween.tween_property(logic_settings_root, "scale", Vector2.ZERO, 0.0)
		logic_settings_tween.tween_property(logic_settings_root, "scale", Vector2.ONE, 0.2)
		logic_settings_root.visible = true
		logic_settings_tween.play()
	else:
		logic_settings_tween.tween_property(logic_settings_root, "scale", Vector2.ZERO, 0.2)
		logic_settings_tween.play()
		await logic_settings_tween.finished
		logic_settings_root.visible = false

func write_all_logic_term_info_to_world_dict() -> void:
	var arbitrary_index: int = 0
	for logic_term in logic_terms.keys():
		logic_terms[logic_term] = logic_term.get_bool_info()
		logic_structure[arbitrary_index] = logic_term.get_logic_term_structure_array()
		arbitrary_index += 1
	Global.world_scene.level_info_dict["logic_terms"] = logic_terms
	Global.world_scene.level_info_dict["logic_menu_structure"] = logic_structure

func update_level_settings_display() -> void:
	var grid_dimensions: Vector2i = Global.world_scene.level_info_dict["grid_dimensions"]
	grid_width_line_edit.text = str(grid_dimensions.x)
	grid_height_line_edit.text = str(grid_dimensions.y)

func create_and_set_logic_terms(logic_structures: Dictionary) -> void:
	for structure_array in logic_structures.values():
		var instance = load(logic_term_path).instantiate()
		logic_terms_vbox.add_child(instance)
		logic_terms_vbox.move_child(instance, -2)
		logic_terms[instance] = "" # Standin until the actual eval text is retrieved and implimented
		instance.set_logic_structure(structure_array)

func clear_logic_structures() -> void:
	for node in logic_terms.keys():
		node.entry_exit_animation(false, true)
	logic_terms.clear()
	logic_structure.clear()

#func save_level(level_data: Dictionary) -> void:
#	if Global.world_scene.active_directory:
#		Global.save_to_file(level_data, Global.world_scene.active_directory)
#		reset_to_saved_button.disabled = false
#	else:
#		save_level_as(level_data)

#func save_level_as(level_data: Dictionary) -> void:
#	Global.world_scene.active_directory = await Global.prompt_user_for_file_path()
#	if Global.world_scene.active_directory.get_extension() != "cgow":
#		Global.world_scene.active_directory += ".cgow"
#	Global.save_to_file(level_data, Global.world_scene.active_directory)
#	reset_to_saved_button.disabled = false

#func open_level_from_local(skip_directory_prompt: bool = false) -> void:
#	var open_from_directory: String = ""
#	if skip_directory_prompt and active_directory.get_extension() == "cgow":
#		open_from_directory = active_directory
#	else:
#		open_from_directory = await Global.prompt_user_for_file_path("Open", "", "", ["*.cgow"], false)
#	
#	var loaded_file = Global.load_from_file(open_from_directory)
#	if loaded_file:
#		active_directory = open_from_directory
#		file_name_label.text = active_directory.get_file()
#		reset_to_saved_button.disabled = false
#	else:
#		print("Could not open file: " + open_from_directory + "\n" + loaded_file)
#		return
#	Global.world_scene.populate_cells(loaded_file.get("grid_dimensions"), loaded_file.get("live_cells"), true)
#	Global.world_scene.populate_zones(loaded_file.get("can_build_zones"), loaded_file.get("no_build_zones"), loaded_file.get("trigger_zones"), true, false)
#	Global.world_scene.level_info_dict = loaded_file

### Signal Functions

func _on_speed_slider_value_changed(value: float) -> void:
	generation_timer.wait_time = 1.0 / speed_slider.value

func _on_step_generation_pressed() -> void:
	Global.world_scene.iterate_generation()
	set_generation_number(Global.generation_number)
	set_play_pause(false)

func _on_generation_timer_timeout() -> void:
	Global.world_scene.iterate_generation()
	set_generation_number(Global.generation_number)

func _on_play_generations_pressed() -> void:
	set_play_pause(!playing_generations)

func _on_auto_play_container_mouse_entered() -> void:
	mouse_over_speed_options = true
	toggle_expand_speed_slider(true)

func _on_left_GUI_container_mouse_exited() -> void:
	mouse_over_speed_options = false
	if not mouse_over_zoom_options and not mouse_over_reset_options:
		toggle_expand_speed_slider(false)
		toggle_expand_zoom_slider(false)
		toggle_expand_reset_options(false)
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func _on_zoom_options_container_mouse_entered() -> void:
	mouse_over_zoom_options = true
	toggle_expand_zoom_slider(true)

func _on_zoom_options_container_mouse_exited() -> void:
	mouse_over_zoom_options = false
	if not mouse_over_speed_options and not mouse_over_reset_options:
		toggle_expand_speed_slider(false)
		toggle_expand_zoom_slider(false)
		toggle_expand_reset_options(false)
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
	Global.world_scene.open_level_from_local()

func _on_save_pressed() -> void:
	Global.world_scene.save_level(Global.world_scene.level_info_dict)

func _on_save_as_pressed() -> void:
	Global.world_scene.save_level_as(Global.world_scene.level_info_dict)

func _on_new_file_pressed() -> void:
	Global.world_scene.clear_grid()
	Global.world_scene.clear_zones()
	Global.generation_number = 0
	set_generation_number(0)
	set_play_pause(false)
	file_name_label.text = "new_level.cgow"
	Global.world_scene.active_directory = ""
	reset_to_saved_button.disabled = true

func _on_reset_build_to_clear_mouse_entered() -> void:
	toggle_expand_reset_options(true)
	mouse_over_reset_options = true

func _on_reset_options_container_mouse_exited() -> void:
	mouse_over_reset_options = false
	if not mouse_over_speed_options and not mouse_over_zoom_options:
		toggle_expand_speed_slider(false)
		toggle_expand_zoom_slider(false)
		toggle_expand_reset_options(false)
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()

func _on_reset_to_clear_pressed() -> void:
	Global.world_scene.clear_grid()
	Global.world_scene.clear_zones()
	Global.generation_number = 0
	set_generation_number(0)
	set_play_pause(false)

func _on_reset_to_saved_pressed() -> void:
	Global.world_scene.open_level_from_local(true)
	Global.generation_number = 0
	set_generation_number(0)
	set_play_pause(false)

func _on_new_zone_button_pressed() -> void:
	var new_zone = generic_zone.instantiate()
	Global.world_scene.add_child(new_zone)
	new_zone.visible = true
	new_zone.global_position = Global.game_camera.global_position

func _on_level_settings_pressed() -> void:
	toggle_expand_level_settings(!level_settings_root.visible)
	if logic_settings_root.visible:
		toggle_expand_logic_settings(false)

func _on_cancel_level_settings_pressed() -> void:
	toggle_expand_level_settings(false)

func _on_apply_level_settings_pressed() -> void:
	if grid_width_line_edit.text.is_valid_int() and grid_height_line_edit.text.is_valid_int():
		if grid_width_line_edit.text.to_int() > 0 and grid_height_line_edit.text.to_int() > 0:
			var current_grid_dimensions: Vector2i = Global.world_scene.level_info_dict["grid_dimensions"]
			var target_dimensions: Vector2i = Vector2i(grid_width_line_edit.text.to_int(), grid_height_line_edit.text.to_int())
			if target_dimensions != current_grid_dimensions:
				Global.world_scene.resize_grid(target_dimensions, {})
	toggle_expand_level_settings(false)

func _on_logic_option_pressed() -> void:
	toggle_expand_logic_settings(!logic_settings_root.visible)
	if level_settings_root.visible:
		toggle_expand_level_settings(false)

func _on_cancel_logic_settings_pressed() -> void:
	toggle_expand_logic_settings(false)

func _on_apply_logic_pressed() -> void:
	write_all_logic_term_info_to_world_dict()
	toggle_expand_logic_settings(false)

func _on_new_bool_pressed() -> void:
	var instance = load(logic_term_path).instantiate()
	logic_terms_vbox.add_child(instance)
	logic_terms_vbox.move_child(instance, -2)
	logic_terms[instance] = "" # Standin until the actual eval text is retrieved and implimented

func _on_exit_pressed() -> void:
	Global.world_scene.button_signal("main")
