extends RigidBody3D
class_name Goblin

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

#Gravity is real
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	pass

func _physics_process(delta):
	pass
