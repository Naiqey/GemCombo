extends Node2D

@onready var hand_container = $HandContainer
@onready var turn_label = $StatusPanel/TurnLabel
@onready var phase_label = $StatusPanel/PhaseLabel
@onready var combo_label = $StatusPanel/ComboLabel
@onready var hand_count_label = $StatusPanel/HandCountLabel
@onready var deck_count_label = $StatusPanel/DeckCountLabel
@onready var enemy_name_label = $EnemyPanel/EnemyNameLabel
@onready var enemy_hp_label = $EnemyPanel/EnemyHpLabel
@onready var enemy_intent_label = $EnemyPanel/EnemyIntentLabel
@onready var enemy_tip_label = $EnemyPanel/EnemyTipLabel
@onready var enemy_list_container = $EnemyPanel/EnemyListContainer
@onready var draw_pile_button = $DrawPileButton
@onready var discard_pile_button = $DiscardPileButton
@onready var pile_window = $PileWindow
@onready var pile_window_title_label = $PileWindow/PileWindowRoot/PileWindowTitleLabel
@onready var pile_empty_label = $PileWindow/PileWindowRoot/PileEmptyLabel
@onready var pile_card_grid = $PileWindow/PileWindowRoot/PileScroll/PileCardGrid
@onready var reward_window = $RewardWindow
@onready var reward_card_container = $RewardWindow/RewardWindowRoot/RewardCardContainer
@onready var death_window = $DeathWindow
@onready var restart_button = $DeathWindow/DeathWindowRoot/RestartButton
@onready var player_hp_label = $PlayerPanel/PlayerHpLabel
@onready var energy_label = $PlayerPanel/EnergyLabel
@onready var level_label = $PlayerPanel/LevelLabel
@onready var experience_label = $PlayerPanel/ExperienceLabel
@onready var block_label = $PlayerPanel/BlockLabel
@onready var end_turn_button = $EndTurnButton

const CARD_RESOURCE_DIR := "res://cards"
const BASE_PLAYER_ENERGY := 4
const STARTING_HAND_SIZE := 4
const STARTING_CARD_COST := 1
const STARTING_CARD_MAX_COST := 1
const REWARD_CARD_COUNT := 3
const COMBO_VALUE_BONUS := 2

var hand_cards: Array[GemCard] = []
var deck_manager := DeckManager.new()
var enemy_waves := EnemyWaveManager.new()
var pending_reward_cards: Array[GemCard] = []
var queued_reward_count: int = 0
var turn_count: int = 1
var max_hand_size: int = STARTING_HAND_SIZE

var max_player_health: int = 30
var current_player_health: int = 30
var player_level: int = 1
var player_experience: int = 0
var player_strength: int = 0

var current_player_energy_max: int = BASE_PLAYER_ENERGY
var current_player_energy: int = BASE_PLAYER_ENERGY
var current_player_block: int = 0
var current_player_shield: int = 0
var turn_strength: int = 0
var turn_resistance: int = 0
var hand_cost_reduction: int = 0
var next_turn_energy_bonus: int = 0
var is_invincible: bool = false

var is_player_turn: bool = true
var is_game_over: bool = false
var current_pile_window_is_discard: bool = false
var pending_target_card: GemCard = null

func _ready():
	randomize()
	deck_manager.load_card_resources(CARD_RESOURCE_DIR)
	start_fresh_game()
	ComboManager.combo_updated.connect(_on_combo_updated)
	ComboManager.combo_broken.connect(_on_combo_broken)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	draw_pile_button.pressed.connect(_on_draw_pile_button_pressed)
	discard_pile_button.pressed.connect(_on_discard_pile_button_pressed)
	pile_window.close_requested.connect(_on_pile_window_close_requested)
	reward_window.close_requested.connect(_on_reward_window_close_requested)
	death_window.close_requested.connect(_on_death_window_close_requested)
	restart_button.pressed.connect(_on_restart_button_pressed)
	update_all_ui()

