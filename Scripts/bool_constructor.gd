extends Control

@onready var signal_a_host: PanelContainer = $HBoxContainer/Signal_A_Host
@onready var signal_b_host: PanelContainer = $HBoxContainer/Signal_B_Host
@onready var logic_gate: OptionButton = $HBoxContainer/Logic_Gate

const trigger_selector_path: String = "res://Scenes/Menus/bool_var_signal_dropdown.tscn"

func get_bool_string_segment() -> String:
	var bool_A: String = signal_a_host.get_child(-1).get_bool_string_segment()
	var bool_B: String = signal_b_host.get_child(-1).get_bool_string_segment()
	match logic_gate.selected:
		0: # And
			return "(" + bool_A + " and " + bool_B + ")"
		1: # Or
			return "(" + bool_A + " or " + bool_B + ")"
		2: # Not
			return "(" + " not " + bool_B + ")"
		3: # Xor
			return "(" + bool_A + " != " + bool_B + ")"
		_:
			return "false" # Fallback case, probably will never trigger

func replace_self_with_trigger_selector() -> void:
	var parent = get_parent()
	if not (parent is Control):
		return
	var instance = load(trigger_selector_path).instantiate()
	parent.add_child(instance)
	queue_free()

func _on_logic_gate_item_selected(index: int) -> void:
	match index:
		0: # And
			signal_a_host.visible = true
		1: # Or
			signal_a_host.visible = true
		2: # Not
			signal_a_host.visible = false
		3: # Xor
			signal_a_host.visible = true
		4: # Var, revert to trigger selection dropdown
			replace_self_with_trigger_selector()
		_:
			pass
