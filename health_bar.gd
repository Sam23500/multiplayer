extends ProgressBar



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.local_health_changed.connect(on_health_changed)

func on_health_changed(new_value: int):
	value = new_value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
