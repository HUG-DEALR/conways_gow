extends Polygon2D

@onready var top_left_area_2d: Area2D = $Top_Left_Area2D
@onready var top_right_area_2d: Area2D = $Top_Right_Area2D
@onready var bottom_right_area_2d: Area2D = $Bottom_Right_Area2D
@onready var bottom_left_area_2d: Area2D = $Bottom_Left_Area2D
@onready var gui_parent: Control = $GUI_Parent
@onready var tab_container: TabContainer = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer

const min_dimensions: Vector2 = Vector2(10,10)

var dragging_corner: Node = null
var drag_offset: Vector2 = Vector2.ZERO
var menu_tween: Tween
const single_cell_grid_rect: Rect2 = Rect2(Vector2.ONE * 5.0, Vector2.ONE * 10.0)
var zone_type: String = ""

func _ready() -> void:
	set_process(false)
	
	gui_parent.visible = false
	var tab_bar: TabBar = tab_container.get_tab_bar()
	tab_bar.set_tab_title(0,"Can Build Zone")
	tab_bar.set_tab_title(1,"No Build Zone")
	
	polygon = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10),
	]
	
	_update_corner_positions()
	
	await get_tree().process_frame
	if Global.world_scene:
		gui_parent.reparent(Global.world_scene.canvas_layer)
	else:
		print("World scene not found through Global, option window failed to reparent for node:" + "\n" + str(self))

func _process(_delta: float) -> void:
	if dragging_corner:
	#	var new_pos = to_local(get_viewport().get_mouse_position()) + drag_offset
		var new_pos: Vector2 = get_global_mouse_position() + drag_offset
		_drag_corner(dragging_corner, new_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
		dragging_corner = null
		set_process(false)
		snap_to_grid(single_cell_grid_rect)

func _handle_corner_input(corner: Node, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging_corner = corner
				drag_offset = corner.position - to_local(get_global_mouse_position())
				set_process(true)
#			else:
#				dragging_corner = null
#	
#	elif event is InputEventMouseMotion and dragging_corner == corner:
#		var new_pos = to_local(get_global_mouse_position()) + drag_offset
#		_drag_corner(corner, new_pos)

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
	
	polygon = [
		Vector2(x1, y1),
		Vector2(x2, y1),
		Vector2(x2, y2),
		Vector2(x1, y2)
	]
	
	_update_corner_positions()

func _update_corner_positions() -> void:
	var area_offset_from_corner = Vector2(2.5, 2.5)
	
	top_left_area_2d.position = polygon[0] + area_offset_from_corner
	top_right_area_2d.position = polygon[1] + Vector2(-area_offset_from_corner.x, area_offset_from_corner.y)
	bottom_right_area_2d.position = polygon[2] - area_offset_from_corner
	bottom_left_area_2d.position = polygon[3] + Vector2(area_offset_from_corner.x, -area_offset_from_corner.y)

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

func toggle_zone_menu_visible(make_visible: bool) -> void:
	if menu_tween:
		menu_tween.kill()
	menu_tween = get_tree().create_tween()
	menu_tween.pause()
	menu_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if make_visible:
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
	else:
		if not top_left_area_2d.is_connected("input_event", Callable(self, "_on_top_left_area_2d_input_event")):
			top_left_area_2d.connect("input_event", Callable(self, "_on_top_left_area_2d_input_event"))
		if not top_right_area_2d.is_connected("input_event", Callable(self, "_on_top_right_area_2d_input_event")):
			top_right_area_2d.connect("input_event", Callable(self, "_on_top_right_area_2d_input_event"))
		if not bottom_right_area_2d.is_connected("input_event", Callable(self, "_on_bottom_right_area_2d_input_event")):
			bottom_right_area_2d.connect("input_event", Callable(self, "_on_bottom_right_area_2d_input_event"))
		if not bottom_left_area_2d.is_connected("input_event", Callable(self, "_on_bottom_left_area_2d_input_event")):
			bottom_left_area_2d.connect("input_event", Callable(self, "_on_bottom_left_area_2d_input_event"))

func snap_to_grid(grid_rect: Rect2) -> void:
	var cell_pos: Vector2 = grid_rect.position
	var cell_size: Vector2 = grid_rect.size
	
	var new_poly: Array[Vector2] = []
	
	for vertex in polygon:
		# Convert local polygon point to global coordinates
		var global_p = position + vertex
	
		# Convert to grid space
		var grid_position = (global_p - cell_pos) / cell_size
	
		# Snap to nearest integer grid point
		grid_position = grid_position.round()
	
		# Convert back to global space
		var snapped_global = grid_position * cell_size + cell_pos
	
		# Convert back to local polygon coordinates
		var new_local = snapped_global - position
		new_poly.append(new_local)
	
	polygon = new_poly
	_update_corner_positions()

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
