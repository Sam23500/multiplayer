class_name Player
extends CharacterBody3D

signal health_changed(new_value: int)

var id : int
var username := ""
var is_local_player := false
var paused := false

@onready var lightning : Lightning = $ConnectedSpells/Lightning
var focus_object : CollisionObject3D = null

var spell_functions_l : Dictionary[String, Callable] = {
	"Rock" : cast_rock,
	"Lightning" : cast_lightning,
	"Light" : cast_light,
}
var spell_functions_r : Dictionary[String, Callable] = {
	"Rock" : hit_rock,
	"Lightning" : shoot_lightning,
	"Light" : light_off
}

var projectile_container : Node
var rock_spawner : MultiplayerSpawner

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
	rock_spawner.spawn_function = GameManager.create_rock
	setup_default_spells()
	syncPos = global_position
	id = int(name)
	username = NetworkManager.players[id]["username"]
	GameManager.player_info[id] = {}
	GameManager.player_info[id]["username"] = username
	$PlayerInfoDisplay/SubViewport/NameTag.text = username
	$PlayerInfoDisplay/SubViewport/NameTag.shrink_to_fit()
	#GameManager.player_info[int(name)] = {"username":username, "spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	health_changed.connect(GameManager.on_health_changed)
	GameManager.game_paused.connect(on_game_paused)
	GameManager.game_resumed.connect(on_game_resumed)
	if is_local_player:
		info_display.queue_free()

func setup_default_spells():
	spell_book.append_spell("Rock", 0.5, 0.0)
	spell_book.append_spell("Lightning", 0.5, 0.0)
	spell_book.append_spell("Light",0.5,0.0)

func _physics_process(delta: float) -> void:
	
	if not is_local_player:
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		healthbar.value = health
		return
	
	if paused:
		return
	
	if health < 1:
		health = max_health
		position = Vector3(0,100,0)
	
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
	var spell = spell_book.get_active_spell_name()
	if !spell_functions_l.has(spell): return
	if spell == "Empty": return
	if Input.is_action_just_pressed("spell_left"):
		if !spell_book.is_spell_l_available(): return
		start_cooldown_l()
		cast_spell.rpc_id(1, get_spell_data(spell, false), false)
	if Input.is_action_just_pressed("spell_right"):
		if !spell_book.is_spell_r_available(): return
		start_cooldown_r()
		cast_spell.rpc_id(1, get_spell_data(spell, true), true)

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

func get_spell_data(spell: String, is_right: bool) -> Array:
	var data = [spell, id]
	if spell == "Rock":
		if is_right:
			if not focus_object:
				data.append_array([null, global_position])
			else:
				data.append_array([focus_object.get_path(), global_position])
		else:
			data.append_array([global_position, global_rotation])
	if spell == "Lightning":
		if is_right:
			pass
		else: 
			pass
	return data

@rpc("authority", "call_local")
func cast_spell(data: Array, is_right: bool):
	#if !multiplayer.is_server():
		#return
	if is_right:
		spell_functions_r[data[0]].call(data)
	else:
		spell_functions_l[data[0]].call(data)

func cast_rock(data):
	rock_spawner.spawn(data)

func hit_rock(data):
	if not data[2]: 
		spell_book.end_cooldown_r()
		return
	var target = get_node(data[2])
	if target is Rock:
		var rock : Rock = target
		request_rock_hit.rpc_id(1, rock.get_path(), data[3]) 
	spell_book.end_cooldown_r()

func cast_lightning(_data):
	lightning.start()

func shoot_lightning(_data):
	lightning.shoot()

func cast_light(data):
	var caller = get_node("../" + str(data[1]))
	caller.set_glow.rpc(true)

func light_off(data):
	var caller = get_node("../" + str(data[1]))
	caller.set_glow.rpc(false)

@rpc("any_peer", "call_local")
func set_glow(on: bool):
	$MeshInstance3D.mesh.material.emission_enabled = on

@rpc("any_peer", "call_local")
func get_hit(damage: int):
	if is_multiplayer_authority():
		health -= damage

@rpc("any_peer", "call_local")
func knockback(vector: Vector3):
	if is_multiplayer_authority():
		velocity += vector

func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass

func on_game_paused():
	paused = true

func on_game_resumed():
	paused = false
