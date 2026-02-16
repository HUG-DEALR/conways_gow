extends Node2D

@onready var shaft: Line2D = $Shaft
@onready var head: Line2D = $Shaft/Head
@onready var head_area: Area2D = $Shaft/Head_Area
@onready var tail_area: Area2D = $Tail_Area
@onready var body_area: Area2D = $Body_Area
@onready var body_area_shape: CollisionShape2D = $Body_Area/Body_Area_Shape
@onready var gui_parent: Control = $GUI_Parent

var dragging_area: int = 0 # 0=null, 1=tail, 2=body, 3=head
var menu_tween: Tween

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	match dragging_area:
		0: # Nothing
			pass
		1: # Tail
			reposition_tail(get_viewport().get_mouse_position())
		2: # Body
			pass
		3: # Head
			reposition_head(get_viewport().get_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and !event.pressed:
		set_process(false)
		dragging_area = 0
#		snap_to_grid(single_cell_grid_rect)

func _handle_area_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				match dragging_area:
					0: # Nothing
						pass
					1: # Tail
						set_process(true)
					2: # Body
						pass
					3: # Head
						set_process(true)

func toggle_zone_menu_visible(make_visible: bool) -> void:
	if menu_tween:
		menu_tween.kill()
	menu_tween = get_tree().create_tween()
	menu_tween.pause()
	menu_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	gui_parent.pivot_offset = get_viewport().get_canvas_transform() * (global_position) - gui_parent.position
	if make_visible:
#		update_menu_options()
		menu_tween.tween_property(gui_parent, "scale", Vector2.ZERO, 0.0)
		menu_tween.tween_property(gui_parent, "scale", Vector2.ONE, 0.3)
		gui_parent.visible = true
		menu_tween.play()
	else:
		menu_tween.tween_property(gui_parent, "scale", Vector2.ZERO, 0.3)
		menu_tween.play()
		await menu_tween.finished
		gui_parent.visible = false

func reposition_tail(target_position: Vector2) -> void:
	var current_tip_position: Vector2 = head.global_position
	global_position = target_position
	reposition_head(current_tip_position)

func reposition_head(target_position: Vector2) -> void:
	target_position = target_position - global_position
	shaft.position = target_position
	shaft.points[1] = -target_position
	head.rotation = atan2(target_position.y, target_position.x)
	body_area.position = target_position/2.0
	body_area.rotation = head.rotation
	body_area_shape.shape.size.x = max(target_position.length() - 10.0, 5.0)

func _on_tail_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	dragging_area = 1
	_handle_area_input(event)

func _on_head_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	dragging_area = 3
	_handle_area_input(event)

func _on_body_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if dragging_area == 0 and !gui_parent.visible:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					if event.pressed:
						toggle_zone_menu_visible(true)

func _on_cancel_pressed() -> void:
	toggle_zone_menu_visible(false)
