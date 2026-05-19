class_name EnemyWaveManager
extends RefCounted

const SMALL_ENEMY_HEALTH := 5
const BIG_ENEMY_HEALTH := 10
const FIRST_WAVE_ATTACK := 3
const ATTACK_GROWTH_PER_WAVE := 1

var waves := [
	{"label": "第1关", "count": 1, "health": BIG_ENEMY_HEALTH, "kind": "大怪"},
	{"label": "第2关", "count": 3, "health": SMALL_ENEMY_HEALTH, "kind": "小怪"},
	{"label": "第3关", "count": 2, "health": BIG_ENEMY_HEALTH, "kind": "大怪"},
	{"label": "第4关", "count": 5, "health": SMALL_ENEMY_HEALTH, "kind": "小怪"},
	{"label": "第5关", "count": 3, "health": BIG_ENEMY_HEALTH, "kind": "大怪"},
	{"label": "第6关", "count": 7, "health": SMALL_ENEMY_HEALTH, "kind": "小怪"},
]

var wave_index: int = 0
var enemies: Array[Dictionary] = []
var is_complete: bool = false

func setup():
	wave_index = 0
	is_complete = waves.is_empty()
	if not is_complete:
		_spawn_wave()

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

func collect_dead_enemy_count() -> int:
	var count := 0
	var alive_enemies: Array[Dictionary] = []
	for enemy in enemies:
		if int(enemy["health"]) <= 0:
			count += 1
		else:
			alive_enemies.append(enemy)
	enemies = alive_enemies
	return count

func advance_wave_if_cleared():
	if is_complete or has_alive_enemies():
		return

	wave_index += 1
	if wave_index >= waves.size():
		is_complete = true
		enemies.clear()
		return

	_spawn_wave()

func _spawn_wave():
	enemies.clear()
	var wave = waves[wave_index]
	var attack = get_current_wave_attack()
	for i in range(int(wave["count"])):
		enemies.append({
			"name": str(wave["kind"]) + " " + str(i + 1),
			"kind": wave["kind"],
			"health": int(wave["health"]),
			"max_health": int(wave["health"]),
			"attack": attack,
			"dot_damage": 0,
			"dot_duration": 0,
		})

func get_current_wave_attack() -> int:
	return FIRST_WAVE_ATTACK + wave_index * ATTACK_GROWTH_PER_WAVE

func get_total_attack_damage() -> int:
	var damage := 0
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			damage += int(enemies[i].get("attack", get_current_wave_attack()))
	return damage

func get_alive_enemy_count() -> int:
	var count := 0
	for i in range(enemies.size()):
		if is_enemy_alive(i):
			count += 1
	return count

func get_wave_title() -> String:
	if is_complete:
		return "全部关卡完成"
	return str(waves[wave_index]["label"])

func get_progress_text() -> String:
	if is_complete:
		return "胜利"
	return get_wave_title() + " 存活: " + str(get_alive_enemy_count()) + "/" + str(enemies.size())