func start_fresh_game():
	clear_hand()
	pending_reward_cards.clear()
	queued_reward_count = 0
	turn_count = 1
	max_hand_size = STARTING_HAND_SIZE
	max_player_health = 30
	current_player_health = max_player_health
	player_level = 1
	player_experience = 0
	player_strength = 0
	current_player_energy_max = BASE_PLAYER_ENERGY
	current_player_energy = BASE_PLAYER_ENERGY
	current_player_block = 0
	current_player_shield = 0
	turn_strength = 0
	turn_resistance = 0
	hand_cost_reduction = 0
	next_turn_energy_bonus = 0
	is_invincible = false
	is_player_turn = true
	is_game_over = false
	current_pile_window_is_discard = false
	end_turn_button.disabled = false
	ComboManager.break_combo()

	for child in reward_card_container.get_children():
		child.queue_free()
	reward_window.hide()
	pile_window.hide()
	death_window.hide()

	deck_manager.build_initial_player_deck(STARTING_HAND_SIZE, STARTING_CARD_MAX_COST, STARTING_CARD_COST)
	deck_manager.reset_draw_pile_from_player_deck()
	enemy_waves.setup()
	draw_initial_hand()

func draw_initial_hand():
	for i in range(STARTING_HAND_SIZE):
		draw_card_from_draw_pile()

func clear_hand():
	pending_target_card = null
	hand_cards.clear()
	for child in hand_container.get_children():
		child.queue_free()

func add_card_to_hand(card_data: GemCard):
	if hand_cards.size() >= max_hand_size:
		update_hand_ui()
		return

	var card_ui_scene = preload("res://card_ui.tscn")
	var card_ui = card_ui_scene.instantiate()
	card_ui.card_data = card_data
	card_ui.card_played.connect(_on_card_played)
	hand_container.add_child(card_ui)
	hand_cards.append(card_data)
	update_hand_ui()

func draw_card_from_draw_pile():
	if hand_cards.size() >= max_hand_size:
		update_hand_ui()
		return

	var card = deck_manager.draw_card()
	if card == null:
		push_warning("抽牌堆为空，无法抽牌")
		return

	add_card_to_hand(card)

func discard_card(card_data: GemCard):
	deck_manager.discard_card(card_data)
	update_hand_ui()

func draw_new_turn_hand():
	rebuild_hand_and_draw_pile_for_new_turn()
	var empty_slots = max_hand_size - hand_cards.size()
	for card in deck_manager.draw_cards(empty_slots):
		add_card_to_hand(card)

func rebuild_hand_and_draw_pile_for_new_turn():
	clear_hand()
	deck_manager.rebuild_draw_pile_from_player_deck()
	update_hand_ui()

func _on_card_played(card_data: GemCard):
	if is_game_over or not is_player_turn:
		return

	if card_needs_target(card_data):
		if current_player_energy < get_current_card_cost(card_data):
			return
		pending_target_card = card_data
		enemy_tip_label.text = "选择一个敌人作为目标"
		refresh_enemy_list_ui()
		return

	play_card(card_data)

func play_card(card_data: GemCard, target_index := -1):
	var play_cost = get_current_card_cost(card_data)
	if current_player_energy < play_cost:
		return

	current_player_energy -= play_cost
	update_energy_ui()

	var combo_triggered = ComboManager.attempt_play(card_data)
	var combo_bonus = ComboManager.current_combo * COMBO_VALUE_BONUS if combo_triggered else 0
	remove_card_from_hand(card_data)
	discard_card(card_data)

	for effect in card_data.effects:
		var effect_value = get_effect_value(effect, combo_bonus)
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE:
				deal_damage_to_enemy(target_index, get_attack_effect_value(effect, combo_bonus), "单体伤害")
			EffectResource.EffectType.DEAL_DAMAGE_AOE:
				deal_damage_to_all_enemies(get_attack_effect_value(effect, combo_bonus), "群体伤害")
			EffectResource.EffectType.DEAL_DAMAGE_DOT:
				apply_enemy_dot(target_index, effect_value, effect.duration)
			EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS:
				var dot_bonus = 3 if enemy_waves.enemy_has_dot(target_index) else 0
				deal_damage_to_enemy(target_index, get_attack_effect_value(effect, combo_bonus) + dot_bonus, "DoT 加成伤害")
			EffectResource.EffectType.GAIN_BLOCK:
				current_player_block += effect_value
			EffectResource.EffectType.GAIN_HEALTH_REGEN:
				current_player_health = min(max_player_health, current_player_health + effect_value)
			EffectResource.EffectType.GAIN_INVINCIBLE:
				is_invincible = true
			EffectResource.EffectType.DRAW_CARD:
				for i in range(effect_value):
					draw_card_from_draw_pile()
			EffectResource.EffectType.GAIN_ENERGY:
				current_player_energy_max += effect_value
				current_player_energy += effect_value
			EffectResource.EffectType.INCREASE_HAND_LIMIT:
				max_hand_size += effect_value
			EffectResource.EffectType.GAIN_STRENGTH_TURN:
				turn_strength += effect_value
			EffectResource.EffectType.GAIN_RESISTANCE_TURN:
				turn_resistance += effect_value
			EffectResource.EffectType.GAIN_ENERGY_NEXT_TURN:
				next_turn_energy_bonus += effect_value
			EffectResource.EffectType.REDUCE_HAND_COST_TURN:
				hand_cost_reduction += effect_value
			EffectResource.EffectType.RESET_ENERGY:
				current_player_energy = current_player_energy_max
			EffectResource.EffectType.GAIN_SHIELD:
				current_player_shield += effect_value

	resolve_enemy_deaths()
	update_all_ui()

