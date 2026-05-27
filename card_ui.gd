extends Control

signal card_played(card_data: GemCard)

class GemSlotCircle:
	extends Control

	const SLOT_COLOR := Color(0.917647, 0.92549, 0.933333, 1.0)

	func _init():
		custom_minimum_size = Vector2(8, 8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw():
		draw_rect(Rect2(Vector2(1, 1), Vector2(6, 6)), SLOT_COLOR, false, 1.0)

@export var card_data: GemCard
@export var is_preview: bool = false
@export var is_affordable: bool = true
@export var display_cost: int = -1
@export var display_player_strength: int = 0
@export var display_turn_strength: int = 0
@export var display_combo_bonus: int = 0

@onready var button = $Button
@onready var color_rect = $Button/ColorBg
@onready var top_band = $Button/TopBand
@onready var cost_badge = $Button/CostBadge
@onready var number_label = $Button/CostBadge/NumberLabel
@onready var name_label = $Button/NameLabel
@onready var gem_label = $Button/GemLabel
@onready var function_label = $Button/FunctionLabel
@onready var gem_slot_container = $Button/GemSlotContainer

func _ready():
	update_display()
	if is_preview:
		button.disabled = true
	else:
		button.pressed.connect(_on_button_pressed)

func set_display_context(cost: int, player_strength: int, turn_strength: int, combo_bonus: int, affordable: bool = true):
	display_cost = cost
	display_player_strength = player_strength
	display_turn_strength = turn_strength
	display_combo_bonus = combo_bonus
	is_affordable = affordable
	if is_node_ready():
		update_display()

func update_display():
	if not card_data:
		return

	var bg_color := Color("#1A1A2E")
	var band_color := Color("#1A6FA8")
	var gem_text := "蓝"

	match card_data.color:
		GemCard.GemColor.RED:
			bg_color = Color("#C0392B")
			band_color = Color("#922B21")
			gem_text = "红"
		GemCard.GemColor.YELLOW:
			bg_color = Color("#D4AC0D")
			band_color = Color("#9A7D0A")
			gem_text = "黄"
		GemCard.GemColor.BLUE:
			bg_color = Color("#1A6FA8")
			band_color = Color("#154F78")
			gem_text = "蓝"
		GemCard.GemColor.GREEN:
			bg_color = Color("#1E8449")
			band_color = Color("#196F3D")
			gem_text = "绿"

	color_rect.color = bg_color
	top_band.color = band_color
	gem_label.add_theme_color_override("font_color", Color("#EAECEE"))
	function_label.add_theme_color_override("font_color", Color("#EAECEE"))
	name_label.add_theme_color_override("font_color", Color("#EAECEE"))
	var disabled_due_to_cost := not is_preview and not is_affordable
	modulate.a = 0.45 if disabled_due_to_cost else 1.0
	button.disabled = is_preview or disabled_due_to_cost
	_set_cost_badge_color(Color(0.333333, 0.333333, 0.333333, 1.0) if disabled_due_to_cost else band_color)

	number_label.text = str(display_cost if display_cost >= 0 else card_data.cost)
	name_label.text = card_data.card_name
	gem_label.text = gem_text
	function_label.text = _get_card_description()
	_update_gem_slots()

func _set_cost_badge_color(color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.25)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.8)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	cost_badge.add_theme_stylebox_override("panel", style)

func _update_gem_slots():
	for child in gem_slot_container.get_children():
		gem_slot_container.remove_child(child)
		child.queue_free()

	for i in range(max(0, card_data.gem_slots)):
		var slot = GemSlotCircle.new()
		gem_slot_container.add_child(slot)

func _get_card_description() -> String:
	if _uses_static_description():
		return card_data.description
	if card_data.effects.is_empty():
		return "无效果"

	var parts: Array[String] = []
	for effect in card_data.effects:
		var value = _get_display_value(effect)
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE:
				parts.append("造成 " + str(value + _get_attack_bonus()) + " 点单体伤害")
			EffectResource.EffectType.DEAL_DAMAGE_AOE:
				parts.append("造成 " + str(value + _get_attack_bonus()) + " 点群体伤害")
			EffectResource.EffectType.DEAL_DAMAGE_DOT:
				parts.append("施加 DoT: " + str(value) + " x " + str(effect.duration))
			EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS:
				parts.append("造成 " + str(value + _get_attack_bonus()) + " 点伤害\n目标有 DoT +3")
			EffectResource.EffectType.GAIN_BLOCK:
				parts.append("获得 " + str(value) + " 点护甲")
			EffectResource.EffectType.GAIN_HEALTH_REGEN:
				parts.append("回复 " + str(value) + " 点生命")
			EffectResource.EffectType.GAIN_INVINCIBLE:
				parts.append("本回合无敌")
			EffectResource.EffectType.DRAW_CARD:
				parts.append("抽 " + str(value) + " 张牌")
			EffectResource.EffectType.GAIN_ENERGY:
				parts.append("获得 " + str(value) + " 点费用")
			EffectResource.EffectType.INCREASE_HAND_LIMIT:
				parts.append("手牌上限 +" + str(value))
			EffectResource.EffectType.GAIN_STRENGTH_TURN:
				parts.append("本回合力量 +" + str(value))
			EffectResource.EffectType.GAIN_RESISTANCE_TURN:
				parts.append("本回合抗性 +" + str(value))
			EffectResource.EffectType.GAIN_ENERGY_NEXT_TURN:
				parts.append("下回合费用 +" + str(value))
			EffectResource.EffectType.REDUCE_HAND_COST_TURN:
				parts.append("本回合手牌费用 -" + str(value))
			EffectResource.EffectType.RESET_ENERGY:
				parts.append("重置本回合费用")
			EffectResource.EffectType.GAIN_SHIELD:
				parts.append("获得 " + str(value) + " 点护盾")
			EffectResource.EffectType.DISCARD_CARD:
				parts.append("弃 " + str(value) + " 张牌")
			EffectResource.EffectType.APPLY_VULNERABLE:
				parts.append("施加易伤 " + str(value))
			EffectResource.EffectType.APPLY_WEAK:
				parts.append("施加虚弱 " + str(value))
			EffectResource.EffectType.DOUBLE_DAMAGE_NEXT:
				parts.append("下一张攻击牌伤害翻倍")
			_:
				parts.append("特殊效果")

	return "\n".join(parts)

func _uses_static_description() -> bool:
	return display_combo_bonus == 0 and display_player_strength == 0 and display_turn_strength == 0 and not card_data.description.strip_edges().is_empty()

func _get_display_value(effect: EffectResource) -> int:
	if effect.value <= 0:
		return effect.value
	return effect.value + display_combo_bonus

func _get_attack_bonus() -> int:
	return display_player_strength + display_turn_strength

func _on_button_pressed():
	print("卡牌按钮被按下: ", card_data.card_name)
	card_played.emit(card_data)
