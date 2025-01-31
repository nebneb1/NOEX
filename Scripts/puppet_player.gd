extends CharacterBody3D
var player_name : String = ""
var player_steam_id : int = 0

func _ready() -> void:
	$Sprite3D/SubViewport/Label.text = player_name
	Global.puppet_players.append(self)
