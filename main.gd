extends Node2D

@onready var hand_container = $HandScroll/HandContainer
@onready var turn_label = $StatusPanel/TurnLabel
@onready var phase_label = $StatusPanel/PhaseLabel
@onready var combo_label = $StatusPanel/ComboLabel
@onready var hand_count_label = $StatusPanel/HandCountLabel
@onready var deck_count_label = $StatusPanel/DeckCountLabel
@onready var hand_limit_label = $HandLimitLabel
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
@onready var victory_window = $VictoryWindow
@onready var victory_restart_button = $VictoryWindow/VictoryWindowRoot/VictoryRestartButton
@onready var relic_window = $RelicWindow
@onready var relic_name_label = $RelicWindow/RelicWindowRoot/RelicNameLabel
@onready var relic_description_label = $RelicWindow/RelicWindowRoot/RelicDescriptionLabel
@onready var relic_take_button = $RelicWindow/RelicWindowRoot/RelicTakeButton
@onready var relic_skip_button = $RelicWindow/RelicWindowRoot/RelicSkipButton
@onready var curse_list_label = $CurseListLabel
@onready var relic_bar = $RelicBar
@onready var player_hp_label = $PlayerPanel/PlayerHpLabel
@onready var energy_label = $PlayerPanel/EnergyLabel
@onready var level_label = $PlayerPanel/LevelLabel
@onready var experience_label = $PlayerPanel/ExperienceLabel
@onready var block_label = $PlayerPanel/BlockLabel
@onready var end_turn_button = $EndTurnButton

const CARD_RESOURCE_DIR := "res://cards"
const BASE_PLAYER_ENERGY := 4
const STARTING_HAND_SIZE := 4
const STARTING_HAND_LIMIT := 6
const STARTING_CARD_COST := 1
const STARTING_CARD_MAX_COST := 1
const REWARD_CARD_COUNT := 3
const COMBO_VALUE_BONUS := 2
const EXPERIENCE_TO_LEVEL := 3
const SMALL_ENEMY_EXPERIENCE := 1
const SMALL_ENEMY_HEALTH := 5
const ENEMY_UNIT_SCENE := preload("res://enemy_unit.tscn")
const ALL_CARD_COLORS := [
	GemCard.GemColor.RED,
	GemCard.GemColor.YELLOW,
	GemCard.GemColor.BLUE,
	GemCard.GemColor.GREEN,
]

var hand_cards: Array[GemCard] = []
var deck_manager := DeckManager.new()
var enemy_waves := EnemyWaveManager.new()
var pending_reward_cards: Array[GemCard] = []
var queued_reward_count: int = 0
var turn_count: int = 1
var max_hand_size: int = STARTING_HAND_LIMIT

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
var active_curses: Array[String] = []
var pending_relic_rewards: int = 0
var player_relics: Array[RelicResource] = []
var pending_relic: RelicResource = null
var pending_victory_after_relic: bool = false

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
	victory_window.close_requested.connect(_on_victory_window_close_requested)
	victory_restart_button.pressed.connect(_on_restart_button_pressed)
	relic_window.close_requested.connect(_on_relic_window_close_requested)
	relic_take_button.pressed.connect(_on_relic_take_button_pressed)
	relic_skip_button.pressed.connect(_on_relic_skip_button_pressed)
	update_all_ui()

func _unhandled_input(event):
	if pending_target_card == null:
		return
	if event.is_action_pressed("ui_cancel"):
		clear_pending_target()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clear_pending_target()

func start_fresh_game():
	clear_hand()
	pending_reward_cards.clear()
	queued_reward_count = 0
	turn_count = 1
	reset_hand_limit()
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
	active_curses.clear()
	pending_relic_rewards = 0
	player_relics.clear()
	ComboManager.set_relics(player_relics)
	pending_relic = null
	pending_victory_after_relic = false
	end_turn_button.disabled = false
	ComboManager.break_combo()

	for child in reward_card_container.get_children():
		child.queue_free()
	reward_window.hide()
	pile_window.hide()
	death_window.hide()
	victory_window.hide()
	relic_window.hide()
	update_curse_ui()
	update_relic_ui()

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
		hand_container.remove_child(child)
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
	update_card_ui_display(card_ui, card_data)
	update_hand_ui()

func draw_card_from_draw_pile(excluded_card: GemCard = null):
	if hand_cards.size() >= max_hand_size:
		update_hand_ui()
		return

	var card = deck_manager.draw_card_for_effect(excluded_card) if excluded_card != null else deck_manager.draw_card()
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

	if pending_target_card == card_data:
		clear_pending_target()
		return

	if card_needs_target(card_data):
		if current_player_energy < get_current_card_cost(card_data):
			return
		pending_target_card = card_data
		enemy_tip_label.text = "选择一个敌人作为目标"
		refresh_enemy_list_ui()
		return

	play_card(card_data)

func clear_pending_target():
	pending_target_card = null
	update_enemy_ui()

