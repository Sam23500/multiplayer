extends ProgressBar
@onready var player: Player = $"../.."



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_value = player.max_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value = player.health
