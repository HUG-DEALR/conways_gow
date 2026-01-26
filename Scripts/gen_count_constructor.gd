extends Control

@onready var target_number: SpinBox = $HBoxContainer/Target_Number
@onready var opperator: OptionButton = $HBoxContainer/Opperator

const trigger_selector_path: String = "res://Scenes/Menus/bool_var_signal_dropdown.tscn"

func _ready() -> void:
	var target_number_line_edit = target_number.get_line_edit()
	target_number_line_edit.add_theme_font_size_override("font_size", 30)

func replace_self_with_alternate(path: String) -> void:
	var parent = get_parent()
	if not (parent is Control):
		return
	var instance = load(path).instantiate()
	parent.add_child(instance)
	queue_free()

func get_bool_string_segment() -> String:
	if opperator.selected == 6: # Revert to variable
		return "false"
	return "(gen_count " + opperator.get_item_text(opperator.selected) + " " + str(int(target_number.value)) + ")"

func _on_opperator_item_selected(index: int) -> void:
	match index:
		6: # Revert to variable
			replace_self_with_alternate(trigger_selector_path)
