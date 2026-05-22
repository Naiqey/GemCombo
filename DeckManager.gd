class_name DeckManager
extends RefCounted

var card_pool: Array[GemCard] = []
var player_deck: Array[GemCard] = []
var draw_pile: Array[GemCard] = []
var discard_pile: Array[GemCard] = []

func load_card_resources(resource_dir: String):
	card_pool.clear()

	for file_name in DirAccess.get_files_at(resource_dir):
		if not file_name.ends_with(".tres"):
			continue

		var resource_path = resource_dir + "/" + file_name
		var card = load(resource_path) as GemCard
		if card == null:
			push_warning("跳过非卡牌资源: " + resource_path)
			continue
		if card.card_name.strip_edges().is_empty() or card.effects.is_empty():
			push_warning("跳过未完成卡牌资源: " + resource_path)
			continue

		card_pool.append(card)

func build_initial_player_deck(deck_size: int, max_cost: int, exact_cost := -1):
	player_deck.clear()
	var starter_candidates: Array[GemCard] = []
	for card in card_pool:
		if exact_cost >= 0 and card.cost == exact_cost:
			starter_candidates.append(card)
		elif exact_cost < 0 and card.cost <= max_cost:
			starter_candidates.append(card)

	if starter_candidates.is_empty():
		push_warning("没有符合条件的初始卡牌资源")
		return

	starter_candidates.shuffle()
	for i in range(deck_size):
		var template = starter_candidates[i % starter_candidates.size()]
		player_deck.append(template.duplicate(true) as GemCard)

func reset_draw_pile_from_player_deck():
	_rebuild_draw_pile_from_player_deck(true)

func rebuild_draw_pile_from_player_deck():
	# New turns rebuild from the player's owned deck; this intentionally clears all temporary piles.
	_rebuild_draw_pile_from_player_deck(true)

func _rebuild_draw_pile_from_player_deck(clear_discard: bool):
	draw_pile.clear()
	if clear_discard:
		discard_pile.clear()
	for card in player_deck:
		draw_pile.append(card.duplicate(true) as GemCard)
	draw_pile.shuffle()

func draw_card() -> GemCard:
	if draw_pile.is_empty():
		return null

	return draw_pile.pop_back()

func draw_card_for_effect(excluded_card: GemCard = null) -> GemCard:
	var card = draw_card()
	if card != null:
		return card

	var candidates: Array[GemCard] = []
	for discarded_card in discard_pile:
		if excluded_card != null and is_same_card_template(discarded_card, excluded_card):
			continue
		candidates.append(discarded_card)

	if candidates.is_empty():
		return null

	draw_pile = candidates.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
	return draw_pile.pop_back()

func draw_cards(count: int) -> Array[GemCard]:
	var cards: Array[GemCard] = []
	for i in range(count):
		var card = draw_card()
		if card == null:
			break
		cards.append(card)
	return cards

func refill_draw_pile_from_discard():
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

func discard_card(card_data: GemCard):
	discard_pile.append(card_data)

func discard_cards(cards: Array[GemCard]):
	for card in cards:
		discard_card(card)

func add_card_to_player_deck(card_data: GemCard, add_to_discard := true):
	player_deck.append(card_data.duplicate(true) as GemCard)
	if add_to_discard:
		discard_card(card_data.duplicate(true) as GemCard)

func get_reward_cards(count: int) -> Array[GemCard]:
	var candidates = card_pool.duplicate()
	var rewards: Array[GemCard] = []
	if candidates.is_empty():
		return rewards

	candidates.shuffle()
	for i in range(count):
		var template = candidates[i % candidates.size()]
		rewards.append(template.duplicate(true) as GemCard)
	return rewards

func is_same_card_template(a: GemCard, b: GemCard) -> bool:
	if a == null or b == null:
		return false
	return a.card_name == b.card_name and a.color == b.color and a.cost == b.cost
