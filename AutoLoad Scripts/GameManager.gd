extends Node

# Autoload named Game Manager

signal local_health_changed(value: int)

var player_info := {}

var spell_scenes : Dictionary[String, PackedScene] = {
	"Rock" = preload("res://spells/rock.tscn"),
	"Lightning" = preload("res://spells/lightning.tscn"),
}

func on_health_changed(value: int):
	local_health_changed.emit(value)

func create_rock(data):
	var projectile : Node = spell_scenes[data[0]].instantiate()
	projectile.position = data[2]
	projectile.rotation = data[3]
	var summoner_path = "/root/Root/Game/Game/Players/" + str(data[1])
	var summoner = get_node(summoner_path)
	projectile.summoner = summoner
	projectile.setup()
	return projectile
