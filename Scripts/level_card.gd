extends PanelContainer

@onready var level_name_label: Label = $MarginContainer/VBoxContainer/Name
@onready var level_rating_label: Label = $MarginContainer/VBoxContainer/Rating
@onready var lock_symbol: Label = $Lock

func _ready() -> void:
	while not Global.world_scene:
		await get_tree().process_frame
	self.focus_entered.connect(Global.world_scene.UI_play_click)

func set_level_card_info(level_name: String, level_rating: Array, is_locked: bool, level_ID: String) -> void:
	level_name_label.text = level_name
	lock_symbol.visible = is_locked
	set_meta("level_id", level_ID)
	
	var completion_rating_string: String = ""
	for i in level_rating.size(): # Should always be 3
		if level_rating[i]:
			completion_rating_string += "★"
		else:
			completion_rating_string += "☆"
	level_rating_label.text = completion_rating_string
	
	await get_tree().process_frame
	scale_text_to_fit()

func update_level_card_rating(new_level_rating: Array) -> void:
	var completion_rating_string: String = ""
	for i in new_level_rating.size(): # Should always be 3
		if new_level_rating[i]:
			completion_rating_string += "★"
		else:
			completion_rating_string += "☆"
	level_rating_label.text = completion_rating_string

func set_lock_state(is_locked: bool) -> void:
	lock_symbol.visible = is_locked

func scale_text_to_fit(label: Label = level_name_label, min_acceptable_font_size: int = 12, max_acceptable_font_size: int = 256) -> void:
	if min_acceptable_font_size > max_acceptable_font_size:
		label.add_theme_font_size_override("font_size", min_acceptable_font_size)
		return
	
	var font: Font = label.get_theme_font("font")
	for font_size_to_test in range(min_acceptable_font_size, max_acceptable_font_size + 1):
		var total_text_size: Vector2 = font.get_multiline_string_size(
			label.text,
			label.horizontal_alignment,
			label.size.x,
			font_size_to_test,
			label.max_lines_visible,
			TextServer.BREAK_WORD_BOUND | TextServer.BREAK_GRAPHEME_BOUND,
			TextServer.JUSTIFICATION_WORD_BOUND,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL
			)
		if total_text_size.y > label.size.y:
			label.add_theme_font_size_override("font_size", clamp(font_size_to_test - 1, min_acceptable_font_size, max_acceptable_font_size))
			return
	
	# Reaching this code means everything fits at max size
	label.add_theme_font_size_override("font_size", max_acceptable_font_size)
