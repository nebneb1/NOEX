extends Node

var steam_id : int = 0
var steam_username : String = ""

#func steam_setup():
	#OS.set_environment("SteamAppID", str(480))
	#OS.set_environment("SteamGameID", str(480))

func _ready():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	print(Steam.steamInit(false, 480)["verbal"])
	
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	print(steam_username, " ", steam_id)
	
func _process(delta: float) -> void:
	Steam.run_callbacks()
	
