extends Control

@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel_container: PanelContainer = $MarginContainer/PanelContainer
@onready var status_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Status_Label
@onready var next_level_button: Button = $MarginContainer/PanelContainer/VBoxContainer/Next_Level

var intro_exit_tween: Tween

func toggled_deployed(deploy: bool, is_victorious: bool) -> void:
	if intro_exit_tween:
		intro_exit_tween.kill()
	intro_exit_tween = get_tree().create_tween()
	intro_exit_tween.pause()
	intro_exit_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if deploy:
		
		if is_victorious:
			var current_rating: Array = Global.world_scene.level_info_dict["current_rating"]
			var rating_string: String = ""
			if current_rating[0]:
				rating_string = "★"
			else:
				rating_string = "☆"
			if current_rating[1]:
				rating_string += "★"
			else:
				rating_string += "☆"
			if current_rating[2]:
				rating_string += "★"
			else:
				rating_string += "☆"
			
			status_label.text = "VICTORY" + "\n" + rating_string
			next_level_button.disabled = false
		else:
			status_label.text = "DEFEAT"
			next_level_button.disabled = true
		
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 1.5 * margin_container.size.y), 0.0)
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 50.0), 0.3)
		intro_exit_tween.play()
		visible = true
	else:
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 1.5 * margin_container.size.y), 0.3)
		intro_exit_tween.play()
		await intro_exit_tween.finished
		visible = false

func _on_main_menu_pressed() -> void:
	Global.world_scene.button_signal("main")
	toggled_deployed(false, false)

func _on_retry_pressed() -> void:
	Global.world_scene.menus.get("GUI")._on_restart_pressed()
	toggled_deployed(false, false)
