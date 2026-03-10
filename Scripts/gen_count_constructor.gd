extends Control

@onready var target_number: SpinBox = $HBoxContainer/Target_Number
@onready var opperator: OptionButton = $HBoxContainer/Opperator

const trigger_selector_path: String = "res://Scenes/Menus/bool_var_signal_dropdown.tscn"

var previous_bool_status: bool = false

func _ready() -> void:
	var target_number_line_edit = target_number.get_line_edit()
	target_number_line_edit.add_theme_font_size_override("font_size", 30)
	Global.world_scene.connect("generation_itterated", _on_generation_iterated)
	Global.world_scene.connect("clear_zones_called", self_destruct)

func replace_self_with_alternate(_index_of_replacement: int) -> void:
	var parent = get_parent()
	if not (parent is Control):
		return
#	var path = ""
#	match index_of_replacement:
#		2:
#			path = trigger_selector_path
	var instance = load(trigger_selector_path).instantiate()
	parent.add_child(instance)
	queue_free()

func get_bool_string_segment() -> String:
	if opperator.selected == 6: # Revert to variable
		return "false"
	return "(gen_count " + opperator.get_item_text(opperator.selected) + " " + str(int(target_number.value)) + ")"

func get_logic_term_structure_array() -> Array:
	# [object_index, [selection_indexes], [child_A_info], [child_B_info]]
	return [1, [opperator.selected, target_number.value], [null], [null]]

func set_logic_structure(structure_array: Array) -> void:
	if structure_array[0] != 1:
		push_error("set_logic_structure() object type failed to set up correctly" + "\n" + str(structure_array))
		return
	# format is [object_index, [selection_indexes], [child_A_info], [child_B_info]]
	opperator.selected = structure_array[1][0]
	target_number.value = structure_array[1][1]

func get_bool_status() -> bool:
	match opperator.selected:
		0: # ==
			return Global.generation_number == target_number.value
		1: # <=
			return Global.generation_number <= target_number.value
		2: # >=
			return Global.generation_number >= target_number.value
		3: # <
			return Global.generation_number < target_number.value
		4: # >
			return Global.generation_number > target_number.value
		5: # !=
			return Global.generation_number != target_number.value
		_:
			return false

func self_destruct() -> void:
	queue_free()

func _on_generation_iterated() -> void:
	var current_bool_status: bool = get_bool_status()
	if previous_bool_status != current_bool_status:
		Global.world_scene.check_logic_conditions(get_bool_string_segment())
	previous_bool_status = current_bool_status

func _on_opperator_item_selected(index: int) -> void:
	match index:
		6: # Revert to variable
			replace_self_with_alternate(2)
