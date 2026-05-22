extends Node

signal combo_updated(combo: int)
signal combo_broken

var current_combo: int = 0
var last_card: GemCard = null
var active_relic_ids: Array[String] = []

func set_relics(relics: Array):
	active_relic_ids.clear()
	for relic in relics:
		var relic_id = str(relic.get("relic_id")) if relic != null else ""
		if not relic_id.is_empty():
			active_relic_ids.append(relic_id)

func attempt_play(card: GemCard) -> bool:
	if last_card == null:
		current_combo = 0
		last_card = card
		combo_updated.emit(current_combo)
		return true
	
	if can_combo(last_card, card):
		current_combo += 1
		last_card = card
		combo_updated.emit(current_combo)
		return true
	else:
		break_combo()
		return false

func can_combo(previous_card: GemCard, current_card: GemCard) -> bool:
	if previous_card == null or current_card == null:
		return false
	if previous_card.color == current_card.color:
		return true
	if previous_card.cost == current_card.cost:
		return true
	for relic_id in active_relic_ids:
		if check_relic_combo(relic_id, previous_card, current_card):
			return true
	return false

func check_relic_combo(relic_id: String, previous_card: GemCard, current_card: GemCard) -> bool:
	match relic_id:
		"R-001":
			return previous_card.cost % 2 == 1 and current_card.cost % 2 == 1
		"R-002":
			return previous_card.cost % 2 == 0 and current_card.cost % 2 == 0
		"R-003":
			return _color_pair_matches(previous_card, current_card, GemCard.GemColor.BLUE, GemCard.GemColor.GREEN)
		"R-004":
			return _color_pair_matches(previous_card, current_card, GemCard.GemColor.YELLOW, GemCard.GemColor.BLUE)
	return false

func _color_pair_matches(a: GemCard, b: GemCard, first_color: GemCard.GemColor, second_color: GemCard.GemColor) -> bool:
	return (a.color == first_color and b.color == second_color) or (a.color == second_color and b.color == first_color)

func break_combo():
	current_combo = 0
	last_card = null
	combo_broken.emit()
	combo_updated.emit(current_combo)
