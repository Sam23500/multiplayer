class_name Player
extends CharacterBody3D

const JUMP_VELOCITY: float = 4.5

var max_health := 100
var health := 100

var gravity := 9.8 

var max_speed: float = 5.0

var syncPos := Vector3(0.0, 0.0, 0.0)

@onready var info_display := $PlayerInfoDisplay
@onready var healthbar := $PlayerInfoDisplay/SubViewport/HealthBar

func _enter_tree():
	# Doing this here instead of on ready prevents bugs.
	set_multiplayer_authority(int(str(name)))
	if is_multiplayer_authority():
		var cam := preload("res://player_cam.tscn").instantiate()
		add_child(cam)

func _ready() -> void:
	syncPos = global_position
	
	GameManager.player_info[int(name)] = {"spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	if is_multiplayer_authority():
		remove_child(info_display)
func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		healthbar.value = health
		return
	
	
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		health -= 10
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if direction:
		direction = direction.normalized()
		velocity.x = direction.x * max_speed
		velocity.z = direction.z * max_speed
	else:
		velocity.x = move_toward(velocity.x, 0, max_speed)
		velocity.z = move_toward(velocity.z, 0, max_speed)


	syncPos = position
	move_and_slide()


func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass
