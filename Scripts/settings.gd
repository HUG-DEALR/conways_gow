extends Control

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/TabContainer
# Video tab
@onready var x_resolution: LineEdit = $PanelContainer/MarginContainer/TabContainer/Video/Resolution/xResolution
@onready var y_resolution: LineEdit = $PanelContainer/MarginContainer/TabContainer/Video/Resolution/yResolution
@onready var window_mode_options: OptionButton = $PanelContainer/MarginContainer/TabContainer/Video/WindowMode/WindowMode_Options
# Misc tab
@onready var clear_campaign_levels_button: Button = $PanelContainer/MarginContainer/TabContainer/Misc/HBoxContainer/Clear_Levels
# Dev tab
@onready var dev_target_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Target_Input
@onready var dev_cmd_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_CMD_Input
@onready var dev_args_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Args_Input
@onready var dev_feedback: Label = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Feedback

const settings_config_file_path: String = "user://cgow_settings_config.txt"

var settings_config_dictionary: Dictionary = {
	"resolution": Vector2i(1600, 900),
	"window_mode": DisplayServer.WINDOW_MODE_WINDOWED,
	"window_borderless_flag": false,
}

func _ready() -> void:
	tab_container.current_tab = 0
	load_and_apply_settings_from_local()

func set_gui_visible(set_to_visible: bool) -> void:
	update_displayed_video_settings()
	visible = set_to_visible
	clear_campaign_levels_button.disabled = false

func save_settings_to_local() -> void:
	Global.save_to_file(settings_config_dictionary, settings_config_file_path)

func load_and_apply_settings_from_local() -> void:
	var loaded_data: Dictionary = {}
	if FileAccess.file_exists(settings_config_file_path):
		loaded_data = Global.load_from_file(settings_config_file_path) # in-built safety checks
	else:
		print("No settings config file found")
	
	if loaded_data.is_empty(): # Fallback to defaults if file is empty/invalid
		loaded_data = settings_config_dictionary.duplicate()
		print(settings_config_file_path + " is invalid, reverting to default settings")
	
	var resolution: Vector2i = loaded_data.get("resolution", settings_config_dictionary["resolution"])
	var window_mode: int = loaded_data.get("window_mode", settings_config_dictionary["window_mode"])
	var is_borderless: bool = loaded_data.get("window_borderless_flag", settings_config_dictionary["window_borderless_flag"])
	
	resolution.x = max(resolution.x, 960)
	resolution.y = max(resolution.y, 540)
	DisplayServer.window_set_size(resolution)
	
	DisplayServer.window_set_mode(window_mode)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, is_borderless)
	
	update_displayed_video_settings()
	save_settings_to_local()

func show_confirm_clear_campaign_dialog():
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to rest all campaign progress?" + "\n" + "This action cannot be undone"
	
	dialog.title = "Confirm Campaign Progress Deletion"
	dialog.get_ok_button().text = "Confirm"
	dialog.get_cancel_button().text = "Cancel"
	
	dialog.confirmed.connect(func():
		reset_campaign_levels()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
		clear_campaign_levels_button.disabled = false
	)
	
	add_child(dialog)
	dialog.popup_centered()

