extends Control

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")
