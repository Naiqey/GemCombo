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
@onready var draw_pile_button = $DrawPileButton
@onready var discard_pile_button = $DiscardPileButton
@onready var pile_window = $PileWindow
@onready var pile_window_title_label = $PileWindow/PileWindowRoot/PileWindowTitleLabel
@onready var pile_empty_label = $PileWindow/PileWindowRoot/PileEmptyLabel
@onready var pile_card_grid = $PileWindow/PileWindowRoot/PileScroll/PileCardGrid
@onready var reward_window = $RewardWindow
@onready var reward_card_container = $RewardWindow/RewardWindowRoot/RewardCardContainer
@onready var player_hp_label = $PlayerPanel/PlayerHpLabel
@onready var energy_label = $PlayerPanel/EnergyLabel
@onready var level_label = $PlayerPanel/LevelLabel
@onready var experience_label = $PlayerPanel/ExperienceLabel
@onready var block_label = $PlayerPanel/BlockLabel
@onready var end_turn_button = $EndTurnButton

const CARD_RESOURCE_DIR := "res://cards"
const BASE_PLAYER_ENERGY := 3
const STARTING_HAND_SIZE := 3
const ENEMY_NAMES := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var hand_cards: Array[GemCard] = []
var card_pool: Array[GemCard] = []
var player_deck: Array[GemCard] = []
var draw_pile: Array[GemCard] = []
var discard_pile: Array[GemCard] = []
var pending_reward_cards: Array[GemCard] = []
var turn_count: int = 1
var enemy_count: int = 1
var max_hand_size: int = STARTING_HAND_SIZE

var max_enemy_health: int = 30
var max_player_health: int = 30
var current_enemy_health: int = 30
var current_player_health: int = 30
var player_level: int = 1
var player_experience: int = 0
var player_experience_to_next_level: int = 10

var current_player_energy_max: int = BASE_PLAYER_ENERGY
var current_player_energy: int = BASE_PLAYER_ENERGY
var current_player_block: int = 0
var current_player_shield: int = 0
var turn_strength: int = 0
var turn_resistance: int = 0
var hand_cost_reduction: int = 0
var next_turn_energy_bonus: int = 0
var is_invincible: bool = false

var enemy_attack_damage: int = 5
var enemy_dot_damage: int = 0
var enemy_dot_duration: int = 0
var is_player_turn: bool = true
var is_game_over: bool = false
var current_pile_window_is_discard: bool = false

func _ready():
	randomize()
	load_card_resources()
	build_initial_player_deck()
	reset_draw_pile_from_player_deck()
	ComboManager.combo_updated.connect(_on_combo_updated)
	ComboManager.combo_broken.connect(_on_combo_broken)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	draw_pile_button.pressed.connect(_on_draw_pile_button_pressed)
	discard_pile_button.pressed.connect(_on_discard_pile_button_pressed)
	pile_window.close_requested.connect(_on_pile_window_close_requested)
	reward_window.close_requested.connect(_on_reward_window_close_requested)

	draw_initial_hand()
	update_all_ui()
	print("游戏开始，手牌数量：", hand_cards.size())

func load_card_resources():
	card_pool.clear()

	for file_name in DirAccess.get_files_at(CARD_RESOURCE_DIR):
		if not file_name.ends_with(".tres"):
			continue

		var resource_path = CARD_RESOURCE_DIR + "/" + file_name
		var card = load(resource_path) as GemCard
		if card == null:
			push_warning("跳过非卡牌资源: " + resource_path)
			continue
		if card.card_name.strip_edges().is_empty() or card.effects.is_empty():
			push_warning("跳过未完成卡牌资源: " + resource_path)
			continue

		card_pool.append(card)

	print("加载卡牌资源数量: ", card_pool.size())

