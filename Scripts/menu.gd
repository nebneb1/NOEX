extends Control

const PLAYER_VOLUME_SLIDER = preload("res://Scenes/player_volume_slider.tscn")

@onready var voice_thresh_slider: HSlider = $VBoxContainer/VoiceUI/VoiceThreshSlider
@onready var voice_thresh_input_val: HSlider = $VBoxContainer/VoiceUI/VoiceThreshSlider/VoiceThreshInputVal
@onready var voice_volume_slider: HSlider = $VBoxContainer/VoiceUI/VoiceVolume
@onready var device_dropdown: OptionButton = $VBoxContainer/VoiceUI/Device
@onready var player_container: VBoxContainer = $Players/PlayerContainer
@onready var player_volume_label: Label = $Players/Label


var player_volume_sliders = []

func _ready() -> void:
	Global.menu = self
	update_players()
	hide()

func update_players():
	for child in player_container.get_children():
		child.queue_free()
	
	if Global.puppet_players.size() == 0:
		player_volume_label.text = ""
	else:
		player_volume_label.text = "Player Volumes:"
		
	for puppet in Global.puppet_players:
		var inst = PLAYER_VOLUME_SLIDER.instantiate()
		var name_label = inst.get_node("Name")
		var slider = inst.get_node("HBoxContainer/Slider")
		var percent = inst.get_node("HBoxContainer/Percent")
		
		inst.name = str(puppet.player_steam_id)
		name_label.text = puppet.player_name + ": "
		
		var has_entry = false
		for player in Settings.player_volumes:
			if player[0] == puppet.player_steam_id:
				has_entry = true
				slider.value = player[1]
				
		
		if not has_entry:
			Settings.player_volumes.append([puppet.player_steam_id, 1.0])
			slider.value = 1.0
		
		percent.text = str(round(slider.value * 100.0)) + "%"
		slider.value_changed.connect(_on_player_volume_value_changed)
		
		player_container.add_child(inst)
		
	

func update_values():
	voice_thresh_slider.value = Settings.voice_threshold
	voice_volume_slider.value = Settings.voice_volume
	device_dropdown.clear()
	for device in AudioServer.get_input_device_list():
		device_dropdown.add_item(device, hash(device))
	
	device_dropdown.select(device_dropdown.get_item_index(hash(Settings.audio_input_device)))
	
	update_players()

func _process(delta: float) -> void:
	voice_thresh_input_val.value = Global.mic_vol
	


func _on_voice_threshold_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Settings.voice_threshold = voice_thresh_slider.value


func _on_voice_volume_value_changed(value: float) -> void:
	Settings.voice_volume = voice_volume_slider.value
	Settings.set_mic_volume(voice_volume_slider.value)

func _on_device_item_selected(index: int) -> void:
	Settings.audio_input_device = device_dropdown.get_item_text(index)
	AudioServer.input_device = device_dropdown.get_item_text(index)

func _on_player_volume_value_changed(value: float) -> void: # Theres a better way to do this but I think this way is funny
	print("a")
	for child in player_container.get_children():
		for puppet in Global.puppet_players:
			if child.name == str(puppet.player_steam_id):
				print("b")
				for player in Settings.player_volumes:
					if player[0] == puppet.player_steam_id:
						print("c")
						player[1] = child.get_node("HBoxContainer/Slider").value
						print(round(player[1] * 100.0))
						child.get_node("HBoxContainer/Percent").text = str(round(player[1] * 100.0)) + "%"
						puppet.update_volume(player[1])
