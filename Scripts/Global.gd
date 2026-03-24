extends Node

# To do list
# Pressing reset in campaign play reverts to loaded info - maybe already done
# Gen number is saved with outcome
# Logic elements cleared by signal
# Settings

const read_only_level_default_source_directory: String = "res://level_defaults/"
const local_campaign_levels_directory: String = "user://campaign_levels/"

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
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + file_path)
		return {}
	
	var data = file.get_var()
	file.close()
	
	if typeof(data) == TYPE_DICTIONARY:
		print("Loading from " + file_path)
		return data
	else:
		push_error("Failed to parse file: " + file_path + "\n" + str(typeof(data)) + "\n" + data)
		return {}

func prompt_user_for_directory(prompt: String = "Select Directory", current_directory: String = "") -> String:
	var dialog: FileDialog = FileDialog.new()
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
	
	var dialog: FileDialog = FileDialog.new()
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

func sync_default_levels() -> void:
	DirAccess.make_dir_recursive_absolute(local_campaign_levels_directory)
	
	var level_default_files: PackedStringArray = DirAccess.get_files_at(read_only_level_default_source_directory)
	for file_name in level_default_files:
		if not file_name.ends_with(".cgow"):
			continue
		
		var target_path: String = local_campaign_levels_directory + file_name
		if FileAccess.file_exists(target_path):
			continue # Skip if user already has the file
		var source_path: String = read_only_level_default_source_directory + file_name
		
		var source_file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
		if source_file == null:
			push_error("Failed to open source file: " + source_path)
			continue
		
		var destination_file: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
		if destination_file == null:
			push_error("Failed to create target file: " + target_path)
			source_file.close()
			continue
		
		source_file.seek(0)
		destination_file.store_buffer(source_file.get_buffer(source_file.get_length()))
		
		source_file.close()
		destination_file.close()
		
		print("Copied default level: " + file_name + "\n" + "to " + target_path)

func repair_all_cgow_files(target_directory: String) -> void:
	if target_directory.begins_with("res://") and not OS.has_feature("editor"):
		push_error("DirAccess to project directory is not possible outside the project editor")
		return
	var directory_acess: DirAccess = DirAccess.open(target_directory)
	if directory_acess == null:
		push_error("Failed to open directory: " + target_directory)
		return
	
	directory_acess.list_dir_begin()
	var file_name: String = directory_acess.get_next()
	
	while file_name != "":
		if not directory_acess.current_is_dir():
			if file_name.get_extension() == "cgow":
				var full_path: String = target_directory.path_join(file_name)
				
				# Load file data
				var data: Dictionary = load_from_file(full_path)
				if data.is_empty():
					push_error("Skipping invalid or empty file: " + full_path)
					file_name = directory_acess.get_next()
					continue
				
				# Repair data
				print(str(world_scene.repair_current_file_missing_parameters(data)) + " missing parameters repaired in " + file_name)
				
				# Save repaired data back
				save_to_file(data, full_path)
		
		file_name = directory_acess.get_next()
	
	directory_acess.list_dir_end()

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
