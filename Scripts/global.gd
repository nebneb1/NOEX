extends Node

const SAVE_FOLDER = "save_data"

enum VoiceMode {
	ALWAYS_ON,
	PUSH_TO_TALK,
	MUTE
}

var voip_sample_rate = 44100
var voice_mode : VoiceMode = VoiceMode.ALWAYS_ON

var steam_id : int = 0
var steam_username : String = ""
var puppet_players : Array = []
var player_holder : Node3D
var trans : Control
var menu : Control
var mouse_control = true

@onready var vol_effect : AudioEffectSpectrumAnalyzer = preload("res://Audio/LiveFX/mic_input_vol.tres")
var _vol_effect_instance : AudioEffectSpectrumAnalyzerInstance
var mic_vol : float = 0.0

func _ready():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	print(Steam.steamInit(false, 480)["verbal"])
	
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	print(steam_username, " ", steam_id)
	
	
	_vol_effect_instance = get_audio_effect_instance("Record", vol_effect)
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_FOLDER): 
		dir.make_dir(SAVE_FOLDER)
		print("Directory created:", SAVE_FOLDER)

func get_audio_effect_instance(bus : String, effect : AudioEffect) -> AudioEffectInstance:
	var bus_index = AudioServer.get_bus_index(bus)
	for i in range(AudioServer.get_bus_effect_count(bus_index)):
		if AudioServer.get_bus_effect(bus_index, i) == vol_effect:
			return AudioServer.get_bus_effect_instance(bus_index, i)
	
	return null

func _process(delta: float) -> void:
	Steam.run_callbacks()
	
	mic_vol = _vol_effect_instance.get_magnitude_for_frequency_range(0, 20000).length()
	
	# cull dead puppet players
	for puppet in puppet_players:
		if not is_instance_valid(puppet):
			puppet_players.erase(puppet)

func get_puppet_player(steam_id : int):
	for puppet in puppet_players:
		if puppet.player_steam_id == steam_id:
			return puppet
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		if mouse_control:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_control = false
			menu.show()
			Settings.load_settings()
			
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_control = true
			menu.hide()
			Settings.save_settings()

#func update_voice_mode(new_mode : VoiceMode) -> void:
	#voice_mode = new_mode
	#Steam.setInGameVoiceSpeaking(steam_id, false)
	#match voice_mode:
		#VoiceMode.ALWAYS_ON:
			#Steam.startVoiceRecording()
			#
		#VoiceMode.PUSH_TO_TALK:
			#Steam.stopVoiceRecording()
		#
		#VoiceMode.MUTE:
			#Steam.stopVoiceRecording()
#
#func _input(event: InputEvent) -> void:
	#if voice_mode == VoiceMode.PUSH_TO_TALK:
		#if event.is_action_pressed("push_to_talk"):
			#Steam.startVoiceRecording()
			#Steam.setInGameVoiceSpeaking(steam_id, true)
		#if event.is_action_released("push_to_talk"):
			#Steam.stopVoiceRecording()
			#Steam.setInGameVoiceSpeaking(steam_id, false)
