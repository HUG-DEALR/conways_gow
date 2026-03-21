extends Sprite2D

@onready var body_collision_shape_2d: CollisionShape2D = $Area2D/Body_CollisionShape2D
@onready var right_border_collision_shape_2d: CollisionShape2D = $Area2D/Right_Border_CollisionShape2D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var panel_container: PanelContainer = $SubViewport/Control/PanelContainer
@onready var gui_parent: Control = $GUI_Parent
@onready var bheaviour_option: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/Bheaviour_Option
@onready var display_text: TextEdit = $SubViewport/Control/PanelContainer/Display_Text
@onready var menu_text: TextEdit = $GUI_Parent/PanelContainer/VBoxContainer/Menu_Text

var menu_tween: Tween
var draggin_display: bool = false
var resizing: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var pre_edit_display_text: String = ""

func _ready() -> void:
	gui_parent.visible = false
	await get_tree().process_frame
	if Global.world_scene:
		gui_parent.reparent(Global.world_scene.canvas_layer)
	#	Global.world_scene.update_or_add_hint_arrow_info(self)
	#	Global.world_scene.connect("clear_arrows_called", self_destruct)
	else:
		print("World scene not found through Global, option window failed to reparent for node:" + "\n" + str(self))
	Global.generations_reset_to_0.connect(_on_generations_reset_to_0)
	_on_generations_reset_to_0()
	update_viewport_size()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if draggin_display:
			global_position = get_global_mouse_position() + drag_offset
		elif resizing:
			resize_wdith(-70.0 + (to_local(get_global_mouse_position()).x)/scale.x)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if draggin_display or resizing:
				draggin_display = false
				resizing = false
				get_viewport().set_input_as_handled()

func resize_wdith(target_width: float) -> void:
	target_width = max(target_width, display_text.custom_minimum_size.x)
	
	var display_text_previous_center: Vector2 = display_text.position + (display_text.size/2.0)
	display_text.size.x = target_width
	display_text.position = display_text_previous_center - (display_text.size/2.0)
	
	var panel_container_previous_center: Vector2 = panel_container.position + (panel_container.size/2.0)
	panel_container.size = display_text.size + Vector2.ONE * 40.0
	panel_container.position = panel_container_previous_center - (panel_container.size/2.0)
	
	body_collision_shape_2d.shape.size.x = panel_container.size.x + 30.0
	right_border_collision_shape_2d.position.x = (panel_container.size.x + 30.0)/2.0
	update_viewport_size()

func update_viewport_size() -> void:
	sub_viewport.size = panel_container.size + Vector2.ONE * 130.0

func toggle_menu_visible(set_to_expand: bool) -> void:
	if set_to_expand and gui_parent.visible:
		return
	if menu_tween:
		menu_tween.kill()
	menu_tween = get_tree().create_tween()
	menu_tween.pause()
	menu_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	gui_parent.pivot_offset = get_viewport().get_canvas_transform() * (global_position) - gui_parent.position
	if set_to_expand:
		pre_edit_display_text = display_text.text
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

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_menu_visible(true)
			get_viewport().set_input_as_handled()
			sub_viewport.set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if shape_idx == 0: # main body
				draggin_display = true
				drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
				sub_viewport.set_input_as_handled()
			
			elif shape_idx == 1: # right border
				resizing = true
				drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
				sub_viewport.set_input_as_handled()

func _on_generations_reset_to_0() -> void:
	if Global.world_scene.current_sub_menu == "play":
		if bheaviour_option.selected == 1: # Hide after gen 0
			visible = true
		elif bheaviour_option.selected == 3: # Show on hint
			visible = false

func _on_menu_text_text_changed() -> void:
	display_text.text = menu_text.text
	body_collision_shape_2d.shape.size = panel_container.size + Vector2(30.0,50.0)
	right_border_collision_shape_2d.shape.size.y = body_collision_shape_2d.shape.size.y
	update_viewport_size()

func _on_apply_pressed() -> void:
	pre_edit_display_text = display_text.text
	toggle_menu_visible(false)
	body_collision_shape_2d.shape.size = panel_container.size + Vector2(30.0,50.0)
	right_border_collision_shape_2d.shape.size.y = body_collision_shape_2d.shape.size.y
	update_viewport_size()

func _on_cancel_pressed() -> void:
	display_text.text = pre_edit_display_text
	toggle_menu_visible(false)
	body_collision_shape_2d.shape.size = panel_container.size + Vector2(30.0,50.0)
	right_border_collision_shape_2d.shape.size.y = body_collision_shape_2d.shape.size.y
	update_viewport_size()