func build_initial_player_deck():
	player_deck.clear()
	var starter_candidates: Array[GemCard] = []
	for card in card_pool:
		if card.cost <= 1:
			starter_candidates.append(card)

	if starter_candidates.is_empty():
		push_warning("没有 0-1 费卡牌资源，无法创建初始牌组")
		return

	starter_candidates.shuffle()
	for i in range(STARTING_HAND_SIZE):
		var template = starter_candidates[i % starter_candidates.size()]
		player_deck.append(template.duplicate(true) as GemCard)

	print("初始牌组数量: ", player_deck.size())

func draw_initial_hand():
	for i in range(STARTING_HAND_SIZE):
		draw_card_from_draw_pile()

func add_card_to_hand(card_data: GemCard):
	if hand_cards.size() >= max_hand_size:
		print("手牌已满: ", hand_cards.size(), "/", max_hand_size)
		update_hand_ui()
		return

	var card_ui_scene = preload("res://card_ui.tscn")
	var card_ui = card_ui_scene.instantiate()
	card_ui.card_data = card_data
	card_ui.card_played.connect(_on_card_played)
	hand_container.add_child(card_ui)
	hand_cards.append(card_data)
	update_hand_ui()

func reset_draw_pile_from_player_deck():
	draw_pile.clear()
	discard_pile.clear()
	for card in player_deck:
		draw_pile.append(card.duplicate(true) as GemCard)
	draw_pile.shuffle()
	update_hand_ui()

func draw_card_from_draw_pile():
	if hand_cards.size() >= max_hand_size:
		print("手牌达到上限，无法抽牌")
		update_hand_ui()
		return
	if draw_pile.is_empty():
		refill_draw_pile_from_discard()
	if draw_pile.is_empty():
		push_warning("抽牌堆和弃牌堆都为空，无法抽牌")
		return

	add_card_to_hand(draw_pile.pop_back())

func refill_draw_pile_from_discard():
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
	update_hand_ui()

func discard_card(card_data: GemCard):
	discard_pile.append(card_data)
	update_hand_ui()

func discard_remaining_hand():
	while not hand_cards.is_empty():
		var card = hand_cards.pop_back()
		discard_pile.append(card)

	for child in hand_container.get_children():
		child.queue_free()

	update_hand_ui()

func draw_new_turn_hand():
	for i in range(max_hand_size):
		draw_card_from_draw_pile()

func _on_card_played(card_data: GemCard):
	if is_game_over:
		return
	if not is_player_turn:
		print("现在是敌人回合，不能出牌")
		return

	var play_cost = get_current_card_cost(card_data)
	if current_player_energy < play_cost:
		print("能量不足！")
		return

	current_player_energy -= play_cost
	update_energy_ui()

	var combo_triggered = ComboManager.attempt_play(card_data)
	var combo_bonus = ComboManager.current_combo * 2 if combo_triggered else 0
	remove_card_from_hand(card_data)
	discard_card(card_data)

	for effect in card_data.effects:
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE:
				deal_damage_to_enemy(effect.value + turn_strength + combo_bonus, "单体伤害")

			EffectResource.EffectType.DEAL_DAMAGE_AOE:
				deal_damage_to_enemy(effect.value + turn_strength + combo_bonus, "群体伤害")

			EffectResource.EffectType.DEAL_DAMAGE_DOT:
				apply_enemy_dot(effect.value, effect.duration)

			EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS:
				var bonus = 3 if enemy_dot_duration > 0 else 0
				deal_damage_to_enemy(effect.value + bonus + turn_strength + combo_bonus, "DoT加成伤害")

			EffectResource.EffectType.GAIN_BLOCK:
				current_player_block += effect.value
				update_block_ui()
				print("获得 ", effect.value, " 护甲")

			EffectResource.EffectType.GAIN_HEALTH_REGEN:
				current_player_health = min(max_player_health, current_player_health + effect.value)
				update_player_ui()
				print("回复 ", effect.value, " 生命")

			EffectResource.EffectType.GAIN_INVINCIBLE:
				is_invincible = true
				update_block_ui()
				print("本回合无敌")

			EffectResource.EffectType.DRAW_CARD:
				for i in range(effect.value):
					draw_card_from_draw_pile()
				print("抽 ", effect.value, " 张牌")

			EffectResource.EffectType.GAIN_ENERGY:
				current_player_energy_max += effect.value
				current_player_energy += effect.value
				update_energy_ui()
				print("本回合获得 ", effect.value, " 费用")

			EffectResource.EffectType.INCREASE_HAND_LIMIT:
				max_hand_size += effect.value
				update_hand_ui()
				print("手牌上限 +", effect.value)

			EffectResource.EffectType.GAIN_STRENGTH_TURN:
				turn_strength += effect.value
				update_block_ui()
				print("本回合力量 +", effect.value)

			EffectResource.EffectType.GAIN_RESISTANCE_TURN:
				turn_resistance += effect.value
				update_block_ui()
				print("本回合抗性 +", effect.value)

			EffectResource.EffectType.GAIN_ENERGY_NEXT_TURN:
				next_turn_energy_bonus += effect.value
				update_energy_ui()
				print("下回合费用 +", effect.value)

			EffectResource.EffectType.REDUCE_HAND_COST_TURN:
				hand_cost_reduction += effect.value
				print("本回合手牌费用 -", effect.value)

			EffectResource.EffectType.RESET_ENERGY:
				current_player_energy = current_player_energy_max
				update_energy_ui()
				print("费用已重置")

			EffectResource.EffectType.GAIN_SHIELD:
				current_player_shield += effect.value
				update_block_ui()
				print("获得 ", effect.value, " 护盾")

	if current_enemy_health <= 0:
		print("敌人死亡！")
		spawn_new_enemy()

	update_all_ui()

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

