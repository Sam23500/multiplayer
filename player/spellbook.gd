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

func is_spell_l_active():
	return _spells[_active_index].available_l

func is_spell_r_active():
	return _spells[_active_index].available_r

func start_cooldown_l():
	if _spells[_active_index].cooldown_l == 0: return 0
	_spells[_active_index].available_l = false
	return _spells[_active_index].cooldown_l
func start_cooldown_r():
	if _spells[_active_index].cooldown_r == 0: return 0
	_spells[_active_index].available_r = false
	return _spells[_active_index].cooldown_r

func end_cooldown_l():
	_spells[_active_index].available_l = true
func end_cooldown_r():
	_spells[_active_index].available_r = true

func set_active(index: int):
	if index >= MAX_SPELLS: return
	_active_index = index

func increment_active():
	_active_index = (_active_index+1)
	if _active_index == 3: _active_index = 0

func decrement_active():
	_active_index = (_active_index-1)
	if _active_index == -1: _active_index = 2

func append_spell(spell_name: String, cooldown_l: float, cooldown_r: float):
	var new_spell = Spell.new()
	new_spell.name = spell_name
	new_spell.cooldown_l = cooldown_l
	new_spell.cooldown_r = cooldown_r
	_spells.append(new_spell)
