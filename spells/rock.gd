class_name Rock
extends RigidBody3D

var summoner : Player

var sync_pos : Vector3
var last_sync_pos : Vector3
var used := false

var last_vel := Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_multiplayer_authority(int(str(summoner.name)))
	if !multiplayer.is_server():
		visible = false
		freeze = true

@rpc("authority", "call_local")
func setup():
	var forward_dir = -transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	position += (forward_dir*2)
	position.y = 0
	linear_velocity.y = 10
	add_to_group("interactables")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		if last_sync_pos == Vector3.ZERO:
			global_position = sync_pos
		global_position = lerp(global_position, sync_pos, 0.5)
		if visible == false and last_sync_pos != sync_pos:
			visible = true
		last_sync_pos = sync_pos
		return
	if linear_velocity.y < 0:
		if !get_collision_mask_value(1):
			set_collision_mask_value(1,true)
	if not used:
		rotation = summoner.rotation
		var forward_dir = -transform.basis.z
		forward_dir.y = 0
		forward_dir = forward_dir.normalized()
		var last_pos = global_position
		position.x = summoner.position.x + (forward_dir.x*2)
		position.z = summoner.position.z + (forward_dir.z*2)
		linear_velocity.x = (global_position.x - last_pos.x)/delta
		linear_velocity.z = (global_position.z - last_pos.z)/delta
	sync_pos = global_position
	last_sync_pos = sync_pos
	last_vel = linear_velocity


@rpc("authority", "call_local")
func hit(from: Vector3):
	if used:
		return
	used = true
	if linear_velocity.y > 5:
		linear_velocity.y = lerp(5.0, linear_velocity.y, 0.5)
	from.y = lerp(from.y, global_position.y, 0.8)
	apply_central_impulse((global_position-from).normalized() * 30)
	remove_from_group("Interactables")
	deactivate()

func activate():
	$MeshInstance3D/Outline.visible = true
func deactivate():
	$MeshInstance3D/Outline.visible = false

func _on_body_entered(body: Node) -> void:
	if !is_multiplayer_authority(): return
	var damage = 2 * linear_velocity.length()
	var collider_path: NodePath = body.get_path()
	explode.rpc_id(1, collider_path, damage)

@rpc("authority", "call_local")
func explode(collider_path: NodePath, damage: int):
	delete.rpc()
	var target: Node = get_node_or_null(collider_path)
	if !target:
		return
	if target is Player and multiplayer.is_server():
		if last_sync_pos == Vector3.ZERO:
			last_sync_pos = global_position
		var knockback = knockback_calc((target.global_position - last_sync_pos).normalized())
		target.knockback.rpc(knockback)
		target.get_hit.rpc(damage)

@rpc("authority","call_local")
func delete():
	queue_free()

func knockback_calc(vector: Vector3):
	var xz = Vector3(vector.x, 0, vector.z)
	var weighted = xz.normalized() * 15 + last_vel * 1.5
	var final := Vector3(weighted.x,1,weighted.z)
	return final
