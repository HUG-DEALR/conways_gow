extends Node

# To do list
# Outcomes from bool eval
# Description and instructions integration
# Loading levels in levels menu utilises correct data structure
# Pressing reset in campaign play reverts to loaded info
# Gen number is saved with outcome

signal generations_reset_to_0
signal build_saved

var alive_colour: Color = Color(0.0,0.5,0.7,1.0)
var dead_colour: Color = Color(0.1,0.1,0.1,1.0)
var enemy_colour: Color = Color(0.7,0.2,0.0,1.0)
var ally_colour: Color = Color(0.0,0.7,0.5,1.0)
var static_alive_colour: Color = Color(0.0,0.2,0.3,1.0)
var static_dead_colour: Color = Color(0.0,0.0,0.0,1.0)

var world_scene: Node2D
var menu_camera: Camera2D
var game_camera: Camera2D

var generation_number: int = 0

func save_to_file(data_to_save: Dictionary, file_path: String) -> void:
	print("Saving to " + file_path)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return
	
	file.store_var(data_to_save)
	file.close()
	build_saved.emit()

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
		push_error("Failed to parse file: " + file_path + "\n" + str(typeof(data)) + "\n" + data)
		return {}

func prompt_user_for_directory(prompt: String = "Select Directory", current_directory: String = "") -> String:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.title = prompt
	
	if current_directory.is_empty():
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	else:
		dialog.current_dir = current_directory
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	var result: String = await dialog.dir_selected
	dialog.queue_free()
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
	
	if current_directory.is_empty():
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	else:
		dialog.current_dir = current_directory
	
	if default_file_name == "":
		default_file_name = "new_level.cgow"
	dialog.current_file = default_file_name
	
	# Optional filters like ["*.json", "*.txt"]
	for f in filters:
		dialog.add_filter(f)
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	var result: String = await dialog.file_selected
	
	dialog.queue_free()
	return result

func get_offset_to_be_fully_visible(control: Control) -> Vector2:
	var rect: Rect2 = control.get_global_rect()
	var viewport_size: Vector2 = control.get_viewport_rect().size
	var offset: Vector2 = Vector2.ZERO
	# Check left and top overflow (negative position)
	if rect.position.x < 0:
		offset.x = -rect.position.x
	elif rect.position.x + rect.size.x > viewport_size.x:
		offset.x = viewport_size.x - (rect.position.x + rect.size.x)
	if rect.position.y < 0:
		offset.y = -rect.position.y
	elif rect.position.y + rect.size.y > viewport_size.y:
		offset.y = viewport_size.y - (rect.position.y + rect.size.y)
	return offset

func reset_generation_to_0() -> void:
	generation_number = 0
	generations_reset_to_0.emit()
