extends Control

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/TabContainer
@onready var clear_campaign_levels_button: Button = $PanelContainer/MarginContainer/TabContainer/Misc/HBoxContainer/Clear_Levels
@onready var dev_target_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Target_Input
@onready var dev_cmd_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_CMD_Input
@onready var dev_args_input: CodeEdit = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Args_Input
@onready var dev_feedback: Label = $PanelContainer/MarginContainer/TabContainer/Dev/DEV_Feedback

func _ready() -> void:
	tab_container.current_tab = 0

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible
	clear_campaign_levels_button.disabled = false

func show_confirm_clear_campaign_dialog():
	var dialog = ConfirmationDialog.new()
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
