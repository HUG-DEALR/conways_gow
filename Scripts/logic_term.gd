extends ScrollContainer

@onready var option_button_output: OptionButton = $HBoxContainer/OptionButton_Output
@onready var h_box_container: HBoxContainer = $HBoxContainer

var entry_exit_tween: Tween

func _ready() -> void:
	entry_exit_animation(true)
	await get_tree().process_frame
	if get_index() == 0:
		option_button_output.get_popup().set_item_disabled(7, true)

func get_bool_info() -> Array:
	var outcome_string: String = ""
	match option_button_output.selected:
		0: # Victory
			outcome_string = "victory"
		1: # Defeat
			outcome_string = "defeat"
		2: # ★☆☆
			outcome_string = "star_1"
		3: # ☆★☆
			outcome_string = "star_2"
		4: # ☆☆★
			outcome_string = "star_3"
		5: # ★★☆
			outcome_string = "star_1_2"
		6: # ★★★
			outcome_string = "star_1_2_3"
		7: # Delete self
			return ["",""] # This should never trigger
	var bool_string: String = h_box_container.get_child(-1).get_bool_string_segment()
	return [outcome_string, bool_string]

func entry_exit_animation(entering: bool) -> void:
	if entry_exit_tween:
		entry_exit_tween.kill()
	entry_exit_tween = create_tween()
	entry_exit_tween.pause()
	entry_exit_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if entering:
		entry_exit_tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.0)
		entry_exit_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
		entry_exit_tween.play()
	else:
		entry_exit_tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.2)
		entry_exit_tween.play()
		await entry_exit_tween.finished
		queue_free()

func _on_output_item_selected(index: int) -> void:
	match index:
		7: # Delete term
			if get_index() != 0:
				entry_exit_animation(false)
			else: # Is first child and should not be deleted
				option_button_output.select(-1)
				option_button_output.get_popup().set_item_disabled(7, true)
