@tool
extends EditorScript

func _run() -> void:
	print_dict()

func print_dict() -> void:
	var open_from_directory: String = await Global.prompt_user_for_file_path("Open", "", "", ["*.cgow"], false)
	print(Global.load_from_file(open_from_directory))
