extends Control

signal level_selected

@onready var level_source_tab_container: TabContainer = $PanelContainer/MarginContainer/TabContainer
@onready var campaign_play_button: Button = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer/HBoxContainer/Play
@onready var campaign_level_name_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Name
@onready var campaign_level_rating_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Rating
@onready var campaign_level_description_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Description
@onready var load_from_local_play_button: Button = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer/HBoxContainer/Play
@onready var load_from_local_level_name_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Name
@onready var load_from_local_level_rating_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Rating
@onready var load_from_local_level_description_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Description

var levels_dict: Dictionary = { # Grid dimension, layout_dict, unlocked, Name, Rating, Description
	"blank50": [Vector2i(50,50),{}, true, "Sandbox", "★★★", "An empty world to experiment in"],
	"level_1": [Vector2i(50,50),{}, false, "Level 1", "☆☆☆", "Your first test"],
	"level_2": [Vector2i(50,50),{}, false, "Level 2", "☆☆☆", "A new trick to learn"],
	"level_3": [Vector2i(50,50),{}, false, "Level 3", "☆☆☆", "Grow my child"],
}

var focus_owner: Control = self
var selected_level_id: String = ""

func _ready() -> void:
	level_selected.connect(_on_level_selected)
	
	var level_source_tab_bar: TabBar = level_source_tab_container.get_tab_bar()
	level_source_tab_bar.set_tab_title(0, " Campaign Levels ")
	level_source_tab_bar.set_tab_title(1, " Steam Workshop ")
	level_source_tab_bar.set_tab_title(2, " Open From Local ")
	
	level_source_tab_bar.set_tab_disabled(1, true)
	level_source_tab_container.current_tab = 0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			await get_tree().process_frame
			focus_owner = get_viewport().gui_get_focus_owner()
			if focus_owner:
				if focus_owner is PanelContainer and focus_owner.has_meta("level_id"):
					selected_level_id = focus_owner.get_meta("level_id")
					level_selected.emit()

func set_gui_visible(set_to_visible: bool) -> void:
	visible = set_to_visible

func load_to_pre_loaded_level_info_dict(level_name: String = selected_level_id) -> void:
	var level_directory: String = Global.local_campaign_levels_directory + level_name
	if not DirAccess.dir_exists_absolute(level_directory):
		push_error("Level directory: " + level_directory + "\n" + "cannot be found")
		return
	Global.world_scene.active_directory = level_directory
	Global.world_scene.open_level_from_local(true, true, false)
	# Need a new way to determine if level is locked
	campaign_level_name_info_tab.text = Global.world_scene.pre_loaded_level_info_dict["level_name"]
	campaign_level_description_info_tab.text = Global.world_scene.pre_loaded_level_info_dict["level_description"]
	var completion_rating_string: String = ""
	var completion_rating_array: Array = Global.world_scene.pre_loaded_level_info_dict["completion_rating"]
	for i in completion_rating_array.size(): # Should always be 3
		if completion_rating_array[i]:
			completion_rating_string += "★"
		else:
			completion_rating_string += "☆"
	campaign_level_rating_info_tab.text = completion_rating_string

func _on_level_selected() -> void:
	var level_info: Array = levels_dict.get(selected_level_id)
	campaign_play_button.disabled = !level_info[2]
	campaign_level_name_info_tab.text = level_info[3]
	campaign_level_rating_info_tab.text = level_info[4]
	campaign_level_description_info_tab.text = level_info[5]

func clear_load_from_local_selection() -> void:
	load_from_local_play_button.disabled = true
	load_from_local_level_name_info_tab.text = ""
	load_from_local_level_description_info_tab.text = ""
	load_from_local_level_rating_info_tab.text = ""

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")
	clear_load_from_local_selection()

func _on_campaign_play_pressed() -> void:
	if selected_level_id: # This needs to be changed to be similar to _on_play_open_from_local_pressed()
		Global.world_scene.button_signal("play")
		var level_data: Array = levels_dict.get(selected_level_id)
		Global.world_scene.populate_cells(level_data[0], level_data[1], true)
		clear_load_from_local_selection()

func _on_open_from_local_pressed() -> void:
	await Global.world_scene.open_level_from_local(false, true, false)
	load_from_local_play_button.disabled = false
	load_from_local_level_name_info_tab.text = Global.world_scene.pre_loaded_level_info_dict["level_name"]
	load_from_local_level_description_info_tab.text = Global.world_scene.pre_loaded_level_info_dict["level_description"]
	var completion_rating_string: String = ""
	var completion_rating_array: Array = Global.world_scene.pre_loaded_level_info_dict["completion_rating"]
	for i in completion_rating_array.size(): # Should always be 3
		if completion_rating_array[i]:
			completion_rating_string += "★"
		else:
			completion_rating_string += "☆"
	load_from_local_level_rating_info_tab.text = completion_rating_string

func _on_play_open_from_local_pressed() -> void:
	Global.world_scene.button_signal("populate_then_play")
	clear_load_from_local_selection()
