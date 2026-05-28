class_name Player
extends CharacterBody3D

signal health_changed(new_value: int)

var id : int
var username := ""
var is_local_player := false

var focus_object : CollisionObject3D = null

var projectile_container : Node
var projectile_spawner : MultiplayerSpawner
var projectiles : Dictionary[String, PackedScene] = {
	"rock": preload("res://rock.tscn")
}

const JUMP_VELOCITY := 4.5

var max_health := 100
var health := 100:
	set(value):
		health = value
		if is_local_player:
			health_changed.emit(value)


var gravity := 9.8 

var max_speed := 5.0
var default_speed := 5.0
var sprint_multiplier := 1.8
var max_stamina := 2.0
var stamina := 2.0
var sprint_on := false
var exhausted := false
var exhaust_end_threshold := 0.5
enum SprintMode {
	HELD,
	TOGGLE,
}
var sprint_mode := SprintMode.HELD

var syncPos := Vector3(0.0, 0.0, 0.0)

@onready var info_display := $PlayerInfoDisplay
@onready var healthbar := $PlayerInfoDisplay/SubViewport/HealthBar

func _enter_tree():
	# Doing this here instead of on ready prevents bugs.
	set_multiplayer_authority(int(str(name)))
	if is_multiplayer_authority():
		is_local_player = true
		var cam := preload("res://player_cam.tscn").instantiate()
		cam.position.y += 0.5
		add_child(cam)

func _ready() -> void:
	syncPos = global_position
	id = int(name)
	username = NetworkManager.players[id]["username"]
	GameManager.player_info[id] = {}
	GameManager.player_info[id]["username"] = username
	$PlayerInfoDisplay/SubViewport/NameTag.text = username
	$PlayerInfoDisplay/SubViewport/NameTag.shrink_to_fit()
	projectile_spawner.spawn_function = setup_projectile
	#GameManager.player_info[int(name)] = {"username":username, "spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	health_changed.connect(GameManager.on_health_changed)
	if is_local_player:
		remove_child(info_display)
		

func _physics_process(delta: float) -> void:
	
	if not is_local_player:
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		healthbar.value = health
		return
	
	if Input.is_action_just_pressed("sprint_toggle"):
		if sprint_on or !exhausted:
			sprint_on = !sprint_on
		sprint_mode = SprintMode.TOGGLE
	if Input.is_action_pressed("sprint_held"):
		sprint_on = true
		sprint_mode = SprintMode.HELD
	elif sprint_mode == SprintMode.HELD:
		sprint_on = false
	
	if sprint_on and not exhausted:
		max_speed = default_speed * sprint_multiplier
		stamina -= delta
		if stamina < 0:
			stamina = 0
			exhausted = true
			sprint_on = false
	else:
		max_speed = default_speed
		stamina += delta
		if stamina > max_stamina * exhaust_end_threshold and not sprint_on:
			exhausted = false
		if stamina > max_stamina:
			stamina = max_stamina
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if direction:
		velocity.x = direction.x * max_speed
		velocity.z = direction.z * max_speed
	else:
		velocity.x = move_toward(velocity.x, 0, max_speed)
		velocity.z = move_toward(velocity.z, 0, max_speed)
	
	
	syncPos = position
	move_and_slide()
	
	if Input.is_action_just_pressed("spell_left"):
		if Input.is_action_pressed("move_back"):
			spawn_projectile.rpc_id(1, "rock", global_position, global_rotation, 0, 0)
		else:
			spawn_projectile.rpc_id(1, "rock", global_position, global_rotation, velocity.x, velocity.z)
	if Input.is_action_just_pressed("spell_right") and focus_object:
		if focus_object is Rock:
			var rock : Rock = focus_object
			request_rock_hit.rpc_id(1, rock.get_path(), global_position) 

@rpc("any_peer", "call_local")
func request_rock_hit(rock_path: NodePath, hit_from: Vector3):
	if not multiplayer.is_server():
		return
	var rock = get_node_or_null(rock_path)
	if rock and rock is Rock:
		rock.hit.rpc(hit_from)

func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass

@rpc("authority", "call_local")
func spawn_projectile(projectile_name: String, pos: Vector3, dir: Vector3, x_speed: float, z_speed: float):
	if !multiplayer.is_server():
		return
	if !projectiles.has(projectile_name): return
	projectile_spawner.spawn([projectile_name, pos, dir, x_speed, z_speed])

func setup_projectile(data):
	var projectile := projectiles[data[0]].instantiate()
	projectile.position = data[1]
	projectile.rotation = data[2]
	projectile.position.x += data[3] * 0.2
	projectile.position.z += data[4] * 0.2
	projectile.setup()
	return projectile

@rpc("any_peer", "call_local")
func get_hit(damage: int):
	if is_multiplayer_authority():
		health -= damage
