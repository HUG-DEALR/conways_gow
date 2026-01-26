extends OptionButton

const bool_constructor_path: String = "res://Scenes/Menus/bool_constructor.tscn"
const gen_count_constructor_path: String = "res://Scenes/Menus/gen_count_constructor.tscn"

var target_trigger # This can be a node or a string

func _ready() -> void:
	await get_tree().process_frame
	refresh_trigger_list()

func get_bool_string_segment() -> String:
	if target_trigger is Control:
		return target_trigger.get_bool_string_segment()
	elif target_trigger is String:
		return target_trigger
	else:
		return "false"

func replace_self_with_alternate(path: String) -> void:
	var parent = get_parent()
	if not (parent is Control):
		return
	var instance = load(path).instantiate()
	parent.add_child(instance)
	queue_free()

func refresh_trigger_list() -> void:
	while item_count > 5:
		remove_item(item_count - 1) # Using index -1 throws an error
	
	var triggers_dict: Dictionary = Global.world_scene.level_info_dict["trigger_zones"]
	for trigger_node in triggers_dict.keys():
		add_item(triggers_dict[trigger_node][3], 5)

func _on_item_selected(index: int) -> void:
	match index:
		0: # New logic gate
			replace_self_with_alternate(bool_constructor_path)
		1: # Gen Count
			replace_self_with_alternate(gen_count_constructor_path)
		2: # True
			target_trigger = "true"
		3: # False
			target_trigger = "false"
		4: # Seperator
			pass
			# This code is unreachable
		_: # trigger
			pass

func _on_pressed() -> void:
	refresh_trigger_list()