func card_needs_target(card_data: GemCard) -> bool:
	for effect in card_data.effects:
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE, EffectResource.EffectType.DEAL_DAMAGE_DOT, EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS:
				return true
	return false

func remove_card_from_hand(card_data: GemCard):
	var index = hand_cards.find(card_data)
	if index == -1:
		return

	var card_ui = hand_container.get_child(index)
	card_ui.queue_free()
	hand_cards.remove_at(index)
	update_hand_ui()

func get_current_card_cost(card_data: GemCard) -> int:
	return max(0, card_data.cost - hand_cost_reduction)

func get_preview_combo_count(card_data: GemCard) -> int:
	if ComboManager.last_card == null:
		return 0
	if card_data.color == ComboManager.last_card.color or card_data.cost == ComboManager.last_card.cost:
		return ComboManager.current_combo + 1
	return 0

func get_preview_combo_bonus(card_data: GemCard) -> int:
	return get_preview_combo_count(card_data) * COMBO_VALUE_BONUS

func get_effect_value(effect: EffectResource, combo_bonus: int) -> int:
	if effect.value <= 0:
		return effect.value
	return effect.value + combo_bonus

func get_attack_effect_value(effect: EffectResource, combo_bonus: int) -> int:
	return get_effect_value(effect, combo_bonus) + player_strength + turn_strength

func deal_damage_to_enemy(target_index: int, amount: int, source: String):
	if target_index == -1:
		enemy_waves.damage_first_alive(amount)
	else:
		enemy_waves.damage_enemy(target_index, amount)
	update_enemy_ui()
	print(source, " 造成 ", amount, " 伤害")

func deal_damage_to_all_enemies(amount: int, source: String):
	enemy_waves.damage_all_alive(amount)
	update_enemy_ui()
	print(source, " 对所有敌人造成 ", amount, " 伤害")

func apply_enemy_dot(target_index: int, damage: int, duration: int):
	if target_index == -1:
		target_index = enemy_waves.get_first_alive_index()
	enemy_waves.apply_dot(target_index, damage, duration)
	update_enemy_ui()

func tick_enemy_dot():
	enemy_waves.tick_dots()
	update_enemy_ui()

func resolve_enemy_deaths() -> bool:
	var dead_count = enemy_waves.collect_dead_enemy_count()
	for i in range(dead_count):
		level_up()

	var wave_cleared = dead_count > 0 and not enemy_waves.has_alive_enemies()
	if wave_cleared:
		enemy_waves.advance_wave_if_cleared()
		if enemy_waves.is_complete:
			is_game_over = true
			is_player_turn = false
			end_turn_button.disabled = true
		else:
			start_next_player_turn()

	update_enemy_ui()
	update_enemy_intent_ui()
	update_turn_ui()
	return wave_cleared

func level_up():
	player_level += 1
	player_strength += 1
	max_player_health += 5
	current_player_health = min(max_player_health, current_player_health + 5)
	player_experience = 0
	queued_reward_count += 1
	try_open_next_card_reward()
	update_player_ui()
	update_experience_ui()

