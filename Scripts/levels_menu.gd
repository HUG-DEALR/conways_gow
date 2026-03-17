extends Control

signal level_selected

@onready var level_source_tab_container: TabContainer = $PanelContainer/MarginContainer/TabContainer

@onready var campaign_play_button: Button = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer/HBoxContainer/Play
@onready var campaign_level_name_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Name
@onready var campaign_level_rating_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Rating
@onready var campaign_level_description_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer2/Level_Description
@onready var campaign_level_card_grid_container: GridContainer = $PanelContainer/MarginContainer/TabContainer/Campaign_Levels/VBoxContainer/ScrollContainer/MarginContainer/GridContainer

@onready var load_from_local_play_button: Button = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer/HBoxContainer/Play
@onready var load_from_local_level_name_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Name
@onready var load_from_local_level_rating_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Rating
@onready var load_from_local_level_description_info_tab: Label = $PanelContainer/MarginContainer/TabContainer/Load_From_Local/VBoxContainer2/Level_Description

const level_card_path: String = "res://Scenes/Props/example_level_card.tscn"

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
	
	await get_tree().process_frame
	populate_campaign_level_cards(true)

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
	if not FileAccess.file_exists(level_directory):
		push_error("Level directory: " + level_directory + " cannot be found")
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
	if not FileAccess.file_exists(Global.local_campaign_levels_directory.path_join(selected_level_id)):
		push_error("Selected level ID: " + selected_level_id + " not found")
		return
	load_to_pre_loaded_level_info_dict(selected_level_id)
	campaign_play_button.disabled = false

func clear_load_from_local_selection() -> void:
	load_from_local_play_button.disabled = true
	load_from_local_level_name_info_tab.text = ""
	load_from_local_level_description_info_tab.text = ""
	load_from_local_level_rating_info_tab.text = ""

func populate_campaign_level_cards(clear_previous: bool = false) -> void:
	if not DirAccess.dir_exists_absolute(Global.local_campaign_levels_directory):
		push_error("Could not find local campaign levels directory at:" + "\n" + Global.local_campaign_levels_directory)
		return
	
	if clear_previous:
		for child in campaign_level_card_grid_container.get_children():
			if child.get_index() != 0:
				child.queue_free()
	
	var local_level_files: PackedStringArray = DirAccess.get_files_at(Global.local_campaign_levels_directory)
	local_level_files.sort() # This will determine display order of the cards
	# format of level files should be CampaignLevel_0001_LevelName.cgow
	var level_card: Resource = load(level_card_path)
	for file_name in local_level_files:
		if not file_name.ends_with(".cgow"):
			continue
		
		var full_path: String = Global.local_campaign_levels_directory.path_join(file_name)
		var level_data: Dictionary = Global.load_from_file(full_path)
		if level_data.is_empty():
			continue
		
		var new_level_card: Node = level_card.instantiate()
		campaign_level_card_grid_container.add_child(new_level_card)
		campaign_level_card_grid_container.move_child(new_level_card, campaign_level_card_grid_container.get_child_count() - 1)
		new_level_card.set_level_card_info(level_data["level_name"], level_data["completion_rating"], false, file_name)

func _on_back_pressed() -> void:
	Global.world_scene.button_signal("main")
	clear_load_from_local_selection()

func _on_campaign_play_pressed() -> void:
	Global.world_scene.button_signal("populate_then_play")
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