func deal_damage_to_enemy(amount: int, source: String):
	current_enemy_health = max(0, current_enemy_health - amount)
	update_enemy_ui()
	print(source, " 造成 ", amount, " 伤害")

func apply_enemy_dot(damage: int, duration: int):
	enemy_dot_damage = damage
	enemy_dot_duration = duration
	update_enemy_ui()
	print("施加 DoT: 每回合 ", damage, " 点，持续 ", duration, " 回合")

func tick_enemy_dot():
	if enemy_dot_duration <= 0:
		return

	current_enemy_health = max(0, current_enemy_health - enemy_dot_damage)
	enemy_dot_duration -= 1
	update_enemy_ui()
	print("DoT 造成 ", enemy_dot_damage, " 伤害，剩余 ", enemy_dot_duration, " 回合")

func spawn_new_enemy():
	gain_experience(get_enemy_experience_reward())
	enemy_count += 1
	max_enemy_health = 30 + int(enemy_count / 2)
	current_enemy_health = max_enemy_health
	enemy_dot_damage = 0
	enemy_dot_duration = 0
	update_enemy_ui()
	update_enemy_intent_ui()
	print("新敌人出现，血量: ", current_enemy_health)

func get_enemy_experience_reward() -> int:
	return 5 + enemy_count * 2

func gain_experience(amount: int):
	player_experience += amount
	print("获得经验: ", amount)

	while player_experience >= player_experience_to_next_level:
		player_experience -= player_experience_to_next_level
		level_up()

	update_experience_ui()

func level_up():
	player_level += 1
	player_experience_to_next_level += 5
	max_player_health += 5
	current_player_health = min(max_player_health, current_player_health + 5)
	update_player_ui()
	open_card_reward_window()
	print("升级到 ", player_level, " 级")

func _on_end_turn_pressed():
	if is_game_over:
		return
	if not is_player_turn:
		return

	is_player_turn = false
	update_turn_ui()
	print("玩家回合结束")
	print("------------------")

	tick_enemy_dot()
	if current_enemy_health <= 0:
		spawn_new_enemy()
	else:
		enemy_attack()
		if is_game_over:
			update_all_ui()
			return

	ComboManager.break_combo()
	discard_remaining_hand()
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
	print("敌人回合结束，现在是玩家回合")
	print("------------------")

