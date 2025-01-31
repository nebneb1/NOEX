extends Node

var steam_id : int = 0
var steam_username : String = ""
var puppet_players : Array = []
var player_holder : Node3D
var trans : Control

func _ready():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	print(Steam.steamInit(false, 480)["verbal"])
	
	
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	print(steam_username, " ", steam_id)

func _process(delta: float) -> void:
	Steam.run_callbacks()
	# cull dead puppet players
	for puppet in puppet_players:
		if not is_instance_valid(puppet):
			puppet_players.erase(puppet)
	
