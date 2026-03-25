extends Control

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main", "resume")
