extends Node2D

signal generation_itterated
signal clear_zones_called

@onready var grid: MultiMeshInstance2D = $Grid
@onready var grid_multimesh: MultiMesh = grid.multimesh
@onready var game_camera: Camera2D = $Game_Camera
@onready var menu_camera: Camera2D = $Rot_Parent/Menu_Camera
@onready var rot_parent_menu_camera: Node2D = $Rot_Parent
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var outcome_overlay: Control = $CanvasLayer/outcome_overlay
@onready var menus: Dictionary = {
	"GUI": $CanvasLayer/GUI_Standard,
	"Main_menu": $CanvasLayer/MainMenu,
	"Levels_menu": $CanvasLayer/Levels_Menu,
	"Settings_menu": $CanvasLayer/Settings,
	"Build_menu": $CanvasLayer/GUI_Standard2,
}

const cell_size: float = 10.0
const cell_margin: float = 0.0

var current_cell_count: int
var last_click_location: Vector2 = Vector2.ZERO
var current_menu: Control
var current_sub_menu: String = "main"
var menu_transition_tween: Tween
var menus_active: bool = true
var level_info_dict: Dictionary = {
	"grid_dimensions": Vector2i.ZERO,
	"live_cells": {}, # format is index: ["cell type", number of live neighbours]
	"can_build_zones": {}, # format is node: ["filter", Rect2]
	"no_build_zones": {}, # format is node: ["filter", Rect2]
	"trigger_zones": {}, # format is node: ["filter", Rect2, "Logic Gate", "trigger_identifier"] # Filter types are: All, Empty, Alive, Target, Hole, Pole, Ally
	"logic_terms": {}, # format is node: ["outcome", "eval_string"]
	"logic_menu_structure": {}, # format is arbitrary_index: [outcome_index, [object_index, [selection_indexes], [child_A_info], [child_B_info]]]
	# Logic Object indexes are: 0=bool_constructor, 1=gen_count, 2=bool_var
	"level_name": "",
	"level_description": "",
	"level_instructions": "",
	"completion_rating": [false, false, false], # This is the best co,pletion rating across runs
	"current_rating": [false, false, false], # This is completion rating in current run
}
var trigger_zone_id_itterator: int = 0
var active_directory: String = ""

func _ready():
	Global.world_scene = self
	Global.menu_camera = menu_camera
	Global.game_camera = game_camera
	menu_camera.make_current()
	menus.get("GUI").set_gui_visible(false)
	current_menu = menus.get("Main_menu")
	switch_to_menu("Main_menu", true)
	outcome_overlay.visible = true

func _process(delta: float) -> void:
	if menus_active:
		rot_parent_menu_camera.rotation += delta * 0.1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			last_click_location = get_global_mouse_position()
			handle_cell_clicked(get_cell_index_from_position(last_click_location))
	if event.is_action_pressed("ui_cancel"):
		if current_menu != menus.get("Main_menu"):
			button_signal("main")

# Grid functions
func populate_cells(grid_size: Vector2i, cells_dict: Dictionary = {}, clear_previous: bool = true) -> void:
	if level_info_dict["grid_dimensions"] != grid_size:
		level_info_dict["grid_dimensions"] = grid_size
		current_cell_count = grid_size.x * grid_size.y
		grid_multimesh.instance_count = current_cell_count
		
		var cell_index: int = 0
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var pos = Vector2(x * (cell_size + cell_margin), y * (cell_size + cell_margin))
				grid_multimesh.set_instance_transform_2d(cell_index, Transform2D(0, pos))
				grid_multimesh.set_instance_color(cell_index, Global.dead_colour) # Grey, dead
				cell_index += 1
	
	if clear_previous:
		clear_grid()
	
	if not cells_dict.is_empty():
		for key in cells_dict.keys():
			set_cell_type(key, cells_dict.get(key)[0])

