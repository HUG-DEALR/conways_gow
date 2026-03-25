extends Control

@onready var pages_parent: Control = $Pages_Parent
@onready var pages: Array = pages_parent.get_children()
@onready var auto_play_generations_button: Button = $Pages_Parent/Page_8/MarginContainer2/HBoxContainer/Auto_Play_Generations_Button

var page_transition_tween: Tween
var current_page_index: int = 0
var playing_generations: bool = false

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible

func transition_pages(target_page_index: int = current_page_index + 1, from_right: bool = true) -> void:
	if target_page_index == current_page_index:
		return
	if target_page_index >= pages.size():
		return
	if target_page_index < 0:
		return
	
	var current_page: Control = pages[current_page_index]
	var new_page: Control = pages[target_page_index]
	
	if page_transition_tween:
		page_transition_tween.kill()
	page_transition_tween = create_tween()
	page_transition_tween.pause()
	page_transition_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var transition_vector: Vector2 = Vector2(get_viewport().size.x + new_page.size.x, 0.0)
	if from_right:
		transition_vector *= -1.0
	
	page_transition_tween.tween_property(current_page, "position", transition_vector, 0.5)
	new_page.position = -1.0 * transition_vector
	new_page.visible = true
	page_transition_tween.parallel().tween_property(new_page, "position", Vector2.ZERO, 0.5)
	
	page_transition_tween.play()
	await page_transition_tween.finished
	current_page.visible = false
	current_page_index = target_page_index

func set_play_pause(set_to_play: bool) -> void:
	if set_to_play:
		auto_play_generations_button.text = "◼"
		playing_generations = true
		Global.world_scene.generation_timer.start(0.1)
	else:
		auto_play_generations_button.text = "❯❯"
		playing_generations = false
		Global.world_scene.generation_timer.stop()

func _on_next_page_button_pressed() -> void:
	if pages.size() == current_page_index + 1:
		await Global.world_scene.menus.get("Levels_menu").select_next_level_id()
		await Global.world_scene.menus.get("Levels_menu").load_to_pre_loaded_level_info_dict()
		Global.world_scene.button_signal("populate_then_play")
	else:
		transition_pages(current_page_index + 1, true)

func _on_previous_page_button_pressed() -> void:
	if current_page_index == 0:
		Global.world_scene.button_signal("main")
	else:
		transition_pages(current_page_index - 1, false)

func _on_auto_play_generations_button_pressed() -> void:
	set_play_pause(!playing_generations)

func _on_step_generation_button_pressed() -> void:
	Global.world_scene.iterate_generation()
	set_play_pause(false)
