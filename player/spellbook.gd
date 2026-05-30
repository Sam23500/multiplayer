class_name SpellBook
extends Resource

const MAX_SPELLS := 3
var _active_index := 0
var _spells : Array[Spell]

func get_active_spell_name() -> String:
	if _spells.size() - 1 < _active_index:
		var blank_spell = Spell.new()
		blank_spell.name = "Empty"
		_spells.append(blank_spell)
	return _spells[_active_index].name

func increment_active():
	_active_index = (_active_index+1)%3

func decrement_active():
	_active_index = (_active_index-1)%3

func append_spell(spell_name: String, scene: PackedScene, cooldown_time: float):
	var new_spell = Spell.new()
	new_spell.name = spell_name
	new_spell.cooldown_time = cooldown_time
	_spells.append(new_spell)