func populate_zones(can_build_zones: Dictionary, no_build_zones: Dictionary, trigger_zones: Dictionary, clear_previous: bool = true, prevent_zone_editing: bool = true) -> void:
	if clear_previous:
		clear_zones()
	
	var generic_zone = preload("res://Scenes/Props/zone_polygon.tscn")
	
	var new_can_build_dict: Dictionary = {}
	for zone in can_build_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("can build here")
		new_zone.set_rect(can_build_zones.get(zone)[1])
		new_can_build_dict[new_zone] = can_build_zones[zone]
	
	var new_no_build_dict: Dictionary = {}
	for zone in no_build_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("no build here")
		new_zone.set_rect(no_build_zones.get(zone)[1])
		new_no_build_dict[new_zone] = no_build_zones[zone]
	
	var new_trigger_dict: Dictionary = {}
	for zone in trigger_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("trigger")
		var zone_info: Array = trigger_zones.get(zone)
		new_zone.set_zone_options(zone_info[0], zone_info[2]) # Set filter and set gate
		new_zone.set_rect(zone_info[1])
		
		var trigger_id: String = zone_info[3]
		if trigger_id == "":
			push_error("missing a trigger id from loaded file")
		else:
			new_zone.set_trigger_identifier(trigger_id)
		new_trigger_dict[new_zone] = trigger_zones[zone]
	
	level_info_dict["can_build_zones"] = new_can_build_dict
	level_info_dict["no_build_zones"] = new_no_build_dict
	level_info_dict["trigger_zones"] = new_trigger_dict

func resize_grid(new_grid_size: Vector2i, cells_dict: Dictionary) -> void:
	if cells_dict.is_empty():
		cells_dict = level_info_dict["live_cells"]
	var old_grid_size: Vector2i = level_info_dict["grid_dimensions"]
	var old_dict: Dictionary = cells_dict
	var new_dict: Dictionary = {}
	
	for old_index in old_dict.keys():
		var cell_data = old_dict[old_index]
		
		var cell_position: Vector2 = Vector2(old_index % old_grid_size.x, old_index / old_grid_size.x)
		if cell_position.x >= new_grid_size.x or cell_position.y >= new_grid_size.y:
			continue # Skip this item in the loop
		var new_index: int = round(cell_position.y * new_grid_size.x + cell_position.x)
		new_dict[new_index] = cell_data
	
	# Call populate with new grid size and remapped dict
	populate_cells(new_grid_size, new_dict, true)

func iterate_generation() -> void:
	var cells_to_check: Dictionary = level_info_dict["live_cells"].duplicate(false)
	for cell_index in level_info_dict["live_cells"].keys():
		cells_to_check[cell_index][1] = 0
		for neighbour in get_neighbours(cell_index):
			
			if cells_to_check.has(neighbour):
				cells_to_check[neighbour][0] = get_cell_type(neighbour)
			else:
				cells_to_check[neighbour] = [get_cell_type(neighbour),0]
			
			if cells_to_check[neighbour][0] == "alive":
				cells_to_check[cell_index][1] += 1
	
	var dead_neighbour_cells: Dictionary = subtract_dicts(cells_to_check, level_info_dict["live_cells"], true)
	for cell_index in dead_neighbour_cells.keys():
		for neighbour in get_neighbours(cell_index):
			if get_cell_type(neighbour) == "alive":
				cells_to_check[cell_index][1] += 1
	
	for cell_index in cells_to_check.keys():
		var live_neighbours: int = cells_to_check.get(cell_index)[1]
		match cells_to_check.get(cell_index)[0]:
			"alive":
				if live_neighbours < 2 or live_neighbours > 3:
					set_cell_type(cell_index, "dead")
			"dead":
				if live_neighbours == 3:
					set_cell_type(cell_index, "alive")
	
	Global.generation_number += 1
	generation_itterated.emit()

func get_neighbours(target_index: int) -> Array:
	var grid_width: int = level_info_dict["grid_dimensions"].x
	var grid_height: int = level_info_dict["grid_dimensions"].y
	var column: int = target_index % grid_width
	var row: int = int(floor(float(target_index) / float(grid_width)))
	
	var neighbours: Array = []
	
	for dy in range(-1, 2):
		var neighbour_by_row: int = row + dy
		if neighbour_by_row < 0 or neighbour_by_row >= grid_height:
			continue
		for dx in range(-1, 2):
			
			if dx == 0 and dy == 0:
				continue
			
			var neighbour_by_column: int = column + dx
			if neighbour_by_column < 0 or neighbour_by_column >= grid_width:
				continue
			var neighbour_index = neighbour_by_row * grid_width + neighbour_by_column
			neighbours.append(neighbour_index)
	
	return neighbours

