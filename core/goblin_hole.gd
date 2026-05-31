extends StaticBody3D

const COOLDOWN: int = 3
var active: bool = false
var player: Player
var goblin: PackedScene = preload("res://core/goblin.tscn")

func activate():
	active = true
	
func deactivate():
	active = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	activate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and active:
		print("Pressed")
		spawn_friend()

func spawn_friend():
	var new_goblin: Goblin = goblin.instantiate()
	new_goblin.position.y = 50
	add_child(new_goblin)
