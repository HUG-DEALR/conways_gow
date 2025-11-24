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

var current_grid_dimensions: Vector2i
var current_cell_count: int
var last_click_location: Vector2 = Vector2.ZERO
var live_cells_dict: Dictionary = {} # format is index: ["type", live neighbours]
var buildable_rects: Array[Rect2i] = []
var current_menu: Control
var current_sub_menu: String = "main"
var menu_transition_tween: Tween
var menus_active: bool = true

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
func populate_cells(grid_size: Vector2i, level_dict: Dictionary = {}, clear_previous: bool = true) -> void:
	if current_grid_dimensions != grid_size:
		current_grid_dimensions = grid_size
		current_cell_count = grid_size.x * grid_size.y
		grid_multimesh.instance_count = current_cell_count
		
		var i: int = 0
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var pos = Vector2(x * (cell_size + cell_margin), y * (cell_size + cell_margin))
				grid_multimesh.set_instance_transform_2d(i, Transform2D(0, pos))
				grid_multimesh.set_instance_color(i, Global.dead_colour) # Grey, dead
				i += 1
	
	if clear_previous:
		clear_grid()
	if not level_dict.is_empty():
	#	if max(level_dict.keys()) >= current_cell_count:
	#		return # level dict does not match size
		for key in level_dict.keys():
			set_cell_type(key, level_dict.get(key)[0])

func iterate_generation() -> void:
	var cells_to_check: Dictionary = live_cells_dict.duplicate(false)
	for cell_index in live_cells_dict.keys():
		cells_to_check[cell_index][1] = 0
		for neighbour in get_neighbours(cell_index):
			
			if cells_to_check.has(neighbour):
				cells_to_check[neighbour][0] = get_cell_type(neighbour)
			else:
				cells_to_check[neighbour] = [get_cell_type(neighbour),0]
			
			if cells_to_check[neighbour][0] == "alive":
				cells_to_check[cell_index][1] += 1
	
	var dead_neighbour_cells: Dictionary = subtract_dicts(cells_to_check, live_cells_dict, true)
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

func get_neighbours(target_index: int) -> Array:
	var grid_width: int = current_grid_dimensions.x
	var grid_height: int = current_grid_dimensions.y
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
	if column < 0 or row < 0 or column >= current_grid_dimensions.x or row >= current_grid_dimensions.y:
		return -1
	
	# Compute the index
	var index = row * current_grid_dimensions.x + column
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
		
		if not is_index_in_buildable_zones(cell_index):
			return
		
		match get_cell_type(cell_index):
			"dead": # Grey
				set_cell_type(cell_index, "alive")
			"alive": # Black
				set_cell_type(cell_index, "dead")
#	else:
#		print("invalid cell index passed to handle_cell_clicked()")

func clear_grid() -> void:
	for key in live_cells_dict.keys():
		grid_multimesh.set_instance_color(key, Global.dead_colour)
	live_cells_dict.clear()

func get_cell_type(cell_index: int) -> String:
	if live_cells_dict.has(cell_index):
		return live_cells_dict.get(cell_index)[0]
	else:
		return "dead"

func set_cell_type(cell_index: int, type: String) -> void:
	match type:
		"dead":
			live_cells_dict.erase(cell_index)
			grid_multimesh.set_instance_color(cell_index, Global.dead_colour) # Grey
		"alive":
			live_cells_dict[cell_index] = ["alive",0]
			grid_multimesh.set_instance_color(cell_index, Global.alive_colour) # Black

func index_to_grid_coords(cell_index: int) -> Vector2i:
	var grid_width: int = current_grid_dimensions.x
	return Vector2i(cell_index%grid_width, int(floor(float(cell_index)/float(grid_width))))

func is_index_in_buildable_zones(cell_index: int) -> bool:
	if buildable_rects.is_empty():
		return true
	for rectangle in buildable_rects:
		if rectangle.has_point(index_to_grid_coords(cell_index)):
			return true
	return false

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
		menu_transition_tween.tween_property(current_menu, "position", Vector2(get_viewport().size.x + current_menu.size.x, 0.0), 0.5)
		
		new_menu.position.x = -1 * (get_viewport().size.x + new_menu.size.x)
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
			populate_cells(Vector2i(50,50), {}, true)
			game_camera.position = Vector2.ZERO
			game_camera.zoom = Vector2.ONE * 2.0
	#		var grid_real_size = current_grid_dimensions * (cell_size + cell_margin)
	#		game_camera.set_bounds(Rect2(Vector2(0,0),grid_real_size))
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
			game_camera.position = Vector2.ZERO
			game_camera.zoom = Vector2.ONE * 2.0
	#		var grid_real_size = current_grid_dimensions * (cell_size + cell_margin)
	#		game_camera.set_bounds(Rect2(Vector2(0,0),grid_real_size))
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
