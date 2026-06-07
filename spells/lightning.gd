extends Node3D

var length := 0.0

var shot_scene := preload("res://spells/lightning_shot.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	length += delta * 5

func shoot():
	var bolt = shot_scene.instantiate()
	bolt.length = length
	add_child(bolt)
