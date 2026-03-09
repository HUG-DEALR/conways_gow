extends Node2D

@onready var shaft: Line2D = $Shaft
@onready var head: Line2D = $Shaft/Head
@onready var head_area: Area2D = $Shaft/Head_Area
@onready var tail_area: Area2D = $Tail_Area
@onready var body_area: Area2D = $Body_Area
@onready var body_area_shape: CollisionShape2D = $Body_Area/Body_Area_Shape
@onready var head_collision_shape: CollisionShape2D = $Shaft/Head_Area/Head_Collision_Shape
@onready var tail_collision_shape: CollisionShape2D = $Tail_Area/Tail_Collision_Shape
@onready var gui_parent: Control = $GUI_Parent
@onready var weight_spin_box: SpinBox = $GUI_Parent/PanelContainer/VBoxContainer/HBoxContainer3/Weight_Spin_Box
@onready var color_picker_button: ColorPickerButton = $GUI_Parent/PanelContainer/VBoxContainer/HBoxContainer/ColorPickerButton
@onready var behaviour_option: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/Behaviour_Option

var dragging_area: int = 0 # 0=null, 1=tail, 2=body, 3=head
var menu_tween: Tween
var pre_edit_arrow_colour: Color = Color.WHITE
var arrow_colour: Color = Color.WHITE
var pre_edit_arrow_width: float = 5.0
var arrow_width: float = 5.0
var pre_edit_behaviour_option: int = 0

func _ready() -> void:
	set_process(false)
	
	gui_parent.visible = false
	await get_tree().process_frame
	if Global.world_scene:
		gui_parent.reparent(Global.world_scene.canvas_layer)
		Global.world_scene.update_or_add_hint_arrow_info(self)
		Global.world_scene.connect("clear_arrows_called", self_destruct)
	else:
		print("World scene not found through Global, option window failed to reparent for node:" + "\n" + str(self))

func _process(_delta: float) -> void:
	match dragging_area:
		0: # Nothing
			pass
		1: # Tail
			reposition_tail(get_global_mouse_position())
		2: # Body
			pass
		3: # Head
			reposition_head(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and !event.pressed:
		set_process(false)
		dragging_area = 0
		Global.world_scene.update_or_add_hint_arrow_info(self)

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

func toggle_arrow_menu_visible(make_visible: bool) -> void:
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
		await menu_tween.finished
		gui_parent._on_drag_button_button_up()
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
	body_area_shape.shape.size.x = max(target_position.length() - (arrow_width * 2.0), 5.0)

func get_arrow_info() -> Array:
	# Format is [Colour, width, option_int, V2(Tail), V2(Head)]
	return [arrow_colour, arrow_width, behaviour_option.selected, global_position, head.global_position]

func set_arrow_info(info_array: Array) -> void:
	_on_color_picker_button_color_changed(info_array[0])
	_on_weight_spin_box_value_changed(info_array[1])
	behaviour_option.selected = info_array[2]
	if behaviour_option.selected == 1: # Hide after gen 0
		Global.world_scene.connect("generation_itterated", _on_generation_iterated)
	else:
		if Global.world_scene.is_connected("generation_itterated", _on_generation_iterated):
			Global.world_scene.disconnect("generation_itterated", _on_generation_iterated)
	reposition_tail(info_array[3])
	reposition_head(info_array[4])
	
	pre_edit_arrow_width = arrow_width
	pre_edit_arrow_colour = arrow_colour
	pre_edit_behaviour_option = behaviour_option.selected

func toggle_lock_state(lock_state: bool) -> void:
	if lock_state:
		if behaviour_option.selected == 2: # Don't show
			self.visible = false
		
		if head_area.is_connected("input_event", Callable(self, "_on_head_area_input_event")):
			head_area.disconnect("input_event", Callable(self, "_on_head_area_input_event"))
		if tail_area.is_connected("input_event", Callable(self, "_on_tail_area_input_event")):
			tail_area.disconnect("input_event", Callable(self, "_on_tail_area_input_event"))
		if body_area.is_connected("input_event", Callable(self, "_on_body_area_input_event")):
			body_area.disconnect("input_event", Callable(self, "_on_body_area_input_event"))
	else:
		if behaviour_option.selected == 2: # Don't show
			self.visible = true
		
		if not head_area.is_connected("input_event", Callable(self, "_on_head_area_input_event")):
			head_area.connect("input_event", Callable(self, "_on_head_area_input_event"))
		if not tail_area.is_connected("input_event", Callable(self, "_on_tail_area_input_event")):
			tail_area.connect("input_event", Callable(self, "_on_tail_area_input_event"))
		if not body_area.is_connected("input_event", Callable(self, "_on_body_area_input_event")):
			body_area.connect("input_event", Callable(self, "_on_body_area_input_event"))

func self_destruct() -> void:
	toggle_arrow_menu_visible(false)
	if gui_parent.visible:
		await gui_parent.visibility_changed
	gui_parent.queue_free()
	Global.world_scene.remove_hint_arrow_from_lists(self)
	menu_tween.kill()
	self.queue_free()

func _on_generation_iterated() -> void:
	visible = false
	toggle_lock_state(false)

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
						toggle_arrow_menu_visible(true)

func _on_weight_spin_box_value_changed(value: float) -> void:
	arrow_width = value
	shaft.width = value
	head.width = value
	var area_width: float = max(value, 2.0)
	body_area_shape.shape.size.x = max(shaft.position.length() - (area_width * 2.0), 5.0)
	body_area_shape.shape.size.y = area_width
	head_collision_shape.shape.radius = area_width
	tail_collision_shape.shape.radius = area_width

func _on_color_picker_button_color_changed(color: Color) -> void:
	arrow_colour = color
	shaft.default_color = color
	head.default_color = color

func _on_cancel_pressed() -> void:
	toggle_arrow_menu_visible(false)
	_on_weight_spin_box_value_changed(pre_edit_arrow_width)
	weight_spin_box.value = pre_edit_arrow_width
	_on_color_picker_button_color_changed(pre_edit_arrow_colour)
	color_picker_button.color = pre_edit_arrow_colour
	behaviour_option.selected = pre_edit_behaviour_option

func _on_apply_pressed() -> void:
	if behaviour_option.selected == 4:
		self_destruct()
	toggle_arrow_menu_visible(false)
	pre_edit_arrow_width = arrow_width
	pre_edit_arrow_colour = arrow_colour
	pre_edit_behaviour_option = behaviour_option.selected
	
	# This is a suboptimal logic structure, but given the small scale, it is preferable
	if behaviour_option.selected == 1: # Hide after gen 0
		Global.world_scene.connect("generation_itterated", _on_generation_iterated)
	else:
		if Global.world_scene.is_connected("generation_itterated", _on_generation_iterated):
			Global.world_scene.disconnect("generation_itterated", _on_generation_iterated)
	if behaviour_option.selected == 2: # Don't Show
		modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		modulate = Color.WHITE
	if behaviour_option.selected == 3: # Show on hint
		pass
	#	Global.world_scene.connect("hint_button_pressed", _on_hint_button_pressed)
	else:
		pass
	#	if Global.world_scene.is_connected("hint_button_pressed", _on_hint_button_pressed):
	#		Global.world_scene.disconnect("hint_button_pressed", _on_hint_button_pressed)
	
	Global.world_scene.update_or_add_hint_arrow_info(self)
