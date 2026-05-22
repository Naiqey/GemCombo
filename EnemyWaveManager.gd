class_name EnemyWaveManager
extends RefCounted

const SMALL_ENEMY_TYPE := "small"
const BIG_ENEMY_TYPE := "big"
const BOSS_ENEMY_TYPE := "boss"

var levels: Array[Dictionary] = [
	{
		"name": "新手林地",
		"waves": [
			{"name": "树丛小兵", "enemies": [
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
			]},
			{"name": "巡逻卫兵", "enemies": [
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
			]},
			{"name": "林地领主", "is_boss": true, "enemies": [
				{"name": "林地领主", "type": BOSS_ENEMY_TYPE, "hp": 30, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 3},
			]},
		],
	},
	{
		"name": "熔岩矿洞",
		"waves": [
			{"name": "矿洞蝙蝠", "enemies": [
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
			]},
			{"name": "岩浆守卫", "enemies": [
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 6},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
			]},
			{"name": "熔核巨人", "is_boss": true, "enemies": [
				{"name": "熔核巨人", "type": BOSS_ENEMY_TYPE, "hp": 40, "atk": 7},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 6},
			]},
		],
	},
	{
		"name": "幽魂古堡",
		"waves": [
			{"name": "游荡幽灵", "enemies": [
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 4},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 6},
			]},
			{"name": "古堡骑士", "enemies": [
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 7},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 7},
			]},
			{"name": "幽魂领主", "is_boss": true, "enemies": [
				{"name": "幽魂领主", "type": BOSS_ENEMY_TYPE, "hp": 50, "atk": 8},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 7},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 15, "atk": 7},
			]},
		],
	},
	{
		"name": "虚空裂缝",
		"waves": [
			{"name": "裂缝碎片", "enemies": [
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
			]},
			{"name": "虚空猎手", "enemies": [
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 8},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 8},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 5},
			]},
			{"name": "虚空领袖", "is_boss": true, "enemies": [
				{"name": "虚空领袖", "type": BOSS_ENEMY_TYPE, "hp": 60, "atk": 10},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 8},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 8},
			]},
		],
	},
	{
		"name": "终焉神殿",
		"waves": [
			{"name": "神殿守卫", "enemies": [
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 9},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 9},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 20, "atk": 9},
			]},
			{"name": "神殿精英", "enemies": [
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 25, "atk": 10},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 25, "atk": 10},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 6},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 6},
				{"name": "小怪", "type": SMALL_ENEMY_TYPE, "hp": 5, "atk": 6},
			]},
			{"name": "终焉神·残影", "is_boss": true, "enemies": [
				{"name": "终焉神·残影", "type": BOSS_ENEMY_TYPE, "hp": 80, "atk": 12},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 25, "atk": 10},
				{"name": "大怪", "type": BIG_ENEMY_TYPE, "hp": 25, "atk": 10},
			]},
		],
	},
]

var current_level_index: int = 0
var current_wave_index: int = 0
var enemies: Array[Dictionary] = []
var is_complete: bool = false

func setup():
	current_level_index = 0
	current_wave_index = 0
	is_complete = levels.is_empty()
	if not is_complete:
		_spawn_current_wave()

func damage_first_alive(amount: int):
	var index = get_first_alive_index()
	if index == -1:
		return
	damage_enemy(index, amount)

func damage_all_alive(amount: int):
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			damage_enemy(i, amount)

func damage_enemy(index: int, amount: int):
	if index < 0 or index >= enemies.size():
		return
	var enemy = enemies[index]
	enemy["health"] = max(0, int(enemy["health"]) - amount)
	enemies[index] = enemy

func apply_dot(index: int, damage: int, duration: int):
	if index < 0 or index >= enemies.size():
		return
	var enemy = enemies[index]
	enemy["dot_damage"] = damage
	enemy["dot_duration"] = duration
	enemies[index] = enemy