func get_cell_index_from_position(world_pos: Vector2) -> int: # Returns -1 on fail
	var step: float = cell_size + cell_margin
	var column = int(floor((world_pos.x + (step/2.0)) / step))
	var row = int(floor((world_pos.y + (step/2.0)) / step))
	
	if column < 0 or row < 0 or column >= level_info_dict["grid_dimensions"].x or row >= level_info_dict["grid_dimensions"].y:
		return -1
	
	var index = row * level_info_dict["grid_dimensions"].x + column
	if index >= current_cell_count:
		return -1
	
	var cell_origin = Vector2(column * step, row * step)
	var inside_x = (world_pos.x - cell_origin.x) < cell_size
	var inside_y = (world_pos.y - cell_origin.y) < cell_size
	if not (inside_x and inside_y):
		return -1  # clicked on margin gap
	return index

func handle_cell_clicked(cell_index: int) -> void:
	if cell_index >= 0 and cell_index < current_cell_count:
		
		if not is_index_buildable(cell_index):
			return
		
		match get_cell_type(cell_index):
			"dead": # Grey
				set_cell_type(cell_index, "alive")
			"alive": # Black
				set_cell_type(cell_index, "dead")

func clear_grid() -> void:
	for key in level_info_dict["live_cells"].keys():
		grid_multimesh.set_instance_color(key, Global.dead_colour)
	level_info_dict["live_cells"].clear()

func clear_zones() -> void:
	clear_zones_called.emit()
#	await get_tree().process_frame
	# Zones remove themselves from the level_info_dict
	# The following code is vestigial and a back up just in case a zone failed to connect the signal
#	for zone in level_info_dict["no_build_zones"]:
#		if zone is Polygon2D:
#			zone.self_destruct()
#	for zone in level_info_dict["can_build_zones"]:
#		if zone is Polygon2D:
#			zone.self_destruct()
#	for zone in level_info_dict["trigger_zones"]:
#		if zone is Polygon2D:
#			zone.self_destruct()
	# I'm keep this extra code for now because signals haven't worked perfectly in the past

func get_cell_type(cell_index: int) -> String:
	if level_info_dict["live_cells"].has(cell_index):
		return level_info_dict["live_cells"].get(cell_index)[0]
	else:
		return "dead"

func set_cell_type(cell_index: int, type: String) -> void:
	match type:
		"dead":
			level_info_dict["live_cells"].erase(cell_index)
			grid_multimesh.set_instance_color(cell_index, Global.dead_colour) # Grey
		"alive":
			level_info_dict["live_cells"][cell_index] = ["alive",0]
			grid_multimesh.set_instance_color(cell_index, Global.alive_colour) # Black

func index_to_grid_coords(cell_index: int) -> Vector2i:
	var grid_width: int = level_info_dict["grid_dimensions"].x
	return Vector2i(cell_index%grid_width, int(floor(float(cell_index)/float(grid_width))))

func is_index_buildable(cell_index: int, cell_type: String = "Alive") -> bool:
	if level_info_dict["no_build_zones"].is_empty() and level_info_dict["can_build_zones"].is_empty():
		return true # No zones
	
	for zone in level_info_dict["no_build_zones"]:
		var zone_filter: String = level_info_dict["no_build_zones"].get(zone)[0]
		if zone_filter == cell_type or zone_filter == "All":
			if level_info_dict["no_build_zones"].get(zone)[1].has_point(cell_size * index_to_grid_coords(cell_index)):
				return false # Point is in a no-build zone
	
	if level_info_dict["can_build_zones"].is_empty():
		return true
	else:
		for zone in level_info_dict["can_build_zones"]:
			var zone_filter: String = level_info_dict["can_build_zones"].get(zone)[0]
			if zone_filter == cell_type or zone_filter == "All":
				if level_info_dict["can_build_zones"].get(zone)[1].has_point(cell_size * index_to_grid_coords(cell_index)):
					return true # Is in a can-build zone, no-build zones already checked for
	
	return false # In neither type of zone

