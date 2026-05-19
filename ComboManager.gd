extends Node

signal combo_updated(combo: int)
signal combo_broken

var current_combo: int = 0
var last_card: GemCard = null

func attempt_play(card: GemCard) -> bool:
	if last_card == null:
		current_combo = 0
		last_card = card
		combo_updated.emit(current_combo)
		return true
	
	if card.color == last_card.color or card.cost == last_card.cost:
		current_combo += 1
		last_card = card
		combo_updated.emit(current_combo)
		return true
	else:
		break_combo()
		return false

func break_combo():
	current_combo = 0
	last_card = null
	combo_broken.emit()
	combo_updated.emit(current_combo)