func enemy_attack():
	var damage = enemy_attack_damage

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
	update_block_ui()
	update_player_ui()
	print("敌人攻击，造成 ", damage, " 点伤害")

	if current_player_health <= 0:
		print("玩家死亡！游戏结束")
		is_game_over = true
		is_player_turn = false
		end_turn_button.disabled = true
		update_turn_ui()

func get_enemy_name_for_turn() -> String:
	var index = (enemy_count - 1) % 26
	return ENEMY_NAMES.substr(index, 1)

func update_enemy_ui():
	enemy_name_label.text = "敌人 " + get_enemy_name_for_turn()
	enemy_hp_label.text = "血量: " + str(current_enemy_health) + " / " + str(max_enemy_health)
	if enemy_dot_duration > 0:
		enemy_tip_label.text = "DoT: " + str(enemy_dot_damage) + " x " + str(enemy_dot_duration)
	else:
		enemy_tip_label.text = "护甲会先抵消攻击伤害"

func update_enemy_intent_ui():
	enemy_intent_label.text = "本回合: 攻击 " + str(enemy_attack_damage)

func update_player_ui():
	player_hp_label.text = "血量: " + str(current_player_health) + " / " + str(max_player_health)

func update_experience_ui():
	level_label.text = "等级: " + str(player_level)
	experience_label.text = "经验: " + str(player_experience) + " / " + str(player_experience_to_next_level)

func update_energy_ui():
	energy_label.text = "费用: " + str(current_player_energy) + " / " + str(current_player_energy_max)

func update_block_ui():
	var status_parts: Array[String] = ["护甲: " + str(current_player_block)]
	if current_player_shield > 0:
		status_parts.append("护盾: " + str(current_player_shield))
	if turn_resistance > 0:
		status_parts.append("抗性: " + str(turn_resistance))
	if turn_strength > 0:
		status_parts.append("力量: " + str(turn_strength))
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
		phase_label.text = "游戏结束"
	else:
		phase_label.text = "玩家行动" if is_player_turn else "敌人行动"
	update_enemy_ui()

func update_combo_ui():
	combo_label.text = "连击: " + str(ComboManager.current_combo)

func update_hand_ui():
	hand_count_label.text = "手牌: " + str(hand_cards.size()) + " / " + str(max_hand_size)
	deck_count_label.text = "抽:" + str(draw_pile.size()) + " 弃:" + str(discard_pile.size()) + " 组:" + str(player_deck.size())
	draw_pile_button.text = "抽牌堆 " + str(draw_pile.size())
	discard_pile_button.text = "弃牌堆 " + str(discard_pile.size())
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
	var pile = discard_pile if current_pile_window_is_discard else draw_pile
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
	pending_reward_cards = get_random_reward_cards(3)
	for child in reward_card_container.get_children():
		child.queue_free()

	var card_ui_scene = preload("res://card_ui.tscn")
	for card in pending_reward_cards:
		var card_ui = card_ui_scene.instantiate()
		card_ui.card_data = card
		card_ui.card_played.connect(_on_reward_card_selected)
		reward_card_container.add_child(card_ui)

	reward_window.popup()

func get_random_reward_cards(count: int) -> Array[GemCard]:
	var candidates = card_pool.duplicate()
	var rewards: Array[GemCard] = []
	if candidates.is_empty():
		return rewards

	candidates.shuffle()
	for i in range(count):
		var template = candidates[i % candidates.size()]
		rewards.append(template.duplicate(true) as GemCard)
	return rewards

func _on_reward_card_selected(card_data: GemCard):
	player_deck.append(card_data.duplicate(true) as GemCard)
	discard_pile.append(card_data.duplicate(true) as GemCard)
	reward_window.hide()
	for child in reward_card_container.get_children():
		child.queue_free()
	pending_reward_cards.clear()
	update_hand_ui()
	print("加入牌组: ", card_data.card_name)

func _on_reward_window_close_requested():
	reward_window.popup()

func _on_combo_updated(_combo: int):
	update_combo_ui()

func _on_combo_broken():
	update_combo_ui()
