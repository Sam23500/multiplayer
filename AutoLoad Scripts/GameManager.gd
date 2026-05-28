extends Node

# Autoload named Game Manager

signal local_health_changed(value: int)

var player_info := {}

func on_health_changed(value: int):
	local_health_changed.emit(value)
