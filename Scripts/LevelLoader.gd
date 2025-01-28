extends Control

const start_level = "planet1"

const levels = {
	"planet1" = preload("res://Scenes/planet1.tscn")
}

@onready var trans_nodes = {
	"fade_from_black" : $Transitions/FadeFromBlack
}


func _ready() -> void:
	#get_tree().change_scene_to_packed(levels[start_level])
	fake_trans_to_level("from_black_one_way", 1.0)

func empty(): return

func trans_to_level(level : String, type : String, time : float):
	match type:
		"fade_from_black":
			var tween = create_tween()
			tween.tween_property(trans_nodes["fade_from_black"], "color:a", 1.0, time)
			await tween.finished
			get_tree().change_scene_to_packed(levels[level])
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

	
