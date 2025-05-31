extends Node

const SETTINGS_PATH = "user://save_data/settings.dat"
const DEFAULT_SETTINGS = {
	"voice_volume" : 1.0, 
	"voice_threshold" : 0.1,
	"device" : "Default",
	"player_volumes" : []
}

var voice_volume : float = 1.0 
var voice_threshold : float = 0.1
var audio_input_device : String = "Default"
var player_volumes = []

var _mic_amplify : AudioEffectAmplify = preload("res://Audio/LiveFX/mic_amplify_vol.tres")

func _ready() -> void:
	create_default_save()
	call_deferred("load_settings")

func create_default_save():
	if not FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		print(file.get_error())
		file.store_var(DEFAULT_SETTINGS.duplicate())
		file.close()

func save_settings():
	var settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var settings : Dictionary = settings_file.get_var().duplicate()
	settings_file.close()
	settings["voice_volume"] = voice_volume
	settings["voice_threshold"] = voice_threshold
	settings["device"] = audio_input_device
	settings["player_volumes"] = player_volumes
	settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	settings_file.store_var(settings)
	settings_file.close()
	
func set_mic_volume(volume : float):
	_mic_amplify.volume_db = clamp(linear_to_db(volume), -INF, 6.0)

func load_settings():
	var settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var settings : Dictionary = settings_file.get_var()
	settings_file.close()
	
	#set settings vars
	voice_volume = settings["voice_volume"]
	voice_threshold = settings["voice_threshold"]
	if AudioServer.get_input_device_list().has(settings["device"]):
		audio_input_device = settings["device"]
	else:
		audio_input_device = "Default"
	player_volumes = settings["player_volumes"]
	
	set_mic_volume(settings["voice_volume"])
	AudioServer.input_device = audio_input_device
	
	Global.menu.update_values()
	
