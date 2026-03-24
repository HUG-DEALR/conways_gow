@tool
extends EditorScript

var root_node: Sprite2D
var display_text: TextEdit
var panel_container: PanelContainer
var center_collision_shape_2d: CollisionShape2D
var right_border_collision_shape_2d: CollisionShape2D
var left_border_collision_shape_2d: CollisionShape2D
var top_border_collision_shape_2d: CollisionShape2D
var bottom_border_collision_shape_2d: CollisionShape2D
var sub_viewport: SubViewport

func _run() -> void:
	print("running tool script")
	root_node = EditorInterface.get_edited_scene_root()
	display_text = root_node.get_node("SubViewport/Control/PanelContainer/Display_Text")
	panel_container = root_node.get_node("SubViewport/Control/PanelContainer")
	center_collision_shape_2d = root_node.get_node("Area2D/Center_CollisionShape2D")
	right_border_collision_shape_2d = root_node.get_node("Area2D/Right_Border_CollisionShape2D")
	left_border_collision_shape_2d = root_node.get_node("Area2D/Left_Border_CollisionShape2D")
	top_border_collision_shape_2d = root_node.get_node("Area2D/Top_Border_CollisionShape2D")
	bottom_border_collision_shape_2d = root_node.get_node("Area2D/Bottom_Border_CollisionShape2D")
	sub_viewport = root_node.get_node("SubViewport")
	resize_display()

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
	
	sub_viewport.size = panel_container.size + Vector2.ONE * 130.0
