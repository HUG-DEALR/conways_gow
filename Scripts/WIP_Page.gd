extends Control

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main", "resume")

func _on_feedback_pressed() -> void:
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSc2GD0_SGyCcc_57rdv3xnOqenKdtFW8fQDZ3QR8uf7Ihhgqg/viewform?usp=dialog")

func _on_bug_report_pressed() -> void:
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSfscd83qw-mP4oFlyRMAc4Kd_fTf4CtDW_ICmki0uCgliZzfA/viewform?usp=dialog")