func _on_end_turn_pressed():
	if is_game_over or not is_player_turn:
		return

	is_player_turn = false
	pending_target_card = null
	update_turn_ui()

	tick_enemy_dot()
	if resolve_enemy_deaths():
		update_all_ui()
		return

	if not is_game_over and enemy_waves.has_alive_enemies():
		enemy_attack()
		if is_game_over:
			update_all_ui()
			return

	ComboManager.break_combo()
	start_next_player_turn()

func start_next_player_turn():
	turn_count += 1
	is_player_turn = true
	current_player_energy_max = BASE_PLAYER_ENERGY + next_turn_energy_bonus
	current_player_energy = current_player_energy_max
	next_turn_energy_bonus = 0
	current_player_block = 0
	current_player_shield = 0
	turn_strength = 0
	turn_resistance = 0
	hand_cost_reduction = 0
	is_invincible = false
	draw_new_turn_hand()
	update_all_ui()

func enemy_attack():
	var damage = enemy_waves.get_total_attack_damage()
	if is_invincible:
		damage = 0
	elif current_player_shield > 0:
		var absorbed_by_shield = min(current_player_shield, damage)
		damage -= absorbed_by_shield
		current_player_shield = 0

	if damage > 0 and current_player_block > 0:
		var absorbed_by_block = min(current_player_block, damage)
		current_player_block -= absorbed_by_block
		damage -= absorbed_by_block

	damage = max(0, damage - turn_resistance)
	current_player_health = max(0, current_player_health - damage)
	if current_player_health <= 0:
		is_game_over = true
		is_player_turn = false
		end_turn_button.disabled = true
		show_death_window()

	update_all_ui()

func show_death_window():
	reward_window.hide()
	pile_window.hide()
	death_window.popup()

func update_enemy_ui():
	enemy_name_label.text = enemy_waves.get_wave_title()
	enemy_hp_label.text = "存活: " + str(enemy_waves.get_alive_enemy_count()) + " / " + str(enemy_waves.enemies.size())
	refresh_enemy_list_ui()
	if pending_target_card != null:
		enemy_tip_label.text = "选择一个敌人作为目标"
	elif enemy_waves.is_complete:
		enemy_tip_label.text = "胜利"
	else:
		enemy_tip_label.text = enemy_waves.get_progress_text()

func update_enemy_intent_ui():
	enemy_intent_label.text = "本回合: 共攻击 " + str(enemy_waves.get_total_attack_damage())

