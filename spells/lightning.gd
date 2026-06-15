class_name Lightning extends Node3D

var length := 0.0
var summoner := Player

var shot_scene := preload("res://spells/lightning_shot.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	length += delta * 5

func start():
	length = 0
	process_mode = Node.PROCESS_MODE_INHERIT

func shoot():
	if length != 0:
		var bolt = shot_scene.instantiate()
		bolt.length = length
		add_child(bolt)
	length = 0
	process_mode = Node.PROCESS_MODE_DISABLED
	
