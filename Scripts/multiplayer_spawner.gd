extends MultiplayerSpawner

@onready var player_scene = preload("res://Scenes/player.tscn")

var players : Dictionary = {}


#func _ready() -> void:
	#if is_multiplayer_authority():
		#spawn(1)
		#multiplayer.peer_connected.connect(spawn)
		#multiplayer.peer_disconnected.connect(remove_player)
#
#func spawn_player(peer_id):
	#var inst = player_scene.instantiate()
	#inst.set_multiplayer_authority(peer_id)
	#players[peer_id] = {
		#"object" : inst
	#}
	#return inst
	#
#
#func remove_player(peer_id):
	#players[peer_id]["object"].queue_free()
	#players.erase(peer_id)
