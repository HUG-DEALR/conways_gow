extends Node2D

@onready var grid: MultiMeshInstance2D = $Grid
@onready var grid_multimesh: MultiMesh = grid.multimesh
@onready var game_camera: Camera2D = $Game_Camera
@onready var menu_camera: Camera2D = $Rot_Parent/Menu_Camera
@onready var rot_parent_menu_camera: Node2D = $Rot_Parent
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var menus: Dictionary = {
	"GUI": $CanvasLayer/GUI_Standard,
	"Main_menu": $CanvasLayer/MainMenu,
	"Levels_menu": $CanvasLayer/Levels_Menu,
	"Settings_menu": $CanvasLayer/Settings,
	"Build_menu": $CanvasLayer/GUI_Standard2,
}

const cell_size: float = 10.0
const cell_margin: float = 0.0

#var current_grid_dimensions: Vector2i
var current_cell_count: int
var last_click_location: Vector2 = Vector2.ZERO
#var live_cells_dict: Dictionary = {} # format is index: ["cell type", live neighbours]
#var can_build_zones_dict: Dictionary = {} # format is node: ["filter", Rect2]
#var no_build_zones_dict: Dictionary = {} # format is node: ["filter", Rect2]
#var trigger_zones_dict: Dictionary = {} # format is node: ["filter", Rect2, "Logic Gate"] # Filter types are: All, Empty, Alive, Target, Hole, Pole, Ally
var current_menu: Control
var current_sub_menu: String = "main"
var menu_transition_tween: Tween
var menus_active: bool = true
var level_info_dict: Dictionary = {
	"grid_dimensions": Vector2i.ZERO,
	"live_cells": {}, # format is index: ["cell type", live neighbours]
	"can_build_zones": {}, # format is node: ["filter", Rect2]
	"no_build_zones": {}, # format is node: ["filter", Rect2]
	"trigger_zones": {}, # format is node: ["filter", Rect2, "Logic Gate"] # Filter types are: All, Empty, Alive, Target, Hole, Pole, Ally
}

func _ready():
	Global.world_scene = self
	Global.menu_camera = menu_camera
	Global.game_camera = game_camera
	menu_camera.make_current()
	menus.get("GUI").set_gui_visible(false)
	current_menu = menus.get("Main_menu")
	switch_to_menu("Main_menu", true)

func _process(delta: float) -> void:
	if menus_active:
		rot_parent_menu_camera.rotation += delta * 0.1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			last_click_location = get_global_mouse_position()
			handle_cell_clicked(get_clicked_cell_index(last_click_location))

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
	
	for zone in can_build_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("can build here")
		new_zone.set_rect(can_build_zones.get(zone)[1])
	
	for zone in no_build_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("no build here")
		new_zone.set_rect(no_build_zones.get(zone)[1])
	
	for zone in trigger_zones:
		var new_zone = generic_zone.instantiate()
		add_child(new_zone)
		if prevent_zone_editing:
			new_zone.toggle_lock_state(true)
		new_zone.visible = true
		new_zone.set_zone_type("trigger")
		new_zone.set_rect(trigger_zones.get(zone)[1])

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

func get_clicked_cell_index(world_pos: Vector2) -> int:
	# Get total spacing (size + margin)
	var step: float = cell_size + cell_margin
	
	# Convert world position to grid-space coordinates
	var column = int(floor((world_pos.x + (step/2.0)) / step))
	var row = int(floor((world_pos.y + (step/2.0)) / step))
	
	# Check if inside grid bounds
	if column < 0 or row < 0 or column >= level_info_dict["grid_dimensions"].x or row >= level_info_dict["grid_dimensions"].y:
		return -1
	
	# Compute the index
	var index = row * level_info_dict["grid_dimensions"].x + column
	if index >= current_cell_count:
		return -1
	
	# check if target landed inside the actual cell (not in margin)
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
	for zone in level_info_dict["no_build_zones"]:
		zone.self_destruct()
	for zone in level_info_dict["can_build_zones"]:
		zone.self_destruct()
	for zone in level_info_dict["trigger_zones"]:
		zone.self_destruct()

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
			game_camera.position = Vector2.ZERO
			game_camera.zoom = Vector2.ONE * 2.0
			game_camera.make_current()
		"exit":
			current_sub_menu = "exit"
			get_tree().paused = true
			get_tree().call_deferred("quit")
		"play":
			current_sub_menu = "play"
			menus.get("GUI").set_gui_visible(true)
			switch_to_menu("GUI")
			menus.get("GUI").set_play_pause(false)
			Global.generation_number = 0
			game_camera.position = Vector2.ZERO
			game_camera.zoom = Vector2.ONE * 2.0
			game_camera.make_current()

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

# Signal functions
