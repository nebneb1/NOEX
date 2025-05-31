extends Control

const MAX_LINE_COUNT = 5
const CONSOLE_FADE_TIME = [3.0, 5.0]

enum {
	DEFAULT,
	ALERT,
	WARN,
	NONE,
	INFO
}

@export var container : VBoxContainer
@onready var console_bg: ColorRect = $ConsoleBg
@export var console: RichTextLabel

var line_count = 0
var console_fade_timer = 0.0

var TAGS = [
	[DEFAULT, Color(1,1,1,0.5).to_html()], 
	[WARN, Color(1,1,0).to_html()], 
	[ALERT, Color(1,0,0).to_html()],
	[NONE, Color(1,1,1).to_html()],
	[INFO, Color(0,1,1).to_html()]]

var tracked_values : Array = [
	{
		"tag": "FPS",
		"label": null,
		"is_function": true,
		"object": Engine,
		"parameter": "",
		"callable": Callable(Engine, "get_frames_per_second"),
		"print": false
	}
]
# tracked values format
# 0 [display tag : String, 
# 1 label object pointer : Label, 
# 2 value from function : bool, 
# 3 Callable func or object : Callable or Node,
# 4 param name in case of non-Callable : String]


func _ready():
	if Global.DEBUG:
		_update_list()
	else:
		hide()
	
	
func _process(delta: float):
	console_fade_timer += delta
	console_bg.modulate.a = 1.0 - clamp((console_fade_timer - CONSOLE_FADE_TIME[0]) / (CONSOLE_FADE_TIME[1] - CONSOLE_FADE_TIME[0]), 0.0, 1.0)
	if Global.DEBUG:
		_update()
	
func _update():
	for value in tracked_values:
		if not value["object"]:
			tracked_values.erase(value)
		else:
			var label = value["label"]
			if label:
				if value["is_function"]:
					label.text = value["tag"] + ": " + str(value["callable"].call())
					if value["print"]: print(str(value["callable"].call()))
					
				else:
					label.text = value["object"].name + " - " + value["tag"] + ": " + str(value["object"].get(value["parameter"]))
					if value["print"]: print(value["object"].name + " - " + value["tag"] + ": " + str(value["object"].get(value["parameter"])))
					
			else: print("aa im missing my label this is the worst day of my short computer life...")

func _update_list():
	for child in container.get_children():
		child.queue_free()
	
	for value in tracked_values:
		var label = Label.new()
		label.text = value["tag"] + ": "
		container.add_child(label)
		tracked_values[tracked_values.find(value)]["label"] = container.get_child(container.get_child_count()-1)
	
	_update()
		

func track(object : Node, track_string : String, print : bool = false, tag : String = "", is_func = false):
	var out = {
		"tag": "",
		"label": null,
		"is_function": is_func,
		"object": null,
		"parameter": "",
		"callable": null,
		"print": print
		}
		
	if tag != "": out["tag"] = tag
	else: out["tag"] = track_string
	
	if is_func: 
		out["callable"] = Callable(object, track_string)
	else: 
		out["object"] = object
		out["parameter"] = track_string
	
	tracked_values.append(out)
	_update_list()



func push(item, tag := DEFAULT):
	var time = Time.get_time_dict_from_system()
	var out = ""
	
	item = str(item)
	for i in TAGS: if i[0] == tag: out += "[color=" + i[1] + "]"
	if tag == DEFAULT: out += "[i]"
	if tag != INFO: out += "[%02d:%02d:%02d] " % [time.hour, time.minute, time.second]
	if tag == ALERT: out += "ALERT: "
	if tag == ALERT: out += "WARNING: "
	if tag == DEFAULT: out += "[/i]"
	out += item + "[/color]\n"
	
	line_count += 1
	#if line_count > MAX_LINE_COUNT:
	console.text = console.text.split("\n", true, 1)[1] + out
	#else:
		#console.text = console.text + out
	
	if tag != ALERT: print("[%02d:%02d:%02d] " % [time.hour, time.minute, time.second], item)
	else: printerr("[%02d:%02d:%02d] ALERT: " % [time.hour, time.minute, time.second], item)
	
	console_fade_timer = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("console"):
		console_fade_timer = 0.0
