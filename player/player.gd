class_name Player
extends CharacterBody3D

signal health_changed(new_value: int)

var id : int
var username := ""
var is_local_player := false

var focus_object : CollisionObject3D = null

var spell_functions_l : Dictionary[String, Callable]
var spell_functions_r : Dictionary[String, Callable]
var spell_scenes : Dictionary[String, PackedScene] = {
	"Rock" = preload("res://spells/rock.tscn"),
	"Lightning" = preload("res://spells/lightning.tscn"),
}
var projectile_container : Node
var projectile_spawner : MultiplayerSpawner

var spell_book := SpellBook.new()


var max_health := 100
var health := 100:
	set(value):
		health = value
		if is_local_player:
			health_changed.emit(value)


var gravity := 9.8 

const JUMP_VELOCITY := 4.5
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
		var cam := preload("res://player/player_cam.tscn").instantiate()
		cam.position.y += 0.5
		add_child(cam)

func _ready() -> void:
	spell_book.append_spell("Rock", 0.5, 0.0)
	spell_book.append_spell("Lightning", 0.5, 0.0)
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
		info_display.queue_free()


func _physics_process(delta: float) -> void:
	
	if not is_local_player:
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		healthbar.value = health
		return
	
	do_sprint_stuff(delta)
	do_jump_stuff(delta)
	do_move_stuff()
	
	syncPos = position
	move_and_slide()
	
	check_spell_select()
	check_spell_cast()

func do_sprint_stuff(delta: float):
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

func do_jump_stuff(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func do_move_stuff():
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if direction:
		velocity.x = direction.x * max_speed
		velocity.z = direction.z * max_speed
	else:
		velocity.x = move_toward(velocity.x, 0, max_speed)
		velocity.z = move_toward(velocity.z, 0, max_speed)

func check_spell_select():
	if Input.is_action_just_pressed("spell_select_left"):
		spell_book.decrement_active()
	if Input.is_action_just_pressed("spell_select_right"):
		spell_book.increment_active()
	if Input.is_action_just_pressed("spell_select_0"):
		spell_book.set_active(0)
	if Input.is_action_just_pressed("spell_select_1"):
		spell_book.set_active(1)
	if Input.is_action_just_pressed("spell_select_2"):
		spell_book.set_active(2)

func check_spell_cast():
	if !spell_scenes.has(spell_book.get_active_spell_name()): return
	if spell_book.get_active_spell_name() == "Empty": return
	if Input.is_action_just_pressed("spell_left"):
		if !spell_book.is_spell_l_available(): return
		start_cooldown_l()
		#if Input.is_action_pressed("move_back"):
			#cast_spell.rpc_id(1, spell_book.get_active_spell_name(), global_position, global_rotation, 0, 0)
		#else:
		cast_spell.rpc_id(1, spell_book.get_active_spell_name(), global_position, global_rotation, velocity.x, velocity.z)
	if Input.is_action_just_pressed("spell_right") and focus_object:
		if focus_object is Rock:
			var rock : Rock = focus_object
			request_rock_hit.rpc_id(1, rock.get_path(), global_position) 
			spell_book.end_cooldown_l()

func start_cooldown_l():
	get_tree().create_timer(spell_book.start_cooldown_l()).timeout.connect(spell_book.end_cooldown_l.bind(spell_book._active_index))
func start_cooldown_r():
	get_tree().create_timer(spell_book.start_cooldown_r()).timeout.connect(spell_book.end_cooldown_r.bind(spell_book._active_index))

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
func cast_spell(spell_name: String, pos: Vector3, dir: Vector3, x_speed: float, z_speed: float):
	if !multiplayer.is_server():
		return
	projectile_spawner.spawn([spell_name, pos, dir, x_speed, z_speed])

func setup_projectile(data):
	var projectile : Node = spell_scenes[data[0]].instantiate()
	projectile.position = data[1]
	projectile.rotation = data[2]
	projectile.linear_velocity.x += data[3]
	projectile.linear_velocity.z += data[4]
	projectile.setup()
	return projectile

@rpc("any_peer", "call_local")
func get_hit(damage: int):
	if is_multiplayer_authority():
		health -= damage

@rpc("any_peer", "call_local")
func knockback(vector: Vector3):
	if is_multiplayer_authority():
		velocity += vector
