extends Polygon2D

@onready var top_left_area_2d: Area2D = $Top_Left_Area2D
@onready var top_right_area_2d: Area2D = $Top_Right_Area2D
@onready var bottom_right_area_2d: Area2D = $Bottom_Right_Area2D
@onready var bottom_left_area_2d: Area2D = $Bottom_Left_Area2D

const min_dimensions: Vector2 = Vector2(10,10)

var dragging_corner: Node = null
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(false)
	polygon = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10),
	]
	
	_update_corner_positions()

func _process(_delta: float) -> void:
	if dragging_corner:
		var new_pos = to_local(get_global_mouse_position()) + drag_offset
		_drag_corner(dragging_corner, new_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
		dragging_corner = null
		set_process(false)

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

func _on_top_left_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(top_left_area_2d, event)

func _on_top_right_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(top_right_area_2d, event)

func _on_bottom_right_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(bottom_right_area_2d, event)

func _on_bottom_left_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_corner_input(bottom_left_area_2d, event)
