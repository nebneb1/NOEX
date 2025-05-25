extends Control

const start_level = "planet1"

@onready var transitions: Control = $Transitions

const levels = {
	"planet1" = preload("res://Scenes/planet1.tscn")
}

@export var level_holder: Node3D
@onready var trans_nodes = {
	"fade_from_black" : $Transitions/FadeFromBlack
}

var curr_level = "menu"

func _ready():
	Global.trans = self
	if Net.AUTO_SETUP:
		if FileAccess.file_exists(Net.AUTO_SETUP_FILE):
			var file = FileAccess.open(Net.AUTO_SETUP_FILE, FileAccess.READ)
			var lobby_id = file.get_var()
			file.close()
			var dir = DirAccess.open("res://")
			dir.remove(Net.AUTO_SETUP_FILE.split("/")[-1])
			join_lobby(lobby_id)
		else:
			host_lobby()
#
var window_focused = false
func _notification(what):
	if what == NOTIFICATION_FOCUS_ENTER:
		window_focused = true
		
	elif what == NOTIFICATION_FOCUS_EXIT:
		window_focused = false
	
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		var dir = DirAccess.open("res://")
		dir.remove(Net.AUTO_SETUP_FILE.split("/")[-1])
		get_tree().quit()
		
		
			
func empty(): return

func trans_to_level(level : String, type : String, time : float = 1.0):
	match type:
		"fade_from_black":
			var tween = create_tween()
			tween.tween_property(trans_nodes["fade_from_black"], "color:a", 1.0, time)
			await tween.finished
			switch_scene(level)
			curr_level = level
			var tween2 = create_tween()
			tween2.tween_property(trans_nodes["fade_from_black"], "color:a", 0.0, time)

func fake_trans_to_level(type : String, time : float = 1.0, after : Callable = empty):
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

func switch_scene(to: String):
	for child in level_holder.get_children():
		child.queue_free()
		
	level_holder.add_child(levels[to].instantiate())

func _input(event: InputEvent) -> void:
	if curr_level == "menu":
		if event.is_action_pressed("host"):
			host_lobby()
			
		elif event.is_action_pressed("join"):
			#var id : int = int($LevelHolder/Control/TextEdit.text)
			join_lobby(int($LevelHolder/Control/TextEdit.text))

func host_lobby():
	switch_scene(start_level)
	fake_trans_to_level("from_black_one_way")
	Net.create_lobby(Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY)

func join_lobby(id : int):
	if id != 0:
		fake_trans_to_level("from_black_one_way")
		Net.join_lobby(id)
