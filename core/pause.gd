extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape") and $"..".pausable:
		$Control.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume():
	$Control.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	get_tree().quit()