func refresh_enemy_list_ui():
	for child in enemy_list_container.get_children():
		child.queue_free()

	for i in range(enemy_waves.enemies.size()):
		var enemy = enemy_waves.enemies[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(190, 56)
		button.text = get_enemy_button_text(enemy)
		button.disabled = not enemy_waves.is_enemy_alive(i)
		button.pressed.connect(_on_enemy_target_pressed.bind(i))
		enemy_list_container.add_child(button)

func get_enemy_button_text(enemy: Dictionary) -> String:
	var text = str(enemy["name"]) + "  " + str(enemy["health"]) + "/" + str(enemy["max_health"]) + " HP"
	text += "\nATK " + str(enemy.get("attack", 0))
	var dot_duration = int(enemy.get("dot_duration", 0))
	if dot_duration > 0:
		text += "  DoT " + str(enemy.get("dot_damage", 0)) + " x " + str(dot_duration)
	return text

func _on_enemy_target_pressed(enemy_index: int):
	if pending_target_card == null or not enemy_waves.is_enemy_alive(enemy_index):
		return

	var card = pending_target_card
	pending_target_card = null
	play_card(card, enemy_index)

func update_player_ui():
	player_hp_label.text = "血量: " + str(current_player_health) + " / " + str(max_player_health)

func update_experience_ui():
	level_label.text = "等级: " + str(player_level)
	experience_label.text = "力量: " + str(player_strength)

func update_energy_ui():
	energy_label.text = "费用: " + str(current_player_energy) + " / " + str(current_player_energy_max)

func update_block_ui():
	var status_parts: Array[String] = ["护甲: " + str(current_player_block), "力量: " + str(player_strength)]
	if current_player_shield > 0:
		status_parts.append("护盾: " + str(current_player_shield))
	if turn_resistance > 0:
		status_parts.append("抗性: " + str(turn_resistance))
	if turn_strength > 0:
		status_parts.append("本回合力量: " + str(turn_strength))
	if hand_cost_reduction > 0:
		status_parts.append("减费: " + str(hand_cost_reduction))
	if is_invincible:
		status_parts.append("无敌")

	var status_text := ""
	for part in status_parts:
		if not status_text.is_empty():
			status_text += " / "
		status_text += part
	block_label.text = status_text

func update_turn_ui():
	turn_label.text = "回合 " + str(turn_count)
	if is_game_over:
		phase_label.text = "胜利" if enemy_waves.is_complete else "游戏结束"
	else:
		phase_label.text = "玩家行动" if is_player_turn else "敌人行动"
	update_enemy_ui()

func update_combo_ui():
	combo_label.text = "连击: " + str(ComboManager.current_combo)

func update_hand_ui():
	hand_count_label.text = "手牌: " + str(hand_cards.size()) + " / " + str(max_hand_size)
	deck_count_label.text = "抽:" + str(deck_manager.draw_pile.size()) + " 弃:" + str(deck_manager.discard_pile.size()) + " 组:" + str(deck_manager.player_deck.size())
	draw_pile_button.text = "抽牌堆 " + str(deck_manager.draw_pile.size())
	discard_pile_button.text = "弃牌堆 " + str(deck_manager.discard_pile.size())

	for i in range(hand_container.get_child_count()):
		var card_ui = hand_container.get_child(i)
		if card_ui.has_method("set_display_context") and i < hand_cards.size():
			var card = hand_cards[i]
			card_ui.set_display_context(get_current_card_cost(card), player_strength, turn_strength, get_preview_combo_bonus(card))

	if pile_window.visible:
		refresh_pile_window()

func update_all_ui():
	update_enemy_ui()
	update_enemy_intent_ui()
	update_player_ui()
	update_experience_ui()
	update_energy_ui()
	update_block_ui()
	update_turn_ui()
	update_combo_ui()
	update_hand_ui()

func _on_draw_pile_button_pressed():
	open_pile_window(false)

func _on_discard_pile_button_pressed():
	open_pile_window(true)

func open_pile_window(show_discard: bool):
	current_pile_window_is_discard = show_discard
	refresh_pile_window()
	pile_window.popup()

func refresh_pile_window():
	var pile = deck_manager.discard_pile if current_pile_window_is_discard else deck_manager.draw_pile
	var title = "弃牌堆" if current_pile_window_is_discard else "抽牌堆"
	pile_window.title = title
	pile_window_title_label.text = title + " " + str(pile.size()) + " 张"
	pile_empty_label.visible = pile.is_empty()

	for child in pile_card_grid.get_children():
		child.queue_free()

	var card_ui_scene = preload("res://card_ui.tscn")
	for card in pile:
		var card_ui = card_ui_scene.instantiate()
		card_ui.card_data = card
		card_ui.is_preview = true
		card_ui.custom_minimum_size = Vector2(120, 170)
		pile_card_grid.add_child(card_ui)

func _on_pile_window_close_requested():
	pile_window.hide()

func open_card_reward_window():
	pending_reward_cards = deck_manager.get_reward_cards(REWARD_CARD_COUNT)
	for child in reward_card_container.get_children():
		child.queue_free()

	var card_ui_scene = preload("res://card_ui.tscn")
	for card in pending_reward_cards:
		var card_ui = card_ui_scene.instantiate()
		card_ui.card_data = card
		card_ui.card_played.connect(_on_reward_card_selected)
		reward_card_container.add_child(card_ui)

	reward_window.popup()

func try_open_next_card_reward():
	if reward_window.visible or not pending_reward_cards.is_empty() or queued_reward_count <= 0:
		return
	queued_reward_count -= 1
	open_card_reward_window()

func _on_reward_card_selected(card_data: GemCard):
	deck_manager.add_card_to_player_deck(card_data)
	reward_window.hide()
	for child in reward_card_container.get_children():
		child.queue_free()
	pending_reward_cards.clear()
	update_hand_ui()
	try_open_next_card_reward()

func _on_reward_window_close_requested():
	reward_window.popup()

func _on_restart_button_pressed():
	start_fresh_game()
	update_all_ui()

func _on_death_window_close_requested():
	death_window.popup()

func _on_combo_updated(_combo: int):
	update_combo_ui()
	update_hand_ui()

func _on_combo_broken():
	update_combo_ui()
	update_hand_ui()