func show_confirm_clear_settings_config_dialog():
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = ("Are you sure you want to delete your settings configuration?" +
	"\n" + "This will reset your settings to default after you restart the game" +
	"\n" + "This action cannot be undone"
	)
	
	dialog.title = "Confirm Delete Settings Config"
	dialog.get_ok_button().text = "Confirm"
	dialog.get_cancel_button().text = "Cancel"
	
	dialog.confirmed.connect(func():
		
		if FileAccess.file_exists(settings_config_file_path):
			var error_return: Error = DirAccess.remove_absolute(settings_config_file_path)
		
			if error_return == OK:
				print("Settings config file deleted")
			else:
				push_error("Failed to delete settings config file: " + str(error_return))
		else:
			print("Settings config file does not exist")
		
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func reset_campaign_levels() -> void:
	var directory_access: DirAccess = DirAccess.open(Global.local_campaign_levels_directory)
	if directory_access == null:
		push_error("Failed to open directory: " + Global.local_campaign_levels_directory)
		return
	
	directory_access.list_dir_begin()
	var file_name: String = directory_access.get_next()
	
	while file_name != "":
		if not directory_access.current_is_dir():
			if file_name.get_extension() == "cgow":
				var full_path: String = Global.local_campaign_levels_directory.path_join(file_name)
				var error = DirAccess.remove_absolute(full_path)
				if error != OK:
					push_error("Failed to delete file: " + full_path)
				else:
					print("Deleted: ", full_path)
		file_name = directory_access.get_next()
	
	directory_access.list_dir_end()
	Global.sync_default_levels()
	Global.repair_all_cgow_files(Global.local_campaign_levels_directory)
	print("Campaign levels reset")
	clear_campaign_levels_button.disabled = true
	Global.world_scene.outcome_overlay.print_outcome("Campaign Reset", true)

func parse_arguments(argument_string: String) -> Array:
	if argument_string.is_empty():
		return []
	var result: Array = []
	
	for raw_arg in argument_string.split(","):
		var arg = raw_arg.strip_edges()
		
		# Try to infer type
		if arg.is_valid_int():
			result.append(int(arg))
		elif arg.is_valid_float():
			result.append(float(arg))
		else:
			# Treat as string (remove optional quotes)
			if (arg.begins_with('"') and arg.ends_with('"')) or (arg.begins_with("'") and arg.ends_with("'")):
				arg = arg.substr(1, arg.length() - 2)
			result.append(arg)
	
	return result

func force_integer_resolution_in_text_field(field: LineEdit, is_x: bool) -> void:
	var text: String = field.text
	
	var filtered: String = ""
	for c in text:
		if c.is_valid_int(): # checks single character
			filtered += c
	
	# If empty after filtering, use current resolution
	if filtered.is_empty():
		var current_size: Vector2i = DisplayServer.window_get_size()
		filtered = str(current_size.x if is_x else current_size.y)
	
	field.text = filtered

func update_displayed_video_settings() -> void:
	var window_size: Vector2i = DisplayServer.window_get_size()
	x_resolution.text = str(window_size.x)
	y_resolution.text = str(window_size.y)
	
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED:
			if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS): # = is borderless?
				window_mode_options.select(1) # Borderless
			else:
				window_mode_options.select(0) # Windowed
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			window_mode_options.select(2) # Maximised
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			window_mode_options.select(3) # Fullscreen
		_: # Catch all
			window_mode_options.select(0)

func _on_apply_video_settings_pressed() -> void:
	force_integer_resolution_in_text_field(x_resolution, true)
	force_integer_resolution_in_text_field(y_resolution, false)
	var resolution_width: int = max(int(x_resolution.text),960)
	var resolution_height: int = max(int(y_resolution.text),540)
	
	DisplayServer.window_set_size(Vector2i(resolution_width, resolution_height))
	settings_config_dictionary["resolution"] = Vector2i(resolution_width, resolution_height)
	
	match window_mode_options.selected:
		0: # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: # Borderless
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			settings_config_dictionary["window_borderless_flag"] = true
		2: # Maximized
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		3: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	settings_config_dictionary["window_mode"] = DisplayServer.window_get_mode()
	
	# Ensure borderless is OFF for other modes
	if window_mode_options.selected != 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		settings_config_dictionary["window_borderless_flag"] = false
	
	update_displayed_video_settings()
	save_settings_to_local()

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")

func _on_clear_levels_pressed() -> void:
	clear_campaign_levels_button.disabled = true
	show_confirm_clear_campaign_dialog()

func _on_execute_dev_button_pressed() -> void:
	dev_feedback.text = ""
	var method: String = dev_cmd_input.text
	var arguments: String = dev_args_input.text
	var target_object: Object = Global
	match dev_target_input.text:
		"":
			target_object = Global
		"Global":
			target_object = Global
		"Global.world_scene":
			target_object = Global.world_scene
		_:
			dev_feedback.text += "Unrecognised target" + "\n"
			return
	if not target_object.has_method(method):
		dev_feedback.text += "Method not found in target" + "\n"
		return
	
	dev_feedback.text += str(target_object.callv(method, parse_arguments(arguments))) + "\n"

func _on_y_video_resolution_focus_exited() -> void:
	force_integer_resolution_in_text_field(y_resolution, false)

func _on_x_video_resolution_focus_exited() -> void:
	force_integer_resolution_in_text_field(x_resolution, true)

func _on_clear_config_pressed() -> void:
	show_confirm_clear_settings_config_dialog()
