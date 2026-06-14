class_name Pause extends Node

signal game_paused
signal game_resumed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control.hide()
	game_paused.connect(GameManager.on_game_paused)
	game_resumed.connect(GameManager.on_game_resumed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and GameManager.pausable:
		if GameManager.paused:
			$Control.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			game_resumed.emit()
		else:
			$Control.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			game_paused.emit()


func resume():
	$Control.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_resumed.emit()



func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	get_tree().quit()
