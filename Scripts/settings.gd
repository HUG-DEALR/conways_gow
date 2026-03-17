extends Control

@onready var clear_campaign_levels_button: Button = $PanelContainer/MarginContainer/TabContainer/Misc/HBoxContainer/Clear_Levels

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
	print("Campaign levels reset")
	clear_campaign_levels_button.disabled = true

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")

func _on_clear_levels_pressed() -> void:
	clear_campaign_levels_button.disabled = true
	show_confirm_clear_campaign_dialog()
