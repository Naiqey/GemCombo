extends Node2D

@onready var hand_container = $HandContainer
@onready var enemy_hp_label = $EnemyHpLabel
@onready var player_hp_label = $PlayerHpLabel
@onready var end_turn_button = $EndTurnButton

var hand_cards: Array = []  # 存储卡牌数据（GemCard 对象列表）
var current_enemy_health: int = 30
var current_player_health: int = 30
var is_player_turn: bool = true  # 玩家回合标志

func _ready():
	# 创建测试卡牌
	var test_cards = [
		create_card(GemCard.GemColor.RED, 3, "AOE"),
		create_card(GemCard.GemColor.RED, 1, "打击"),
		create_card(GemCard.GemColor.BLUE, 1, "法力"),
	]
	for card_data in test_cards:
		add_card_to_hand(card_data)
	
	update_enemy_ui()
	update_player_ui()
	
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	print("游戏开始，手牌数量：", hand_cards.size())


func create_card(color, cost, function) -> GemCard:
	var card = GemCard.new()
	card.color = color
	card.cost = cost
	card.function_name = function
	return card

func add_card_to_hand(card_data: GemCard):
	print("添加卡牌开始")
	var card_ui_scene = preload("res://card_ui.tscn")
	print("预加载成功")
	var card_ui = card_ui_scene.instantiate()
	card_ui.card_data = card_data
	card_ui.card_played.connect(_on_card_played)
	hand_container.add_child(card_ui)
	hand_cards.append(card_data)
	print("添加完成，当前手牌数：", hand_cards.size())
	

func _on_card_played(card_data: GemCard):
	if not is_player_turn:
		print("现在是敌人回合，不能出牌")
		return
	
	print("打出了: ", card_data.color, card_data.cost)
	var success = ComboManager.attempt_play(card_data)
	if success:
		print("连击成功！当前连击数: ", ComboManager.current_combo)
		var damage = calculate_damage(card_data, ComboManager.current_combo)
		print("造成伤害: ", damage)
		current_enemy_health -= damage
		update_enemy_ui()
		
		# 移除打出的卡牌UI和數據
		var index = hand_cards.find(card_data)
		if index != -1:
			var card_ui = hand_container.get_child(index)
			card_ui.queue_free()
			hand_cards.remove_at(index)
		
		# 抽一张新牌
		draw_random_card()
		
		# 检查敌人是否死亡
		if current_enemy_health <= 0:
			print("敌人死亡！")
			spawn_new_enemy()
	else:
		print("连击中断！")
		# 可选：中断时不清除手牌，只重置连击，但是我们已经调用了 break_combo，连击重置
		# 注意：中断时不应移除牌，且不应抽牌。
		# 由于 attempt_play 返回 false 时内部已经调用了 break_combo，我们这里只输出信息即可。
		var damage = calculate_damage(card_data, ComboManager.current_combo)
		print("造成伤害: ", damage)
		current_enemy_health -= damage
		update_enemy_ui()
		
		# 移除打出的卡牌UI和數據
		var index = hand_cards.find(card_data)
		if index != -1:
			var card_ui = hand_container.get_child(index)
			card_ui.queue_free()
			hand_cards.remove_at(index)
		
		# 抽一张新牌
		draw_random_card()
		
		# 检查敌人是否死亡
		if current_enemy_health <= 0:
			print("敌人死亡！")
			spawn_new_enemy()
	print("---------------------------------------")

func calculate_damage(card: GemCard, combo: int) -> int:
	var base_damage = 0
	var final_damage = 0
	var combo_bonus = combo * 2
	if card.color == GemCard.GemColor.RED:
		base_damage = card.cost
		combo_bonus = combo * 2
		final_damage = base_damage + combo_bonus
	return final_damage

func draw_random_card():
	# 随机生成一张卡牌（颜色随机，数字1-4随机）
	var colors = [GemCard.GemColor.RED, GemCard.GemColor.YELLOW, GemCard.GemColor.BLUE, GemCard.GemColor.GREEN]
	var random_color = colors[randi() % colors.size()]
	var random_cost = randi() % 4 + 1  # 1-4
	var new_card = create_card(random_color, random_cost, "test")
	add_card_to_hand(new_card)
	print("抽到新牌: ", random_color, random_cost)

func update_enemy_ui():
	enemy_hp_label.text = "敌人血量: " + str(current_enemy_health)

func update_player_ui():
	player_hp_label.text = "玩家血量: " + str(current_player_health)

func spawn_new_enemy():
	# 简单重置血量，可以增加最大血量，或者随机生成
	current_enemy_health = 30 + (ComboManager.current_combo / 10) as int  # 根据连击数增加难度
	update_enemy_ui()
	print("新敌人出现，血量: ", current_enemy_health)

func _on_end_turn_pressed():
	if not is_player_turn:
		print("已经是敌人回合，请等待")
		return
	# 结束玩家回合
	is_player_turn = false
	print("玩家回合结束")
	
	# 敌人攻击
	enemy_attack()
	
	# 重置连击
	ComboManager.break_combo()
	
	# 开始敌人回合（这里简化：敌人只攻击一次，然后立刻回到玩家回合）
	# 但我们希望玩家点击“回合结束”后，敌人攻击一次，然后再次轮到玩家。
	is_player_turn = true
	print("敌人回合结束，现在是玩家回合")

func enemy_attack():
	var damage = 5  # 固定伤害，可以调整
	current_player_health -= damage
	update_player_ui()
	print("敌人攻击，造成 ", damage, " 点伤害")
	if current_player_health <= 0:
		print("玩家死亡！游戏结束")
		# 可以弹出提示或禁用出牌
		is_player_turn = false
