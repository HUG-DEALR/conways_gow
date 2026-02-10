extends Polygon2D

@onready var top_left_area_2d: Area2D = $Top_Left_Area2D
@onready var top_right_area_2d: Area2D = $Top_Right_Area2D
@onready var bottom_right_area_2d: Area2D = $Bottom_Right_Area2D
@onready var bottom_left_area_2d: Area2D = $Bottom_Left_Area2D
@onready var gui_parent: Control = $GUI_Parent
@onready var tab_container: TabContainer = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer
@onready var zone_name_line_edit: LineEdit = $GUI_Parent/PanelContainer/VBoxContainer/HBoxContainer/Zone_Name_LineEdit
@onready var can_build_zone_option_filter: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer/Can_Build_Here/VBoxContainer/HBoxContainer/OptionButton2
@onready var no_build_zone_option_filter: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer/No_Build_Here/VBoxContainer/HBoxContainer/OptionButton2
@onready var trigger_zone_option_gate: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer/Trigger/VBoxContainer/HBoxContainer/Gate
@onready var trigger_zone_option_filter: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer/Trigger/VBoxContainer/HBoxContainer/Filter
@onready var central_area_2d: Area2D = $Central_Area2D
@onready var central_collision_shape_2d: CollisionShape2D = $Central_Area2D/Central_CollisionShape2D
@onready var corner_indicators: Array[Node] = [
	$Top_Left_Area2D/Polygon2D,
	$Top_Right_Area2D/Polygon2D,
	$Bottom_Right_Area2D/Polygon2D,
	$Bottom_Left_Area2D/Polygon2D,
]

const min_dimensions: Vector2 = Vector2(10,10)

var dragging_corner: Node = null
var drag_offset: Vector2 = Vector2.ZERO
var menu_tween: Tween
var single_cell_grid_rect: Rect2 = Rect2(Vector2.ONE * 5.0, Vector2.ONE * 10.0)
var zone_type: String = ""
var zone_name: String = ""
var trigger_identifier: String = ""
var filter_id: int = 1
var filter_type: String = "empty"
var gate_id: int = 0
var total_covered_cells: int = 0
var previous_measured_population: int = 0 # This var is not updated unless the trigger gate is "pop change of"
var previous_trigger_status: bool = false # This var is not updated unless the zone is a trigger

func _ready() -> void:
	set_process(false)
	
	gui_parent.visible = false
	
	polygon = [
		Vector2(0, 0),
		Vector2(20, 0),
		Vector2(20, 20),
		Vector2(0, 20),
	]
	set_zone_type("can build here")
	
	_update_corner_positions()
	
	await get_tree().process_frame
	snap_to_grid(single_cell_grid_rect)
	if Global.world_scene:
		gui_parent.reparent(Global.world_scene.canvas_layer)
		Global.world_scene.update_or_add_zone_info(self)
		single_cell_grid_rect.size = Vector2.ONE * (Global.world_scene.cell_size + Global.world_scene.cell_margin)
		Global.world_scene.connect("generation_itterated", _on_generation_iterated)
		Global.world_scene.connect("clear_zones_called", self_destruct)
	else:
		print("World scene not found through Global, option window failed to reparent for node:" + "\n" + str(self))
	
	var tab_bar: TabBar = tab_container.get_tab_bar()
	tab_bar.set_tab_title(0,"Can Build Zone")
	tab_bar.set_tab_title(1,"No Build Zone")

