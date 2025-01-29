extends Control

const start_level = "planet1"

@onready var transitions: Control = $Transitions
@onready var level_spawner: MultiplayerSpawner = $MultiplayerSpawner

var lobby_id = 0
var peer = SteamMultiplayerPeer.new()



const levels = {
	"planet1" = preload("res://Scenes/planet1.tscn")
}

@export var level_holder: Node3D
@onready var trans_nodes = {
	"fade_from_black" : $Transitions/FadeFromBlack
}

var curr_level = ""
#
func _ready() -> void:
	level_spawner.spawn_function = load_scene
	peer.lobby_created.connect(_on_lobby_created)

func _process(delta: float) -> void:
	var clip = DisplayServer.clipboard_get()
	if int(clip) != 0 and len(clip) == 18:
		join_lobby(clip)
		DisplayServer.clipboard_set("")
		
var window_focused = false
func _notification(what):
	if what == NOTIFICATION_FOCUS_ENTER:
		window_focused = true
		
	elif what == NOTIFICATION_FOCUS_EXIT:
		window_focused = false
		
			
func empty(): return

func trans_to_level(level : String, type : String, time : float):
	match type:
		"fade_from_black":
			var tween = create_tween()
			tween.tween_property(trans_nodes["fade_from_black"], "color:a", 1.0, time)
			await tween.finished
			switch_scene(levels[level])
			curr_level = level
			var tween2 = create_tween()
			tween2.tween_property(trans_nodes["fade_from_black"], "color:a", 0.0, time)

func fake_trans_to_level(type : String, time : float, after : Callable = empty):
	match type:
		"fade_from_black":
			var tween = create_tween()
			tween.tween_property(trans_nodes["fade_from_black"], "color:a", 1.0, time)
			await tween.finished
			after.call()
			var tween2 = create_tween()
			tween2.tween_property(trans_nodes["fade_from_black"], "color:a", 0.0, time)
			
		"from_black_one_way":
			trans_nodes["fade_from_black"].color.a = 1.0
			var tween = create_tween()
			tween.tween_property(trans_nodes["fade_from_black"], "color:a", 0.0, time)
			after.call()

func switch_scene(to: PackedScene):
	for child in level_holder.get_children():
		child.queue_free()
	level_holder.add_child(to.instantiate())

func load_scene(level : String):
	level_spawner.clear_spawnable_scenes()
	return levels[level].instantiate()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("host") and curr_level == "":
		fake_trans_to_level("from_black_one_way", 1.0)
		peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
		multiplayer.multiplayer_peer = peer
		level_spawner.spawn(start_level)

func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer

func _on_lobby_created(connect, id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()) + "'s Lobby")
		Steam.setLobbyJoinable(lobby_id, true)
		print(lobby_id)
