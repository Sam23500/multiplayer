extends Node

@export var game_scene: PackedScene
var dedicated_correction := 0

@onready var connection_timer: Timer = $ConnectionTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MainMenuStuff/PlayersJoined.visible = false
	$MainMenuStuff/ButtonContainer/Start.pressed.connect(load_game.rpc)
	$MainMenuStuff/ButtonContainer/Host.pressed.connect(NetworkManager.create_game)
	$MainMenuStuff/ButtonContainer/Join.pressed.connect(join_game)
	
	$"MainMenuStuff/ButtonContainer/Quit".pressed.connect(get_tree().quit)
	$MainMenuStuff/ButtonContainer/Start.grab_focus()  # for keyboard/controller use
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

func _on_player_connected(pid, info):
	connection_timer.stop()
	if info["connection_type"] == "dedicated":
		dedicated_correction = 1
	$MainMenuStuff/PlayersJoined.text = "Players in Lobby: %s" %(NetworkManager.players.size() - dedicated_correction)
	$MainMenuStuff/PlayersJoined.visible = true
		
func _on_player_disconnected(_pid):
	$MainMenuStuff/PlayersJoined.text = "Players in Lobby: %s" %(NetworkManager.players.size() - dedicated_correction)

# If any player presses this, it starts the game for everyone
@rpc("any_peer", "call_local", "reliable")
func load_game():
	if NetworkManager.players[1].is_empty():
		NetworkManager.create_game()
	if multiplayer.is_server():
		# only server loads scene. MultiplayerSpawner spawns it for everyone
		var level = game_scene.instantiate()
		$Game.add_child(level)
	$Background.visible = false
	$MainMenuStuff.visible = false
	
func join_game():
	print(multiplayer.get_unique_id())
	NetworkManager.join_game($MainMenuStuff/HostIP.text)
	# Start a timer to check if joining
	connection_timer.start()
	$MainMenuStuff/PlayersJoined.text = "Joining..."
	$MainMenuStuff/PlayersJoined.visible = true


func _on_connection_timer_timeout() -> void:
	NetworkManager._on_connected_fail()
	$MainMenuStuff/PlayersJoined.text = "Connection Timed Out"

func _on_server_disconnected() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Back to main menu
	var levels_children = $Game.get_children()
	for child in levels_children:
		if child is not MultiplayerSpawner:
			child.queue_free()
	
	$MainMenuStuff.visible = true
	$Background.visible = true
	$MainMenuStuff/PlayersJoined.text = "Lost Connection to Server"


func _on_name_changed(new_text: String) -> void:
	NetworkManager.update_name.rpc(new_text)