func remove_zone_from_lists(zone_node: Polygon2D) -> void:
	match zone_node.get_zone_type():
		"can build here":
			level_info_dict["can_build_zones"].erase(zone_node)
		"no build here":
			level_info_dict["no_build_zones"].erase(zone_node)
		"trigger":
			level_info_dict["trigger_zones"].erase(zone_node)

func update_or_add_zone_info(zone_node: Polygon2D) -> void:
	match zone_node.get_zone_type():
		"can build here":
			level_info_dict["can_build_zones"][zone_node] = zone_node.get_zone_info()
		"no build here":
			level_info_dict["no_build_zones"][zone_node] = zone_node.get_zone_info()
		"trigger":
			level_info_dict["trigger_zones"][zone_node] = zone_node.get_zone_info()
			if level_info_dict["trigger_zones"][zone_node][3] == "":
				trigger_zone_id_itterator += 1
				var new_id: String = "trigger_" + str(trigger_zone_id_itterator)
				level_info_dict["trigger_zones"][zone_node][3] = new_id
				zone_node.set_trigger_identifier(new_id)

func set_play_pause(set_to_play: bool) -> void:
	menus.get("GUI").set_play_pause(set_to_play)

# Menu functions
func switch_to_menu(menu_name: String, instant_transition: bool = false) -> void:
	if not menus.has(menu_name):
		return
	var new_menu: Control = menus.get(menu_name)
	if new_menu == current_menu:
		return
	if menu_transition_tween:
		menu_transition_tween.kill()
	
	if instant_transition:
		for menu in menus.values():
			menu.visible = false
			menu.position.x = -1 * (get_viewport().size.x + new_menu.size.x)
		new_menu.visible = true
		new_menu.position = Vector2.ZERO
	else:
		menu_transition_tween = get_tree().root.create_tween()
		menu_transition_tween.pause()
		menu_transition_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		var max_screen_vector: Vector2 = Vector2((get_viewport().size.x + new_menu.size.x),(get_viewport().size.y + new_menu.size.y))
		var transition_vector: Vector2 = [Vector2(-1,-1),Vector2(-1,0),Vector2(-1,1),Vector2(0,-1),Vector2(0,1),Vector2(1,-1),Vector2(1,0),Vector2(1,1)].pick_random()
		transition_vector = Vector2(max_screen_vector.x * transition_vector.x,max_screen_vector.y * transition_vector.y)
		menu_transition_tween.tween_property(current_menu, "position", transition_vector, 0.5)
		
		new_menu.position = -1 * transition_vector
		new_menu.visible = true
		menu_transition_tween.parallel().tween_property(new_menu, "position", Vector2.ZERO, 0.5)
		
		menu_transition_tween.play()
		menu_transition_tween.tween_callback(func():
			current_menu.visible = false
			current_menu = new_menu
			)

func button_signal(singal_name: String) -> void:
	match singal_name:
		"main":
			current_sub_menu = "main"
			switch_to_menu("Main_menu")
			clear_zones()
			menu_camera.make_current()
			menus.get("Main_menu")._on_background_reset_timer_timeout()
			set_play_pause(true)
		"levels":
			current_sub_menu = "levels"
			switch_to_menu("Levels_menu")
		"settings":
			current_sub_menu = "settings"
			switch_to_menu("Settings_menu")
		"build":
			current_sub_menu = "build"
			switch_to_menu("Build_menu")
			menus.get("GUI").set_play_pause(false)
			Global.generation_number = 0
			populate_cells(Vector2i(50,50), {}, true)
			game_camera.position = (cell_size + cell_margin) * level_info_dict["grid_dimensions"]/2.0
			game_camera.zoom = Vector2.ONE * 2.0
			game_camera.make_current()
		"exit":
			current_sub_menu = "exit"
			get_tree().paused = true
			get_tree().call_deferred("quit")
		"play":
			current_sub_menu = "play"
			switch_to_menu("GUI")
			menus.get("GUI").set_play_pause(false)
			Global.generation_number = 0
			menus.get("GUI").set_gui_visible(true)
			game_camera.position = (cell_size + cell_margin) * level_info_dict["grid_dimensions"]/2.0
			game_camera.zoom = Vector2.ONE * 2.0
			game_camera.make_current()