func play_card(card_data: GemCard, target_index := -1):
	var play_cost = get_current_card_cost(card_data)
	if current_player_energy < play_cost:
		return

	current_player_energy -= play_cost
	update_energy_ui()

	ComboManager.attempt_play(card_data)
	var combo_bonus = ComboManager.current_combo * COMBO_VALUE_BONUS
	remove_card_from_hand(card_data)

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
					draw_card_from_draw_pile(card_data)
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
			EffectResource.EffectType.DISCARD_CARD:
				discard_cards_from_hand(effect_value)
			EffectResource.EffectType.APPLY_VULNERABLE:
				print("APPLY_VULNERABLE is not implemented yet. Value: ", effect_value)
			EffectResource.EffectType.APPLY_WEAK:
				print("APPLY_WEAK is not implemented yet. Value: ", effect_value)
			EffectResource.EffectType.DOUBLE_DAMAGE_NEXT:
				print("DOUBLE_DAMAGE_NEXT is not implemented yet.")

	discard_card(card_data)
	apply_after_play_curses()
	resolve_enemy_deaths()
	update_all_ui()

func reset_hand_limit():
	max_hand_size = STARTING_HAND_LIMIT

func card_needs_target(card_data: GemCard) -> bool:
	for effect in card_data.effects:
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE, EffectResource.EffectType.DEAL_DAMAGE_DOT, EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS, EffectResource.EffectType.APPLY_VULNERABLE, EffectResource.EffectType.APPLY_WEAK:
				return true
	return false

func remove_card_from_hand(card_data: GemCard):
	var index = hand_cards.find(card_data)
	if index == -1:
		return

	var card_ui = hand_container.get_child(index)
	hand_container.remove_child(card_ui)
	card_ui.queue_free()
	hand_cards.remove_at(index)
	update_hand_ui()

func discard_cards_from_hand(count: int):
	for i in range(max(0, count)):
		if hand_cards.is_empty():
			return
		var card = hand_cards.back()
		remove_card_from_hand(card)
		discard_card(card)

func get_current_card_cost(card_data: GemCard) -> int:
	return max(0, card_data.cost - hand_cost_reduction)

func get_preview_combo_count(card_data: GemCard) -> int:
	if ComboManager.last_card == null:
		return 0
	if ComboManager.can_combo(ComboManager.last_card, card_data):
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
	var dead_enemies = enemy_waves.collect_dead_enemies()
	for enemy in dead_enemies:
		gain_experience_for_enemy(enemy)
		if bool(enemy.get("is_boss", false)) or str(enemy.get("type", "")) == EnemyWaveManager.BOSS_ENEMY_TYPE:
			on_boss_defeated()

	var wave_cleared = not dead_enemies.is_empty() and not enemy_waves.has_alive_enemies()
	if wave_cleared:
		enemy_waves.advance_wave_if_cleared()
		if enemy_waves.is_complete:
			is_game_over = true
			is_player_turn = false
			end_turn_button.disabled = true
			if relic_window.visible:
				pending_victory_after_relic = true
			else:
				show_victory_window()
		else:
			if enemy_waves.is_current_wave_boss():
				apply_curse(enemy_waves.current_level_index)
			ComboManager.break_combo()
			reset_hand_limit()
			start_next_player_turn()

	update_enemy_ui()
	update_enemy_intent_ui()
	update_turn_ui()
	return wave_cleared

func gain_experience_for_enemy(enemy: Dictionary):
	if str(enemy.get("type", enemy.get("kind", ""))) != EnemyWaveManager.SMALL_ENEMY_TYPE:
		return

	player_experience += SMALL_ENEMY_EXPERIENCE
	while player_experience >= EXPERIENCE_TO_LEVEL:
		player_experience -= EXPERIENCE_TO_LEVEL
		level_up()
	update_experience_ui()

func on_boss_defeated():
	pending_relic_rewards += 1
	print("Boss defeated. Pending relic rewards: ", pending_relic_rewards)
	remove_curse_for_level(enemy_waves.current_level_index)
	show_relic_window()

func apply_curse(level_index: int):
	var curse_id = "CRS-%03d" % [level_index + 1]
	if active_curses.has(curse_id):
		return
	active_curses.append(curse_id)
	print("Applied curse: ", curse_id)
	update_curse_ui()

func remove_curse_for_level(level_index: int):
	var curse_id = "CRS-%03d" % [level_index + 1]
	active_curses.erase(curse_id)
	update_curse_ui()

func apply_after_play_curses():
	if active_curses.has("CRS-001"):
		randomize_hand_card_colors()

func randomize_hand_card_colors():
	for card in hand_cards:
		card.color = ALL_CARD_COLORS.pick_random()
	update_hand_ui()

func update_curse_ui():
	if active_curses.is_empty():
		curse_list_label.visible = false
		curse_list_label.text = ""
		return

	var curse_names: Array[String] = []
	for curse_id in active_curses:
		curse_names.append(get_curse_name(curse_id))
	curse_list_label.text = "诅咒: " + " / ".join(curse_names)
	curse_list_label.visible = true

