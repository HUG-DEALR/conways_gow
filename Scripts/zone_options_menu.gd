extends Control

@onready var panel_container: PanelContainer = $PanelContainer

var glide_tween: Tween
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	position = get_global_mouse_position() - drag_offset

func clamp_to_screen() -> void:
	# Get the screen rectangle
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	
	# Get this Control's global rect
	var rect: Rect2 = get_global_rect()
	
	var new_pos: Vector2 = global_position
	
	# Clamp X
	if rect.position.x < screen_rect.position.x:
		new_pos.x = screen_rect.position.x
	elif rect.position.x + rect.size.x > screen_rect.position.x + screen_rect.size.x:
		new_pos.x = screen_rect.position.x + screen_rect.size.x - rect.size.x
	
	# Clamp Y
	if rect.position.y < screen_rect.position.y:
		new_pos.y = screen_rect.position.y
	elif rect.position.y + rect.size.y > screen_rect.position.y + screen_rect.size.y:
		new_pos.y = screen_rect.position.y + screen_rect.size.y - rect.size.y
	
	global_position = new_pos

func _on_drag_button_button_down() -> void:
	dragging = true
	drag_offset = get_global_mouse_position() - position
	set_process(true)
	if glide_tween:
		glide_tween.pause()

func _on_drag_button_button_up() -> void:
	dragging = false
	set_process(false)
	var screen_overshoot: Vector2 = Global.get_offset_to_be_fully_visible(panel_container)
	if screen_overshoot.length() > 0.0:
		if glide_tween:
			glide_tween.kill()
		glide_tween = get_tree().create_tween()
		glide_tween.pause()
		glide_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		glide_tween.tween_property(self, "position", position + screen_overshoot, 0.5)
		glide_tween.play()