func enemy_has_dot(index: int) -> bool:
	if index < 0 or index >= enemies.size():
		return false
	return int(enemies[index].get("dot_duration", 0)) > 0

func tick_dots():
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var dot_duration = int(enemy.get("dot_duration", 0))
		if dot_duration <= 0:
			continue

		enemy["health"] = max(0, int(enemy["health"]) - int(enemy.get("dot_damage", 0)))
		enemy["dot_duration"] = dot_duration - 1
		enemies[i] = enemy

func get_first_alive_index() -> int:
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			return i
	return -1

func is_enemy_alive(index: int) -> bool:
	return index >= 0 and index < enemies.size() and int(enemies[index]["health"]) > 0

func has_alive_enemies() -> bool:
	return get_first_alive_index() != -1

func collect_dead_enemies() -> Array[Dictionary]:
	var dead_enemies: Array[Dictionary] = []
	var alive_enemies: Array[Dictionary] = []
	for enemy in enemies:
		if int(enemy["health"]) <= 0:
			dead_enemies.append(enemy)
		else:
			alive_enemies.append(enemy)
	enemies = alive_enemies
	return dead_enemies

func collect_dead_enemy_count() -> int:
	return collect_dead_enemies().size()

func advance_wave_if_cleared():
	if is_complete or has_alive_enemies():
		return

	current_wave_index += 1
	if current_wave_index >= get_current_level_waves().size():
		current_level_index += 1
		current_wave_index = 0

	if current_level_index >= levels.size():
		is_complete = true
		enemies.clear()
		return

	_spawn_current_wave()

func _spawn_current_wave():
	enemies.clear()
	var wave = get_current_wave()
	var type_counts := {}
	for enemy_spec in wave.get("enemies", []):
		var enemy_type = str(enemy_spec.get("type", SMALL_ENEMY_TYPE))
		type_counts[enemy_type] = int(type_counts.get(enemy_type, 0)) + 1
		var display_name = str(enemy_spec.get("name", "敌人"))
		if enemy_type != BOSS_ENEMY_TYPE:
			display_name += " " + str(type_counts[enemy_type])
		enemies.append({
			"name": display_name,
			"kind": enemy_type,
			"type": enemy_type,
			"health": int(enemy_spec.get("hp", 1)),
			"max_health": int(enemy_spec.get("hp", 1)),
			"attack": int(enemy_spec.get("atk", 0)),
			"is_boss": enemy_type == BOSS_ENEMY_TYPE,
			"dot_damage": 0,
			"dot_duration": 0,
		})

func get_current_level() -> Dictionary:
	if current_level_index < 0 or current_level_index >= levels.size():
		return {}
	return levels[current_level_index]

func get_current_level_waves() -> Array:
	return get_current_level().get("waves", [])

func get_current_wave() -> Dictionary:
	var waves = get_current_level_waves()
	if current_wave_index < 0 or current_wave_index >= waves.size():
		return {}
	return waves[current_wave_index]

func is_current_wave_boss() -> bool:
	return bool(get_current_wave().get("is_boss", false))

func get_current_level_number() -> int:
	return current_level_index + 1

func get_current_wave_number() -> int:
	return current_wave_index + 1

func get_total_attack_damage() -> int:
	var damage := 0
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			damage += int(enemies[i].get("attack", 0))
	return damage

func get_alive_enemy_count() -> int:
	var count := 0
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			count += 1
	return count

func get_wave_title() -> String:
	if is_complete:
		return "全部波次完成"
	return "关卡 %d · 第 %d 波次 · %s" % [
		get_current_level_number(),
		get_current_wave_number(),
		str(get_current_wave().get("name", "")),
	]

func get_progress_text() -> String:
	if is_complete:
		return "胜利"
	var boss_text = " · Boss" if is_current_wave_boss() else ""
	return get_wave_title() + boss_text + "  存活: " + str(get_alive_enemy_count()) + "/" + str(enemies.size())
