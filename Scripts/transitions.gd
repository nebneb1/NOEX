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

var curr_level = ""

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
