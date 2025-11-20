extends Node

const alive_colour: Color = Color(0.0,0.5,0.7,1.0)
const dead_colour: Color = Color(0.1,0.1,0.1,1.0) # Dark Grey

var world_scene: Node2D
var menu_camera: Camera2D
var game_camera: Camera2D

func save_to_file(data_to_save: Dictionary, file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return
	
	file.store_var(data_to_save)
	file.close()

func load_from_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("File does not exist: " + file_path)
		return {}
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + file_path)
		return {}
	
	var data = file.get_var()
	file.close()
	
	if typeof(data) == TYPE_DICTIONARY:
		return data
	else:
		push_error("Failed to parse JSON from file: " + file_path + "\n" + data)
		return {}

func prompt_user_for_directory(prompt: String = "Select Directory", current_directory: String = "") -> String:
	# Create the dialog
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.title = prompt
	if current_directory:
		dialog.current_dir = current_directory
	dialog.current_dir = OS.get_user_data_dir()
	
	# Add dialog to the scene tree temporarily
	get_tree().root.add_child(dialog)
	
	# Show dialog
	dialog.popup_centered()
	
	# Wait for user to pick a directory
	var result: String = await dialog.dir_selected
	
	# Clean up
	dialog.queue_free()
	
	# Ensure trailing slash for convenience
	if not result.ends_with("/"):
		result += "/"
	
	return result

func prompt_user_for_file_path(
		prompt: String = "Save As",
		default_file_name: String = "",
		current_directory: String = "",
		filters: Array[String] = [],
		save_instead_of_open: bool = true
	) -> String:
	
	var dialog := FileDialog.new()
	if save_instead_of_open:
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	else:
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.title = prompt
	
	# Set starting path
	if current_directory:
		dialog.current_dir = current_directory
	if not default_file_name:
		default_file_name = "new_file.txt"
	dialog.current_file = default_file_name
	
	# Optional filters like ["*.json", "*.txt"]
	for f in filters:
		dialog.add_filter(f)
	
	# Add to scene while waiting
	get_tree().root.add_child(dialog)
	
	dialog.popup_centered()
	
	# Wait for file selection
	var result: String = await dialog.file_selected
	
	dialog.queue_free()
	return result
