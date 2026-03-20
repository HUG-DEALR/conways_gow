extends Sprite2D

@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sub_viewport: SubViewport = $SubViewport
@onready var panel_container: PanelContainer = $SubViewport/Control/PanelContainer
@onready var gui_parent: Control = $GUI_Parent
@onready var bheaviour_option: OptionButton = $GUI_Parent/PanelContainer/VBoxContainer/Bheaviour_Option
@onready var display_text: TextEdit = $SubViewport/Control/PanelContainer/Display_Text
@onready var menu_text: TextEdit = $GUI_Parent/PanelContainer/VBoxContainer/Menu_Text

var menu_tween: Tween
var draggin_display: bool = false
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_mouse_over():
					draggin_display = true
					drag_offset = global_position - get_global_mouse_position()
					get_viewport().set_input_as_handled()
			else:
				if draggin_display:
					draggin_display = false
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and draggin_display:
		global_position = get_global_mouse_position() + drag_offset

func is_mouse_over() -> bool:
	if texture == null:
		return false
	var rect = Rect2(-texture.get_size() / 2.0, texture.get_size())
	var local_mouse = to_local(get_global_mouse_position())
	return rect.has_point(local_mouse)

func update_viewport_size() -> void:
	sub_viewport.size = panel_container.get_combined_minimum_size() + Vector2.ONE * 130.0

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

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toggle_menu_visible(true)

func _on_generations_reset_to_0() -> void:
	if Global.world_scene.current_sub_menu == "play":
		if bheaviour_option.selected == 1: # Hide after gen 0
			visible = true
		elif bheaviour_option.selected == 3: # Show on hint
			visible = false

func _on_menu_text_text_changed() -> void:
	display_text.text = menu_text.text
	collision_shape_2d.shape.size = panel_container.size
	update_viewport_size()

func _on_apply_pressed() -> void:
	pre_edit_display_text = display_text.text
	toggle_menu_visible(false)

func _on_cancel_pressed() -> void:
	display_text.text = pre_edit_display_text
	toggle_menu_visible(false)
