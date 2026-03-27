extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@onready var center_collision_shape_2d: CollisionShape2D = $Area2D/Center_CollisionShape2D
@onready var right_border_collision_shape_2d: CollisionShape2D = $Area2D/Right_Border_CollisionShape2D
@onready var left_border_collision_shape_2d: CollisionShape2D = $Area2D/Left_Border_CollisionShape2D
@onready var top_border_collision_shape_2d: CollisionShape2D = $Area2D/Top_Border_CollisionShape2D
@onready var bottom_border_collision_shape_2d: CollisionShape2D = $Area2D/Bottom_Border_CollisionShape2D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var panel_container: PanelContainer = $SubViewport/Control/PanelContainer
@onready var gui_parent: Control = $GUI_Parent
@onready var behaviour_option: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/Behaviour_Option
@onready var display_text: TextEdit = $SubViewport/Control/PanelContainer/Display_Text
@onready var menu_text: TextEdit = $GUI_Parent/PanelContainer/VBoxContainer/Menu_Text
@onready var scale_h_slider: HSlider = $GUI_Parent/PanelContainer/VBoxContainer/Scale_HSlider
@onready var scale_label: Label = $GUI_Parent/PanelContainer/VBoxContainer/scale_hbox/Scale_Label
@onready var drag_button: Button = $GUI_Parent/Drag_Button
@onready var menu_panel_container: PanelContainer = $GUI_Parent/PanelContainer

var menu_tween: Tween
var draggin_display: bool = false
var resizing: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var pre_edit_display_text: String = ""
var pre_edit_behaviour_option: int = 0
var pre_edit_scale: float = 0.5

func _ready() -> void:
	gui_parent.visible = false
	await get_tree().process_frame
	if Global.world_scene:
		gui_parent.reparent(Global.world_scene.canvas_layer)
		gui_parent.mouse_filter = Control.MOUSE_FILTER_PASS
		gui_parent.global_position = get_viewport_rect().size * 0.5
		Global.world_scene.update_or_add_hint_textbox_info(self)
		Global.world_scene.connect("clear_textboxes_called", self_destruct)
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
			resize_display(-70.0 + (to_local(get_global_mouse_position()).x)/scale.x)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			if draggin_display or resizing:
				draggin_display = false
				resizing = false
				get_viewport().set_input_as_handled()
				Global.world_scene.update_or_add_hint_textbox_info(self)

func _unhandled_input(event: InputEvent) -> void:
	if behaviour_option.selected == 3: # Show on hint
		if Global.world_scene.current_sub_menu == "play":
			if event is InputEventMouseButton and event.pressed:
				self.visible = false

func resize_display(target_width: float = display_text.size.x) -> void:
	# (right and left) and (top and bottom) share collision shape resource;
	# only one of each pair need to be set
	target_width = max(target_width, display_text.custom_minimum_size.x)
	var total_text_size: Vector2 = display_text.get_theme_font("font").get_multiline_string_size(
		display_text.text,
		HORIZONTAL_ALIGNMENT_LEFT, # TextEdit can only be left alignedsf
		target_width,
		display_text.get_theme_font_size("font_size"),
		-1, # TextEdit max lines visible is always -1
		TextServer.BREAK_WORD_BOUND | TextServer.BREAK_GRAPHEME_BOUND,
		TextServer.JUSTIFICATION_WORD_BOUND,
		TextServer.DIRECTION_AUTO,
		TextServer.ORIENTATION_HORIZONTAL
		)
	total_text_size.x = target_width
	
	var display_text_previous_center: Vector2 = display_text.position + (display_text.size/2.0)
	display_text.size = total_text_size
	display_text.position = display_text_previous_center - (display_text.size/2.0)
	
	var panel_container_previous_center: Vector2 = panel_container.position + (panel_container.size/2.0)
	panel_container.size = display_text.size + Vector2.ONE * 40.0
	panel_container.position = panel_container_previous_center - (panel_container.size/2.0)
	
	right_border_collision_shape_2d.position.x = (panel_container.size.x + 30.0)/2.0
	left_border_collision_shape_2d.position.x = -1.0 * right_border_collision_shape_2d.position.x
	top_border_collision_shape_2d.shape.size.x = panel_container.size.x + 10.0
	center_collision_shape_2d.shape.size.x = top_border_collision_shape_2d.shape.size.x
	
	right_border_collision_shape_2d.shape.size.y = panel_container.size.y + 50.0
	bottom_border_collision_shape_2d.position.y = (panel_container.size.y + 30.0) * 0.5
	top_border_collision_shape_2d.position.y = -1.0 * bottom_border_collision_shape_2d.position.y
	center_collision_shape_2d.shape.size.y = right_border_collision_shape_2d.shape.size.y
	
	update_viewport_size()
	Global.world_scene.update_or_add_hint_textbox_info(self)

func update_viewport_size() -> void:
	sub_viewport.size = panel_container.size + Vector2.ONE * 130.0

