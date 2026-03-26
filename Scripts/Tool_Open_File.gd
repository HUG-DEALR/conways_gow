extends Control

@onready var text_edit: TextEdit = $PanelContainer/VBoxContainer/TextEdit

var saved_dict: Dictionary = {}

func load_dict() -> void:
	var open_from_directory: String = await Global.prompt_user_for_file_path("Open", "", "", ["*.cgow"], false)
	saved_dict = Global.load_from_file(open_from_directory)
	text_edit.text = str(saved_dict)

func save_dict() -> void:
	var save_to_directory: String = await Global.prompt_user_for_file_path()
	Global.save_to_file(saved_dict, save_to_directory)

func reset_rating() -> void:
	saved_dict["completion_rating"] = [false, false, false]
	saved_dict["current_rating"] = [false, false, false]
	saved_dict["outcome_generations"] = [-1, -1, [-1, -1, -1], [-1, -1, -1]]
	text_edit.text = str(saved_dict)