# File functions
func open_level_from_local(skip_directory_prompt: bool = false, prevent_zone_editing: bool = false, populate_level: bool = true) -> bool:
	var open_from_directory: String = ""
	if skip_directory_prompt and active_directory.get_extension() == "cgow":
		open_from_directory = active_directory
	else:
		open_from_directory = await Global.prompt_user_for_file_path("Open", "", "", ["*.cgow"], false)
	
	var loaded_file = Global.load_from_file(open_from_directory)
	if loaded_file:
		active_directory = open_from_directory
		menus.get("Build_menu").file_name_label.text = active_directory.get_file()
		menus.get("Build_menu").reset_to_saved_button.disabled = false
	else:
		print("Could not open file: " + open_from_directory + "\n" + loaded_file)
		return false
#	populate_cells(loaded_file.get("grid_dimensions"), loaded_file.get("live_cells"), true)
#	level_info_dict = loaded_file
#	populate_zones(loaded_file.get("can_build_zones"), loaded_file.get("no_build_zones"), loaded_file.get("trigger_zones"), true, prevent_zone_editing)
#	populate_logic_terms(loaded_file.get("logic_menu_structure"))
#	if repair_current_file_missing_parameters():
#		print("Loaded file was missing parameters" + "\n" + "Missing parameters have been filled with default values")
	
	print("Missing parameters in loaded file:" + "\n" + str(repair_current_file_missing_parameters()) + "\n" + "Missing parameters are automatically filled with default values")
	
	if populate_level:
		full_populate_level(loaded_file, prevent_zone_editing)
	
	return true

func full_populate_level(level_dict: Dictionary = level_info_dict, prevent_zone_editing: bool = false) -> void:
	populate_cells(level_dict.get("grid_dimensions"), level_dict.get("live_cells"), true)
	level_info_dict = level_dict
	populate_zones(level_dict.get("can_build_zones"), level_dict.get("no_build_zones"), level_dict.get("trigger_zones"), true, prevent_zone_editing)
	populate_logic_terms(level_dict.get("logic_menu_structure"))

func save_level(level_data: Dictionary) -> void:
	if active_directory:
		Global.save_to_file(level_data, active_directory)
		menus.get("Build_menu").reset_to_saved_button.disabled = false
	else:
		save_level_as(level_data)

func save_level_as(level_data: Dictionary) -> void:
	active_directory = await Global.prompt_user_for_file_path()
	if active_directory.get_extension() != "cgow":
		active_directory += ".cgow"
	Global.save_to_file(level_data, active_directory)
	menus.get("Build_menu").reset_to_saved_button.disabled = false

func repair_current_file_missing_parameters() -> int: # Returns number of repaired parameters
	# Checks if the current file is missing any parameters and fills them with the default
	
	var repaired_parameters: int = 0
	
	if not level_info_dict.has("grid_dimensions"):
		level_info_dict["grid_dimensions"] = Vector2i.ZERO
		repaired_parameters += 1
	if not level_info_dict.has("live_cells"):
		level_info_dict["live_cells"] = {}
		clear_grid()
		repaired_parameters += 1
	if not level_info_dict.has("can_build_zones"):
		level_info_dict["can_build_zones"] = {}
		repaired_parameters += 1
	if not level_info_dict.has("no_build_zones"):
		level_info_dict["no_build_zones"] = {}
		repaired_parameters += 1
	if not level_info_dict.has("trigger_zones"):
		level_info_dict["trigger_zones"] = {}
		repaired_parameters += 1
	if not level_info_dict.has("logic_terms"):
		level_info_dict["logic_terms"] = {}
		repaired_parameters += 1
	if not level_info_dict.has("logic_menu_structure"):
		level_info_dict["logic_menu_structure"] = {}
		repaired_parameters += 1
	if not level_info_dict.has("level_name"):
		level_info_dict["level_name"] = ""
		repaired_parameters += 1
	if not level_info_dict.has("level_description"):
		level_info_dict["level_description"] = ""
		repaired_parameters += 1
	if not level_info_dict.has("level_instructions"):
		level_info_dict["level_instructions"] = ""
		repaired_parameters += 1
	if not level_info_dict.has("completion_rating"):
		level_info_dict["completion_rating"] = [false, false, false]
		repaired_parameters += 1
	if not level_info_dict.has("current_rating"):
		level_info_dict["current_rating"] = [false, false, false]
		repaired_parameters += 1
	
	return repaired_parameters