func toggle_menu_visible(set_to_expand: bool) -> void:
	if set_to_expand == gui_parent.visible:
		return
	if menu_tween:
		menu_tween.kill()
	menu_tween = get_tree().create_tween()
	menu_tween.pause()
	menu_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	gui_parent.pivot_offset = get_viewport().get_canvas_transform() * (global_position) - gui_parent.position
	if set_to_expand:
		pre_edit_display_text = display_text.text
		pre_edit_behaviour_option = behaviour_option.selected
		pre_edit_scale = scale.x
		drag_button.size = Vector2.ONE * 50.0 + menu_panel_container.size
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

func self_destruct() -> void:
	toggle_menu_visible(false)
	if gui_parent.visible:
		await gui_parent.visibility_changed
	gui_parent.queue_free()
	Global.world_scene.remove_hint_textbox_from_lists(self)
	if menu_tween:
		menu_tween.kill()
	self.queue_free()

func get_textbox_info() -> Array:
	# Format is [position, width, behaviour index, text]
	return [global_position, display_text.size.x, behaviour_option.selected, menu_text.text]

func set_textbox_info(textbox_info: Array) -> void:
	global_position = textbox_info[0]
	resize_display(textbox_info[1])
	pre_edit_behaviour_option = textbox_info[2]
	behaviour_option.selected = pre_edit_behaviour_option
	configure_hide_show_behaviour()
	pre_edit_display_text = textbox_info[3]
	display_text.text = pre_edit_display_text
	menu_text.text = pre_edit_display_text

func configure_hide_show_behaviour() -> void:
	# This is a suboptimal logic structure, but given the small scale, it is preferable
	if behaviour_option.selected == 1: # Hide after gen 0
		if not Global.world_scene.is_connected("generation_itterated", _on_generation_iterated):
			Global.world_scene.connect("generation_itterated", _on_generation_iterated)
	#	if not Global.is_connected("generations_reset_to_0", _on_generations_reset_to_0):
	#		Global.connect("generations_reset_to_0", _on_generations_reset_to_0)
	else:
		if Global.world_scene.is_connected("generation_itterated", _on_generation_iterated):
			Global.world_scene.disconnect("generation_itterated", _on_generation_iterated)
	#	if Global.is_connected("generations_reset_to_0", _on_generations_reset_to_0):
	#		Global.disconnect("generations_reset_to_0", _on_generations_reset_to_0)
	if behaviour_option.selected == 2: # Don't Show
		modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		modulate = Color.WHITE
	if behaviour_option.selected == 3: # Show on hint
		if not Global.world_scene.is_connected("hint_button_pressed", _on_hint_button_pressed):
			Global.world_scene.connect("hint_button_pressed", _on_hint_button_pressed)
	else:
		if Global.world_scene.is_connected("hint_button_pressed", _on_hint_button_pressed):
			Global.world_scene.disconnect("hint_button_pressed", _on_hint_button_pressed)
	if behaviour_option.selected == 4: # Delete
		self_destruct()

func toggle_lock_state(lock_state: bool) -> void:
	if lock_state:
		if behaviour_option.selected == 2: # Don't show
			self.visible = false
		
		if area_2d.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area_2d.disconnect("input_event", Callable(self, "_on_area_2d_input_event"))
	else:
		if behaviour_option.selected == 2: # Don't show
			self.visible = true
		
		if not area_2d.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area_2d.connect("input_event", Callable(self, "_on_area_2d_input_event"))

func _on_generation_iterated() -> void:
	if Global.world_scene.current_sub_menu == "play":
		visible = false
		toggle_menu_visible(false)

func _on_hint_button_pressed() -> void:
	# Assumes that the "show on hint" option is selected
	self.visible = true

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				match shape_idx:
					4: # body center
						toggle_menu_visible(true)
					0: # right border
						resizing = true
						drag_offset = global_position - get_global_mouse_position()
					_: # all other border
						draggin_display = true
						drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()

func _on_generations_reset_to_0() -> void:
	if Global.world_scene.current_sub_menu == "play":
		if behaviour_option.selected == 1: # Hide after gen 0
			visible = true
		elif behaviour_option.selected == 3: # Show on hint
			visible = false

func _on_menu_text_text_changed() -> void:
	display_text.text = menu_text.text
	resize_display()
	update_viewport_size()

func _on_apply_pressed() -> void:
	pre_edit_display_text = display_text.text
	pre_edit_behaviour_option = behaviour_option.selected
	pre_edit_scale = scale.x
	toggle_menu_visible(false)
	resize_display()
	update_viewport_size()
	configure_hide_show_behaviour()
	Global.world_scene.update_or_add_hint_textbox_info(self)

func _on_cancel_pressed() -> void:
	display_text.text = pre_edit_display_text
	behaviour_option.selected = pre_edit_behaviour_option
	scale_label.text = str(pre_edit_scale)
	scale_h_slider.value = pre_edit_scale
	scale = Vector2.ONE * pre_edit_scale
	toggle_menu_visible(false)
	resize_display()
	update_viewport_size()

func _on_scale_h_slider_value_changed(value: float) -> void:
	scale_label.text = str(value)
	scale = Vector2.ONE * value
