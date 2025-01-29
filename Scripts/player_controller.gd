extends CharacterBody3D

const SENSITIVITY = 1.0
const MAX_SPEED = 5.0
const ACCEL = 100.0
const GRAVITY = 200.0
const TERMINAL_VELOCITY = 30.0
const DRAG = 100.0
const DEADZOME = 0.1

@export var camera : Camera3D

var mouse_control = true
var vel2D : Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current
	

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	
	var dir = Vector2(Input.get_action_strength("forward") - Input.get_action_strength("backward"), Input.get_action_strength("left") - Input.get_action_strength("right")).normalized()
	
	if dir.length() < DEADZOME: 
		vel2D = vel2D.normalized() * clamp(vel2D.length() - DRAG * delta, 0.0, MAX_SPEED)
	else: 
		vel2D += dir.rotated(rotation.y + PI) * delta * ACCEL
	
	if vel2D.length() > MAX_SPEED: 
		vel2D = vel2D.normalized() * MAX_SPEED
	
	velocity.z = vel2D.x
	velocity.x = vel2D.y
	velocity.y -= GRAVITY * delta * (1 + (velocity.y / TERMINAL_VELOCITY))
	
	move_and_slide()
	
	
	

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion and mouse_control:
		var delta_look_dir = event.relative * SENSITIVITY * 0.005
		rotation.y += -delta_look_dir.x
		camera.rotation.x += -delta_look_dir.y
	
	
	if event.is_action_pressed("exit"):
		if mouse_control:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_control = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_control = true
