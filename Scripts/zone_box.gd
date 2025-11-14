extends Control

var dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			start_pos = event.position
			current_pos = start_pos
			queue_redraw()
		else:
			dragging = false
			queue_redraw()
			# Selection finished (emit signal if needed)
	elif event is InputEventMouseMotion and dragging:
		current_pos = event.position
		queue_redraw()

func _draw() -> void:
	if dragging:
		var rect = Rect2(start_pos, current_pos - start_pos)
		draw_rect(rect.abs(), Color(0, 0.5, 1, 0.3))     # fill
		draw_rect(rect.abs(), Color(0, 0.5, 1, 1), 2.0)  # outline
