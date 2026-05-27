class_name PlayerCam
extends Camera3D

@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 4.0

@onready var player: Player = get_parent()
@onready var sightline: RayCast3D = $RayCast3D
var sight_range: float = 8


var current_focus: Object
var previous_focus: Object

var active := true

func _ready():
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		active = false
	sightline.target_position = Vector3(0,0,-sight_range)

func _input(event):
	if event is InputEventMouseMotion and active:
		get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
		
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		if active:
			active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			active = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if not active:
		return
	
	var cam_joystick := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	
	if cam_joystick.length() > 0.1:
		player.rotate_y(-cam_joystick.x * joystick_sensitivity * delta)
		rotation.x -= cam_joystick.y * joystick_sensitivity * delta
		rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if sightline.is_colliding():
		current_focus = sightline.get_collider()
	else:
		current_focus = null
	if current_focus != previous_focus:
			if current_focus:
				activate_focus_object(current_focus)
			if previous_focus:
				deactivate_focus_object(previous_focus)
	previous_focus = current_focus
	if current_focus is CollisionObject3D:
		player.focus_object = current_focus

func activate_focus_object(collider: Object):
	if not collider is Node:
		return
	var target: Node = collider
	if not target.is_in_group("Interactables"):
		return
	target.activate()

func deactivate_focus_object(collider: Object):
	if not collider is Node:
		return
	var target: Node = collider
	if not target.is_in_group("Interactables"):
		return
	target.deactivate()
