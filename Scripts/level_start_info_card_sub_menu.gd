extends Control

@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel_container: PanelContainer = $MarginContainer/PanelContainer
@onready var level_name_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Level_Name
@onready var level_rating_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Level_Rating
@onready var level_description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/Level_Description

var intro_exit_tween: Tween

func set_start_level_info(level_name: String, level_rating: Array, level_description: String) -> void:
	level_name_label.text = level_name
	level_description_label.text = level_description
	
	var completion_rating_string: String = ""
	for i in level_rating.size(): # Should always be 3
		if level_rating[i]:
			completion_rating_string += "★"
		else:
			completion_rating_string += "☆"
	level_rating_label.text = completion_rating_string

func toggled_deployed(deploy: bool = false) -> void:
	if deploy == visible:
		return
	if intro_exit_tween:
		intro_exit_tween.kill()
	intro_exit_tween = get_tree().create_tween()
	intro_exit_tween.pause()
	intro_exit_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	Global.world_scene.play_audio_track(Global.world_scene.transition_woosh, "UI")
	if deploy:
		Global.world_scene.level_end_sub_menu.toggled_deployed(false)
		
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 1.5 * margin_container.size.y), 0.0)
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 50.0), 0.3)
		intro_exit_tween.play()
		visible = true
	else:
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0, 1.5 * margin_container.size.y), 0.3)
		intro_exit_tween.play()
		await intro_exit_tween.finished
		visible = false

func _on_close_pressed() -> void:
	toggled_deployed(false)
