extends Control

signal level_selected

@onready var level_source_tab_container: TabContainer = $PanelContainer/MarginContainer/TabContainer
@onready var play_button: Button = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer/HBoxContainer/Play
@onready var level_name_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Name
@onready var level_rating_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Rating
@onready var level_description_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Description

var levels_dict: Dictionary = { # Grid dimension, layout_dict, unlocked, Name, Rating, Description
	"blank50": [Vector2i(50,50),{}, true, "Sandbox", "★★★", "An empty world to experiment in"],
	"level_1": [Vector2i(50,50),{}, false, "Level 1", "☆☆☆", "Your first test"],
	"level_2": [Vector2i(50,50),{}, false, "Level 2", "☆☆☆", "A new trick to learn"],
	"level_3": [Vector2i(50,50),{}, false, "Level 3", "☆☆☆", "Grow my child"],
}

var focus_owner: Control = self
var selected_level_id: String = ""
var entry_exit_tween: Tween

func _ready() -> void:
	level_selected.connect(_on_level_selected)
	
	var level_source_tab_bar: TabBar = level_source_tab_container.get_tab_bar()
	level_source_tab_bar.set_tab_title(0, " Campaign Levels ")
	level_source_tab_bar.set_tab_title(1, " Steam Workshop ")
	level_source_tab_bar.set_tab_title(2, " Open From Local ")
	
	level_source_tab_bar.set_tab_disabled(1, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			await get_tree().process_frame
			focus_owner = get_viewport().gui_get_focus_owner()
			if focus_owner:
				if focus_owner is PanelContainer and focus_owner.has_meta("level_id"):
					selected_level_id = focus_owner.get_meta("level_id")
					level_selected.emit()

func _on_level_selected() -> void:
	var level_info: Array = levels_dict.get(selected_level_id)
	play_button.disabled = !level_info[2]
	level_name_info_tab.text = level_info[3]
	level_rating_info_tab.text = level_info[4]
	level_description_info_tab.text = level_info[5]

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")

func _on_play_pressed() -> void:
	if selected_level_id:
		Global.world_scene.button_signal("play")
		var level_data: Array = levels_dict.get(selected_level_id)
		Global.world_scene.populate_cells(level_data[0], level_data[1], true)

func _on_open_from_local_pressed() -> void:
	await Global.world_scene.open_level_from_local()
	Global.world_scene.button_signal("play")
