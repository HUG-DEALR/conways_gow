extends Control

@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel_container: PanelContainer = $MarginContainer/PanelContainer
@onready var label: Label = $MarginContainer/PanelContainer/Label
@onready var deploy_timer: Timer = $Deploy_Timer

var intro_exit_tween: Tween
var queued_outcomes: Array = []
var iterating_through_queue: bool = false
var queue_position: int = 0

func _ready() -> void:
	panel_container.visible = false

func queue_outcome_to_print(outcome: String, use_raw_input: bool = false) -> void:
	queued_outcomes.append([outcome, use_raw_input])
	print("adding to outcome queue: " + str(outcome))
	if not iterating_through_queue:
		advance_outcome_queue()

func advance_outcome_queue() -> void:
	iterating_through_queue = true
	if queued_outcomes.is_empty():
		iterating_through_queue = false
		return
	var next_outcome: Array = queued_outcomes[queue_position]
	print_outcome(next_outcome[0], next_outcome[1])
	queue_position += 1
	await get_tree().process_frame
	if queue_position >= queued_outcomes.size():
		queued_outcomes.clear()
		queue_position = 0

func toggled_deployed(deploy: bool) -> void:
	if intro_exit_tween:
		intro_exit_tween.kill()
	intro_exit_tween = get_tree().create_tween()
	intro_exit_tween.pause()
	intro_exit_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if deploy:
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0,-1.5 * margin_container.size.y), 0.0)
		intro_exit_tween.tween_property(panel_container, "position", Vector2.ONE * 50.0, 0.3)
		intro_exit_tween.play()
		await get_tree().process_frame
		panel_container.visible = true
	else:
		intro_exit_tween.tween_property(panel_container, "position", Vector2(50.0,-1.5 * margin_container.size.y), 0.3)
		intro_exit_tween.play()
		await intro_exit_tween.finished
		panel_container.visible = false
		advance_outcome_queue()

func print_outcome(outcome: String, use_raw_input: bool = false) -> void:
	if use_raw_input:
		label.text = outcome
	else:
		if outcome.begins_with("star_"):
			var current_rating: Array = Global.world_scene.level_info_dict["current_rating"]
			if current_rating[0]:
				label.text = "★"
			else:
				label.text = "☆"
			if current_rating[1]:
				label.text += "★"
			else:
				label.text += "☆"
			if current_rating[2]:
				label.text += "★"
			else:
				label.text += "☆"
		else:
			match outcome:
				"defeat":
					label.text = "DEFEAT"
				"victory":
					label.text = "VICTORY"
				_:
					print("Unrecognised outcome: " + str(outcome))
					label.text = ""
	toggled_deployed(true)
	deploy_timer.start(2.0)
	await deploy_timer.timeout
	toggled_deployed(false)