func get_curse_name(curse_id: String) -> String:
	match curse_id:
		"CRS-001":
			return "变色诅咒"
	return curse_id

func level_up():
	player_level += 1
	player_strength += 1
	max_player_health += 5
	current_player_health = min(max_player_health, current_player_health + 5)
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
	victory_window.hide()
	relic_window.hide()
	death_window.popup()

func show_victory_window():
	reward_window.hide()
	pile_window.hide()
	death_window.hide()
	relic_window.hide()
	victory_window.popup()

func show_relic_window():
	pending_relic_rewards = max(0, pending_relic_rewards - 1)
	pending_relic = get_random_relic_reward()
	if pending_relic == null:
		return
	relic_name_label.text = pending_relic.relic_name
	relic_description_label.text = pending_relic.description
	relic_window.popup()

func get_random_relic_reward() -> RelicResource:
	var relics = get_relic_pool()
	if relics.is_empty():
		return null
	return relics.pick_random()

func get_relic_pool() -> Array[RelicResource]:
	return [
		create_relic("R-001", "奇数宝珠", "奇数费用牌之间也可以触发连击。", "combo_odd_cost"),
		create_relic("R-002", "偶数宝珠", "偶数费用牌之间也可以触发连击。", "combo_even_cost"),
		create_relic("R-003", "猫眼石", "蓝色牌与绿色牌之间也可以触发连击。", "combo_blue_green"),
		create_relic("R-004", "犬视晶", "黄色牌与蓝色牌之间也可以触发连击。", "combo_yellow_blue"),
		create_relic("R-005", "彩虹宝石", "效果待定。", "tbd"),
	]

func create_relic(relic_id: String, relic_name: String, description: String, effect_type: String) -> RelicResource:
	var relic = RelicResource.new()
	relic.relic_id = relic_id
	relic.relic_name = relic_name
	relic.description = description
	relic.effect_type = effect_type
	return relic

func close_relic_window():
	relic_window.hide()
	pending_relic = null
	if pending_victory_after_relic:
		pending_victory_after_relic = false
		show_victory_window()

func update_relic_ui():
	for child in relic_bar.get_children():
		relic_bar.remove_child(child)
		child.queue_free()

	relic_bar.visible = not player_relics.is_empty()
	if player_relics.is_empty():
		return

	for relic in player_relics:
		var label = Label.new()
		label.text = relic.relic_name
		label.tooltip_text = relic.description
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.54, 1.0))
		label.add_theme_font_size_override("font_size", 15)
		relic_bar.add_child(label)

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
		var enemy_unit = ENEMY_UNIT_SCENE.instantiate()
		enemy_unit.setup(enemy, i, enemy_waves.get_current_level_number())
		enemy_unit.set_target_highlight(pending_target_card != null and enemy_waves.is_enemy_alive(i))
		enemy_unit.enemy_clicked.connect(_on_enemy_target_pressed)
		enemy_list_container.add_child(enemy_unit)

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
	experience_label.text = "经验: " + str(player_experience) + "/" + str(EXPERIENCE_TO_LEVEL) + "  力量: " + str(player_strength)

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
	update_hand_limit_label()
	hand_count_label.text = "手牌: " + str(hand_cards.size()) + " / " + str(max_hand_size)
	deck_count_label.text = "抽:" + str(deck_manager.draw_pile.size()) + " 弃:" + str(deck_manager.discard_pile.size()) + " 组:" + str(deck_manager.player_deck.size())
	draw_pile_button.text = "抽牌堆 " + str(deck_manager.draw_pile.size())
	discard_pile_button.text = "弃牌堆 " + str(deck_manager.discard_pile.size())

	while hand_container.get_child_count() > hand_cards.size():
		var stale_card_ui = hand_container.get_child(hand_container.get_child_count() - 1)
		hand_container.remove_child(stale_card_ui)
		stale_card_ui.queue_free()

	for i in range(hand_container.get_child_count()):
		var card_ui = hand_container.get_child(i)
		if i < hand_cards.size():
			update_card_ui_display(card_ui, hand_cards[i])

	if pile_window.visible:
		refresh_pile_window()

func update_card_ui_display(card_ui: Node, card: GemCard):
	if card_ui.has_method("set_display_context"):
		var current_cost = get_current_card_cost(card)
		card_ui.set_display_context(current_cost, player_strength, turn_strength, get_preview_combo_bonus(card), current_player_energy >= current_cost)

func update_hand_limit_label():
	hand_limit_label.text = str(hand_cards.size()) + "/" + str(max_hand_size)

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

func _on_victory_window_close_requested():
	victory_window.popup()

func _on_relic_window_close_requested():
	relic_window.popup()

func _on_relic_take_button_pressed():
	if pending_relic != null:
		player_relics.append(pending_relic)
		ComboManager.set_relics(player_relics)
		update_relic_ui()
	close_relic_window()

func _on_relic_skip_button_pressed():
	close_relic_window()

func _on_combo_updated(_combo: int):
	update_combo_ui()
	update_hand_ui()

func _on_combo_broken():
	update_combo_ui()
	update_hand_ui()
