class_name Rock
extends RigidBody3D

var sync_pos : Vector3
var used := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

@rpc("authority", "call_local")
func setup():
	var forward_dir = -transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	position += (forward_dir*1.5)
	position.y = 0
	linear_velocity.y = 10
	#visible = true
	add_to_group("interactables")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		global_position = sync_pos
		return
	if position.y < -1:
		queue_free()
	if !get_collision_mask_value(1):
		if position.y > 0.7:
			set_collision_mask_value(1,true)
	sync_pos = global_position

@rpc("authority", "call_local")
func hit(from: Vector3):
	if used:
		return
	used = true
	apply_central_impulse((global_position-from).normalized() * 20)
	remove_from_group("Interactables")
	deactivate()

func activate():
	$MeshInstance3D/Outline.visible = true
func deactivate():
	$MeshInstance3D/Outline.visible = false

func _on_body_entered(body: Node) -> void:
	var damage = 2 * linear_velocity.length()
	var collider_path: NodePath = body.get_path()
	explode.rpc_id(1, collider_path, damage)

@rpc("authority", "call_local")
func explode(collider_path: NodePath, damage: int):
	queue_free()
	var target: Node = get_node_or_null(collider_path)
	if !target:
		return
	if target is Player and multiplayer.is_server():
		target.get_hit.rpc(damage)