func _process(_delta: float) -> void:
	if dragging_corner:
	#	var new_pos = to_local(get_viewport().get_mouse_position()) + drag_offset
		var new_pos: Vector2 = get_global_mouse_position() + drag_offset
		_drag_corner(dragging_corner, new_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and !event.pressed:
		dragging_corner = null
		set_process(false)
		snap_to_grid(single_cell_grid_rect)

func _handle_corner_input(corner: Node, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging_corner = corner
				drag_offset = corner.position - to_local(get_global_mouse_position())
				set_process(true)

func _drag_corner(corner: Node, new_global_pos: Vector2) -> void:
	var target_position: Vector2 = to_local(new_global_pos)
	
	var x1: float = min(polygon[0].x, polygon[3].x)
	var x2: float = max(polygon[1].x, polygon[2].x)
	var y1: float = min(polygon[0].y, polygon[1].y)
	var y2: float = max(polygon[2].y, polygon[3].y)
	
	match corner:
		top_left_area_2d:
			x1 = target_position.x
			y1 = target_position.y
		top_right_area_2d:
			x2 = target_position.x
			y1 = target_position.y
		bottom_right_area_2d:
			x2 = target_position.x
			y2 = target_position.y
		bottom_left_area_2d:
			x1 = target_position.x
			y2 = target_position.y
	
	if (x2 - x1) < min_dimensions.x:
		if corner == top_left_area_2d or corner == bottom_left_area_2d:
			x1 = x2 - min_dimensions.x
		else:
			x2 = x1 + min_dimensions.x
	if (y2 - y1) < min_dimensions.y:
		if corner == top_left_area_2d or corner == top_right_area_2d:
			y1 = y2 - min_dimensions.y
		else:
			y2 = y1 + min_dimensions.y
	
	x2 = x2 - x1
	y2 = y2 - y1
	
	global_position += Vector2(x1,y1)
	polygon = [
		Vector2.ZERO,
		Vector2(x2, 0.0),
		Vector2(x2, y2),
		Vector2(0.0, y2)
	]
	
	_update_corner_positions()

func _update_corner_positions() -> void:
	var area_offset_from_corner = Vector2(2.5, 2.5)
	
	top_left_area_2d.position = polygon[0] + area_offset_from_corner
	top_right_area_2d.position = polygon[1] + Vector2(-area_offset_from_corner.x, area_offset_from_corner.y)
	bottom_right_area_2d.position = polygon[2] - area_offset_from_corner
	bottom_left_area_2d.position = polygon[3] + Vector2(area_offset_from_corner.x, -area_offset_from_corner.y)
	
	central_area_2d.position = (polygon[0] + polygon[2])/2.0
	central_collision_shape_2d.shape.size = abs(polygon[2] - polygon[0]) - min_dimensions

func get_rect() -> Rect2:
	return Rect2(global_position, abs(polygon[2]-polygon[0]))

func set_rect(new_rect: Rect2) -> void:
	global_position = new_rect.position
	polygon = [
		Vector2.ZERO,
		Vector2(new_rect.size.x, 0.0),
		new_rect.size,
		Vector2(0.0, new_rect.size.y),
	]

func set_zone_type(type: String) -> void:
	match type:
		"can build here":
			color = Color(0.0,0.5,0.7,0.2)
			zone_type = type
		"no build here":
			color = Color(0.7,0.0,0.0,0.2)
			zone_type = type
		"trigger":
			color = Color(0.0,0.7,0.5,0.2)
			zone_type = type

func get_zone_type() -> String:
	return zone_type

func get_zone_info() -> Array:
	var zone_info: Array = ["",Rect2()]
	match zone_type:
		"can build here": # format is node: ["filter", Rect2]
			zone_info[0] = can_build_zone_option_filter.get_item_text(can_build_zone_option_filter.selected)
			zone_info[1] = get_rect()
		"no build here": # format is node: ["filter", Rect2]
			zone_info[0] = no_build_zone_option_filter.get_item_text(no_build_zone_option_filter.selected)
			zone_info[1] = get_rect()
		"trigger": # format is node: ["filter", Rect2, "Logic Gate", "trigger_id"]
			zone_info.resize(4)
			zone_info[0] = trigger_zone_option_filter.get_item_text(trigger_zone_option_filter.selected)
			zone_info[1] = get_rect()
			zone_info[2] = trigger_zone_option_gate.get_item_text(trigger_zone_option_gate.selected)
			zone_info[3] = trigger_identifier
	return zone_info

func set_zone_options(filter: String, logic_gate: String) -> void:
	match filter:
		"All":
			filter_id = 0
		"Empty":
			filter_id = 1
		"Alive":
			filter_id = 2
		"Target":
			filter_id = 3
		"Hole":
			filter_id = 4
		"Pole":
			filter_id = 5
		"Ally":
			filter_id = 6
	trigger_zone_option_filter.select(filter_id)
	
	match logic_gate:
		"Zone is all":
			gate_id = 0
		"Zone has no":
			gate_id = 1
		"Pop change of":
			gate_id = 2
	trigger_zone_option_gate.select(gate_id)

func get_bool_string_segment() -> String:
	if zone_type != "trigger" or trigger_identifier == "":
		return "false" # Non trigger zone can never be true
	return trigger_identifier

func set_trigger_identifier(identifier: String) -> void:
	trigger_identifier = identifier

func get_covered_active_cells(active_cells: Array) -> Array[int]:
	var output_list: Array[int] = []
	var rect: Rect2 = get_rect()
	var step: float = single_cell_grid_rect.size.x
	var grid_origin: Vector2 = single_cell_grid_rect.position
	
	if total_covered_cells < active_cells.size():
		# This method is prefered when active cells is large and or rect is small
		
		var start_column: int = int(floor((rect.position.x - grid_origin.x) / step))
		var start_row: int = int(floor((rect.position.y - grid_origin.y) / step))
		var end_column: int = int(ceil((rect.position.x + rect.size.x - grid_origin.x) / step)) - 1
		var end_row: int = int(ceil((rect.position.y + rect.size.y - grid_origin.y) / step)) - 1
		
		var grid_dimensions: Vector2i = Global.world_scene["grid_dimensions"]
		
		start_column = clamp(start_column, 0, grid_dimensions.x - 1)
		start_row = clamp(start_row, 0, grid_dimensions.y - 1)
		end_column = clamp(end_column, 0, grid_dimensions.x - 1)
		end_row = clamp(end_row, 0, grid_dimensions.y - 1)
		
		for row in range(start_row, end_row + 1):
			for column in range(start_column, end_column + 1):
				var index: int = Global.world_scene.get_cell_index_from_position(grid_origin + Vector2(column * step, row * step))
				if index != -1 and active_cells.has(index):
					output_list.append(index)
	else: # total_covered_cells >= active_cells.size()
		# This method is prefered when active cells is small and or rect is large
		for index in active_cells:
			if rect.has_point(grid_origin + (Global.world_scene.index_to_grid_coords(index) * step)):
				output_list.append(index)
	
	return output_list

func get_trigger_status() -> bool:
	if filter_id < 0 or filter_id > 6:
		print("Trigger filter not configured for " + trigger_identifier + "\n" + str(self))
		previous_trigger_status = false
		return false
	match gate_id:
		
		0: # Zone is all
			if filter_id == 0: # Any
				previous_trigger_status = true
				return true # If (Zone is all) (Any) is always true
			var active_cell_indexes: Array = get_covered_active_cells(Global.world_scene.level_info_dict["live_cells"].keys())
			match filter_id:
				1: # Empty
					if active_cell_indexes.size() == 0:
						previous_trigger_status = true
						return true # If there are no active cells then (Zone is all) (Empty) is true
					else:
						previous_trigger_status = false
						return false # There is atleast 1 active cell
				_: # Alive, Target, Hole, Pole, Ally
					if active_cell_indexes.size() != total_covered_cells:
						previous_trigger_status = false
						return false # Number of active cells does not fill zone, atleast 1 inactive cell
					else:
						for cell_index in active_cell_indexes:
							if Global.world_scene.get_cell_type(cell_index) != filter_type:
								previous_trigger_status = false
								return false # All cells active, atleast 1 cell of wrong type
						previous_trigger_status = true
						return true # All cells of right type
		
		1: # Zone has no
			if filter_id == 0: # Any
				previous_trigger_status = false
				return false # If (Zone has no) (Any) is always false
			var active_cell_indexes: Array = get_covered_active_cells(Global.world_scene.level_info_dict["live_cells"].keys())
			match filter_id:
				1: # Empty
					if active_cell_indexes.size() == total_covered_cells:
						previous_trigger_status = true
						return true # All cells are live, not empty. zone has no empty
					else:
						previous_trigger_status = false
						return false # Atleast 1 empty cell
				_: # Alive, Target, Hole, Pole, Ally
					if active_cell_indexes.size() == 0:
						previous_trigger_status = true
						return true # All cells empty, Zone has no of any other type
					else:
						for cell_index in active_cell_indexes:
							if Global.world_scene.get_cell_type(cell_index) == filter_type:
								previous_trigger_status = false
								return false # Atleast 1 cell of target type
						previous_trigger_status = true
						return true # No cells of target type
		
		2: # Population change of
			if previous_measured_population != get_population_of_covered_cell_type(filter_type):
				previous_trigger_status = true
				return true
			else:
				previous_trigger_status = false
				return false
		
		_: # Fail safe
			print("Trigger gate not configured for " + trigger_identifier + "\n" + str(self))
			previous_trigger_status = false
			return false

func get_population_of_covered_cell_type(cell_type: String) -> int:
	var active_cell_indexes: Array = get_covered_active_cells(Global.world_scene.level_info_dict["live_cells"].keys())
	var count: int = 0
	for cell_index in active_cell_indexes:
		if Global.world_scene.get_cell_type(cell_index) == cell_type:
			count += 1
	return count

func toggle_zone_menu_visible(make_visible: bool) -> void:
	if menu_tween:
		menu_tween.kill()
	menu_tween = get_tree().create_tween()
	menu_tween.pause()
	menu_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	gui_parent.pivot_offset = get_viewport().get_canvas_transform() * (global_position) - gui_parent.position
	if make_visible:
		update_zone_options()
		menu_tween.tween_property(gui_parent, "scale", Vector2.ZERO, 0.0)
		menu_tween.tween_property(gui_parent, "scale", Vector2.ONE, 0.3)
		gui_parent.visible = true
		menu_tween.play()
	else:
		menu_tween.tween_property(gui_parent, "scale", Vector2.ZERO, 0.3)
		menu_tween.play()
		await menu_tween.finished
		gui_parent.visible = false

func toggle_lock_state(lock_state: bool) -> void:
	if lock_state:
		if top_left_area_2d.is_connected("input_event", Callable(self, "_on_top_left_area_2d_input_event")):
			top_left_area_2d.disconnect("input_event", Callable(self, "_on_top_left_area_2d_input_event"))
		if top_right_area_2d.is_connected("input_event", Callable(self, "_on_top_right_area_2d_input_event")):
			top_right_area_2d.disconnect("input_event", Callable(self, "_on_top_right_area_2d_input_event"))
		if bottom_right_area_2d.is_connected("input_event", Callable(self, "_on_bottom_right_area_2d_input_event")):
			bottom_right_area_2d.disconnect("input_event", Callable(self, "_on_bottom_right_area_2d_input_event"))
		if bottom_left_area_2d.is_connected("input_event", Callable(self, "_on_bottom_left_area_2d_input_event")):
			bottom_left_area_2d.disconnect("input_event", Callable(self, "_on_bottom_left_area_2d_input_event"))
		for node in corner_indicators:
			node.visible = false
	else:
		if not top_left_area_2d.is_connected("input_event", Callable(self, "_on_top_left_area_2d_input_event")):
			top_left_area_2d.connect("input_event", Callable(self, "_on_top_left_area_2d_input_event"))
		if not top_right_area_2d.is_connected("input_event", Callable(self, "_on_top_right_area_2d_input_event")):
			top_right_area_2d.connect("input_event", Callable(self, "_on_top_right_area_2d_input_event"))
		if not bottom_right_area_2d.is_connected("input_event", Callable(self, "_on_bottom_right_area_2d_input_event")):
			bottom_right_area_2d.connect("input_event", Callable(self, "_on_bottom_right_area_2d_input_event"))
		if not bottom_left_area_2d.is_connected("input_event", Callable(self, "_on_bottom_left_area_2d_input_event")):
			bottom_left_area_2d.connect("input_event", Callable(self, "_on_bottom_left_area_2d_input_event"))
		for node in corner_indicators:
			node.visible = true

func snap_to_grid(grid_rect: Rect2) -> void:
	var cell_pos: Vector2 = grid_rect.position
	var cell_size: Vector2 = grid_rect.size
	
	var new_poly: Array[Vector2] = []
	
	for vertex in polygon:
		new_poly.append(((global_position + vertex - cell_pos) / cell_size).round() * cell_size + cell_pos - global_position)
	
	polygon = new_poly
	_update_corner_positions()
	Global.world_scene.update_or_add_zone_info(self)
	total_covered_cells = int(round(get_rect().get_area()/single_cell_grid_rect.get_area()))

func apply_zone_options() -> void:
	var target_type: String = ""
	match tab_container.current_tab:
		0: # Can build here
			target_type = "can build here"
		1: # No build here
			target_type = "no build here"
		2: # Trigger
			target_type = "trigger"
		3: # Delete
			self_destruct()
			return
	
	zone_name = zone_name_line_edit.text
	
	if target_type != zone_type:
		Global.world_scene.remove_zone_from_lists(self)
	set_zone_type(target_type)
	Global.world_scene.update_or_add_zone_info(self)

func update_zone_options() -> void:
	match zone_type:
		"can build here":
			tab_container.current_tab = 0
		"no build here":
			tab_container.current_tab = 1
		"trigger":
			tab_container.current_tab = 2
	
	zone_name_line_edit.text = zone_name

func self_destruct() -> void:
	toggle_zone_menu_visible(false)
	if gui_parent.visible:
		await gui_parent.visibility_changed
	gui_parent.queue_free()
	Global.world_scene.remove_zone_from_lists(self)
	menu_tween.kill()
	self.queue_free()

func _on_top_left_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(top_left_area_2d, event)

func _on_top_right_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(top_right_area_2d, event)

func _on_bottom_right_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(bottom_right_area_2d, event)

func _on_bottom_left_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(bottom_left_area_2d, event)

func _on_cancel_pressed() -> void:
	toggle_zone_menu_visible(false)

func _on_central_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and !gui_parent.visible:
				toggle_zone_menu_visible(true)

func _on_apply_zone_options_pressed() -> void:
	toggle_zone_menu_visible(false)
	apply_zone_options()

func _on_gate_item_selected(index: int) -> void:
	gate_id = index

func _on_filter_item_selected(index: int) -> void:
	filter_id = index
	filter_type = trigger_zone_option_filter.get_item_text(index).to_lower()

func _on_generation_iterated() -> void:
	if zone_type == "trigger":
		if previous_trigger_status != get_trigger_status():
			# Only check full bool if there is a change in status
			Global.world_scene.check_logic_conditions(trigger_identifier)
		
		if gate_id == 2: # Population change of
			previous_measured_population = get_population_of_covered_cell_type(filter_type)
