extends Node

# Autoload named Game Manager

signal local_health_changed(value: int)
signal game_paused
signal game_resumed

var pausable := true
var paused := false
var player_info := {}

const player_list_path := "/root/Root/Game/Game/Players/"

var spell_scenes : Dictionary[String, PackedScene] = {
	"Rock" = preload("res://spells/rock.tscn"),
	"Lightning" = preload("res://spells/lightning.tscn"),
}

func on_health_changed(value: int):
	local_health_changed.emit(value)

func create_rock(data):
	var projectile : Node = spell_scenes["Rock"].instantiate()
	projectile.position = data[2]
	projectile.rotation = data[3]
	var summoner_path = player_list_path + str(data[1])
	var summoner = get_node(summoner_path)
	projectile.summoner = summoner
	projectile.setup()
	return projectile

func on_game_paused():
	paused = true
	game_paused.emit()

func on_game_resumed():
	paused = false
	game_resumed.emit()
