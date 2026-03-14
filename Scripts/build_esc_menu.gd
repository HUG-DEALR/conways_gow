extends Control

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible

func _on_resume_pressed() -> void:
	Global.world_scene.button_signal("build", "resume")

func _on_save_and_exit_pressed() -> void:
	print("Running Save and Exit")
	Global.world_scene.save_level(Global.world_scene.level_info_dict)
#	await Global.build_saved
	Global.world_scene.button_signal("main")
	Global.world_scene.outcome_overlay.queue_outcome_to_print("Build Saved", true)

func _on_return_to_main_pressed() -> void:
	Global.world_scene.button_signal("main")
