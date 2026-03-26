extends Control

@onready var instructions_parent: PanelContainer = $Instructions_Parent
@onready var instruction_text: RichTextLabel = $Instructions_Parent/VBoxContainer/Instruction_Text

func set_gui_visible(set_to_visible: bool) -> void:
	if set_to_visible:
		var instructions: String = Global.world_scene.level_info_dict["level_instructions"]
		if instructions.is_empty():
			instructions_parent.visible = false
		else:
			instruction_text.text = instructions
			instructions_parent.visible = true
		visible = true
	else:
		visible = false

func _on_resume_pressed() -> void:
	Global.world_scene.button_signal("play", "resume")

func _on_return_to_main_pressed() -> void:
	Global.world_scene.button_signal("main")

func _on_visibility_changed() -> void:
	set_gui_visible(visible)
