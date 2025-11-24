extends ColorRect

@onready var top_left_resize_handle: Control = $Top_Left_Resize_Handle
@onready var top_right_resize_handle: Control = $Top_Right_Resize_Handle
@onready var bottom_right_resize_handle: Control = $Bottom_Right_Resize_Handle
@onready var bottom_left_resize_handle: Control = $Bottom_Left_Resize_Handle

# Settings menu nodes
@onready var gui_parent: Control = $GUI_Parent
@onready var tab_container: TabContainer = $GUI_Parent/PanelContainer/VBoxContainer/TabContainer

var resizing: bool = false
var zone_type: String = ""
var single_cell_grid_rect: Rect2 = Rect2(Vector2.ONE * 5.0, Vector2.ONE * 10.0)
var menu_tween: Tween

func _ready() -> void:
	gui_parent.visible = false
	gui_parent.reparent(Global.world_scene.canvas_layer)
	var tab_bar: TabBar = tab_container.get_tab_bar()
	tab_bar.set_tab_title(0,"Can Build Zone")
	tab_bar.set_tab_title(1,"No Build Zone")
	global_position = get_parent().get_parent().global_position
	snap_to_grid(single_cell_grid_rect)

func set_zone_type(type: String) -> void:
	match type:
		"can build here":
			color = Color(0.0,0.5,0.7,0.2)
			zone_type = type
			tooltip_text = type
		"no build here":
			color = Color(0.7,0.0,0.0,0.2)
			zone_type = type
			tooltip_text = type
		"trigger":
			color = Color(0.0,0.7,0.5,0.2)
			zone_type = type
			tooltip_text = type

func get_zone_type() -> String:
	return zone_type

func get_zone_rect() -> Rect2: # Use .get_rect() instead of this function
	return get_rect()
	# This function only exists so I don't forget about this line of code

func toggle_lock_state(lock_state: bool) -> void:
	if lock_state:
		top_left_resize_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_right_resize_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_left_resize_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_right_resize_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		top_left_resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		top_right_resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		bottom_left_resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		bottom_right_resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		self.mouse_filter = Control.MOUSE_FILTER_STOP

func snap_to_grid(grid_rect: Rect2) -> void:
	var cell_pos = grid_rect.position
	var cell_size = grid_rect.size
	# Convert rect corners into grid-space
	var top_left = (position - cell_pos) / cell_size
	var bottom_right = (position + size - cell_pos) / cell_size
	# Snap both corners to nearest grid points
	top_left = top_left.round()
	bottom_right = bottom_right.round()
	# Convert back to world-space
	var new_top_left = top_left * cell_size + cell_pos
	var new_bottom_right = bottom_right * cell_size + cell_pos
	position = new_top_left
	size = new_bottom_right - new_top_left

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !gui_parent.visible:
			toggle_zone_menu_visible(true)

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
		Global.world_scene.canvas_layer.layer = 2
		menu_tween.play()
	else:
		menu_tween.tween_property(gui_parent, "scale", Vector2.ZERO, 0.3)
		Global.world_scene.canvas_layer.layer = 1
		menu_tween.play()
		await menu_tween.finished
		gui_parent.visible = false

# Resizing signal functions
func _on_top_left_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		resizing = event.pressed
		if not resizing:
			snap_to_grid(single_cell_grid_rect)
	elif event is InputEventMouseMotion and resizing:
		var drag_vec: Vector2 = event.relative
		drag_vec = size - Vector2(max(size.x - drag_vec.x, custom_minimum_size.x),max(size.y - drag_vec.y, custom_minimum_size.y))
		size -= drag_vec
		position += drag_vec

func _on_top_right_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		resizing = event.pressed
		if not resizing:
			snap_to_grid(single_cell_grid_rect)
	elif event is InputEventMouseMotion and resizing:
		var drag_vec: Vector2 = event.relative
		drag_vec.y = size.y - max(size.y - drag_vec.y, custom_minimum_size.y)
		size += Vector2(drag_vec.x, -drag_vec.y)
		position.y += drag_vec.y

func _on_bottom_right_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		resizing = event.pressed
		if not resizing:
			snap_to_grid(single_cell_grid_rect)
	elif event is InputEventMouseMotion and resizing:
		var drag_vec: Vector2 = event.relative
		size += Vector2(drag_vec.x, drag_vec.y)

func _on_bottom_left_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		resizing = event.pressed
		if not resizing:
			snap_to_grid(single_cell_grid_rect)
	elif event is InputEventMouseMotion and resizing:
		var drag_vec: Vector2 = event.relative
		drag_vec.x = size.x - max(size.x - drag_vec.x, custom_minimum_size.x)
		size += Vector2(-drag_vec.x, drag_vec.y)
		position.x += drag_vec.x

# Signal functions
func _on_cancel_pressed() -> void:
	toggle_zone_menu_visible(false)
