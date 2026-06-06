class_name LightningShot extends Area3D

var length : float

@onready var mesh = $MeshInstance3D
@onready var hitbox = $CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var forward_dir = -transform.basis.z
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	position += forward_dir*(length/2+0.5)
	mesh.mesh.height = length
	hitbox.shape.height = length

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
