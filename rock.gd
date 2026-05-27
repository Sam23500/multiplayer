class_name Rock
extends RigidBody3D

var sync_pos : Vector3
var used := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var forward_dir = -global_transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	global_position += (forward_dir*1.5)
	global_position.y = 0
	linear_velocity.y = 10
	add_to_group("interactables")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		global_position = sync_pos
		return
	sync_pos = global_position
	if position.y < -1:
		queue_free()
	if !get_collision_mask_value(1):
		if position.y > 0.5:
			set_collision_mask_value(1,true)
	sync_pos = global_position

func hit(from: Vector3):
	if used:
		return
	used = true
	apply_central_impulse((global_position-from).normalized() * 10)
	remove_from_group("Interactables")
	deactivate()

func activate():
	$MeshInstance3D/Outline.visible = true
func deactivate():
	$MeshInstance3D/Outline.visible = false

func _on_body_entered(body: Node) -> void:
	queue_free()
