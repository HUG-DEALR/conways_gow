extends OptionButton

const bool_constructor_path: String = "res://Scenes/Constructors/bool_constructor.tscn"
const gen_count_constructor_path: String = "res://Scenes/Constructors/gen_count_constructor.tscn"

var target_trigger # This can be a node or a string

func _ready() -> void:
	await get_tree().process_frame
	refresh_trigger_list()
	Global.world_scene.clear_logic_elements_called.connect(queue_free)

func get_bool_string_segment() -> String:
	if target_trigger is Control:
		return target_trigger.get_bool_string_segment()
	elif target_trigger is String:
		return target_trigger
	else:
		return "false"

func get_logic_term_structure_array() -> Array:
	# [object_index, [selection_indexes], [child_A_info], [child_B_info]]
	return [2, [get_bool_string_segment()], [null], [null]]

func set_logic_structure(structure_array: Array) -> void:
	if structure_array[0] != 2:
		push_error("set_logic_structure() object type failed to set up correctly" + "\n" + str(structure_array))
		return
	# format is [object_index, [selection_indexes], [child_A_info], [child_B_info]]
	target_trigger = structure_array[1][0]
	refresh_trigger_list()
	match target_trigger:
		"true":
			select(2)
		"false":
			select(3)
		_: # A trigger identifier
			if item_count > 5:
				for item_index in range(5, item_count):
					if target_trigger == get_item_text(item_index):
						select(item_index)
						break

func replace_self_with_alternate(index_of_replacement: int) -> void:
	var parent = get_parent()
	if not (parent is Control):
		return
	var path = ""
	match index_of_replacement:
		0:
			path = bool_constructor_path
		1:
			path = gen_count_constructor_path
		_:
			return
	var instance = load(path).instantiate()
	parent.add_child(instance)
	queue_free()

func refresh_trigger_list() -> void:
	while item_count > 5:
		remove_item(item_count - 1) # Using index -1 throws an error
	
	var triggers_dict: Dictionary = Global.world_scene.level_info_dict["trigger_zones"]
	for trigger_node in triggers_dict.keys():
		add_item(triggers_dict[trigger_node][4], 5)

func _on_item_selected(index: int) -> void:
	match index:
		0: # New logic gate
			replace_self_with_alternate(0)
		1: # Gen Count
			replace_self_with_alternate(1)
		2: # True
			target_trigger = "true"
		3: # False
			target_trigger = "false"
		4: # Seperator
			pass
			# This code is unreachable
		_: # trigger identifiers
			target_trigger = get_item_text(index)

func _on_pressed() -> void:
	refresh_trigger_list()