# Misc functions
func subtract_dicts(dict_subtracting_from: Dictionary, dict_subtracting: Dictionary, only_keep_keys: bool = false) -> Dictionary:
	var result: Dictionary = {}
	for key in dict_subtracting_from.keys():
		if not dict_subtracting.has(key):
			if only_keep_keys:
				result[key] = null
			else:
				result[key] = dict_subtracting_from[key]
	return result

func populate_logic_terms(logic_structures: Dictionary) -> void:
	var build_menu: Node = menus.get("Build_menu")
	build_menu.clear_logic_structures()
	build_menu.create_and_set_logic_terms(logic_structures)

func remove_logic_term_from_dict(logic_term: Node) -> void:
	level_info_dict["logic_terms"].erase(logic_term)
	menus.get("Build_menu").logic_terms.erase(logic_term)

func evaluate_string_to_bool(expr_string: String) -> bool:
	if expr_string.is_empty():
		push_error("Empty expression passed to evaluate_string_to_bool()")
		return false
	
	var variable_ids: PackedStringArray = ["gen_count"]
	var values: Array = [Global.generation_number]
	
	for node in level_info_dict["trigger_zones"].keys():
		var id: String = level_info_dict["trigger_zones"][node][3]
		variable_ids.append(id)
		values.append(node.get_trigger_status())
	if variable_ids.size() != values.size():
		push_error("Discrepancy in number of variables and values in evaluate_string_to_bool()" + "\n" + "variable_ids.size() " + str(variable_ids.size()) + "\n" + "values.size() " + str(values.size()) + "\n" + str(variable_ids) + "\n" + str(values))
		return false
	#var inputs: Dictionary = {
	#	"identifiers": variable_ids,
	#	"values": values
	#}
	
	var expression: Expression = Expression.new()
	var error = expression.parse(expr_string, variable_ids)
	if error != OK:
		push_error("Expression parse error: " + expression.get_error_text())
		return false
	
	var result = expression.execute(values)
	if expression.has_execute_failed():
		push_error("Expression execution failed")
		return false
	
	return bool(result)

func check_logic_conditions(trigger_id: String = "") -> void:
	if trigger_id == "":
		# check all
		for logic_term in level_info_dict.get("logic_terms").values():
			if evaluate_string_to_bool(logic_term[1]):
				process_logic_term_outcome(logic_term[0])
	else:
		# check only logic conditions containing trigger_id
		for logic_term in level_info_dict.get("logic_terms").values():
			if logic_term[1].contains(trigger_id):
				if evaluate_string_to_bool(logic_term[1]):
					process_logic_term_outcome(logic_term[0])

func process_logic_term_outcome(outcome: String) -> void:
	match outcome:
		"star_1": # ★☆☆
			level_info_dict["current_rating"][0] = true
		"star_2": # ☆★☆
			level_info_dict["current_rating"][1] = true
		"star_3": # ☆☆★
			level_info_dict["current_rating"][2] = true
		"star_1_2": # ★★☆
			level_info_dict["current_rating"][0] = true
			level_info_dict["current_rating"][1] = true
		"star_1_2_3": # ★★★
			level_info_dict["current_rating"] = [true, true, true]
		"defeat":
			pass
		"victory":
			var count_completion_rating: int = int(level_info_dict["completion_rating"][0]) + int(level_info_dict["completion_rating"][1]) + int(level_info_dict["completion_rating"][2])
			var count_current_rating: int = int(level_info_dict["current_rating"][0]) + int(level_info_dict["current_rating"][1]) + int(level_info_dict["current_rating"][2])
			if count_current_rating >= count_completion_rating:
				level_info_dict["completion_rating"] = level_info_dict["current_rating"]
	outcome_overlay.queue_outcome_to_print(outcome)

# Signal functions
