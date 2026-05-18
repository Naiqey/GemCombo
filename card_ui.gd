extends Control

signal card_played(card_data: GemCard)

@export var card_data: GemCard
@export var is_preview: bool = false

@onready var button = $Button
@onready var color_rect = $Button/ColorBg
@onready var top_band = $Button/TopBand
@onready var cost_badge = $Button/CostBadge
@onready var number_label = $Button/CostBadge/NumberLabel
@onready var name_label = $Button/NameLabel
@onready var gem_label = $Button/GemLabel
@onready var function_label = $Button/FunctionLabel

func _ready():
	update_display()
	if is_preview:
		button.disabled = true
	else:
		button.pressed.connect(_on_button_pressed)

func update_display():
	if not card_data:
		return
	var bg_color := Color(0.18, 0.2, 0.24)
	var band_color := Color(0.32, 0.48, 0.82)
	var gem_text := "蓝"

	match card_data.color:
		GemCard.GemColor.RED:
			bg_color = Color(0.35, 0.08, 0.07)
			band_color = Color(0.85, 0.18, 0.14)
			gem_text = "红"
		GemCard.GemColor.YELLOW:
			bg_color = Color(0.34, 0.27, 0.08)
			band_color = Color(0.95, 0.68, 0.16)
			gem_text = "黄"
		GemCard.GemColor.BLUE:
			bg_color = Color(0.08, 0.18, 0.34)
			band_color = Color(0.18, 0.44, 0.88)
			gem_text = "蓝"
		GemCard.GemColor.GREEN:
			bg_color = Color(0.08, 0.27, 0.18)
			band_color = Color(0.18, 0.62, 0.35)
			gem_text = "绿"

	color_rect.color = bg_color
	top_band.color = band_color
	_set_cost_badge_color(band_color)

	number_label.text = str(card_data.cost)
	name_label.text = card_data.card_name
	gem_label.text = gem_text
	function_label.text = _get_card_description()

func _set_cost_badge_color(color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.25)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.8)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	cost_badge.add_theme_stylebox_override("panel", style)

func _get_card_description() -> String:
	if not card_data.description.strip_edges().is_empty():
		return card_data.description
	if card_data.effects.is_empty():
		return "无效果"

	var parts: Array[String] = []
	for effect in card_data.effects:
		match effect.type:
			EffectResource.EffectType.DEAL_DAMAGE_SINGLE:
				parts.append("造成 " + str(effect.value) + " 点单体伤害")
			EffectResource.EffectType.GAIN_BLOCK:
				parts.append("获得 " + str(effect.value) + " 点护甲")
			EffectResource.EffectType.DRAW_CARD:
				parts.append("抽 " + str(effect.value) + " 张牌")
			EffectResource.EffectType.GAIN_ENERGY:
				parts.append("获得 " + str(effect.value) + " 点能量")
			EffectResource.EffectType.DEAL_DAMAGE_AOE:
				parts.append("造成 " + str(effect.value) + " 点群体伤害")
			EffectResource.EffectType.DEAL_DAMAGE_DOT:
				parts.append("施加 DoT：" + str(effect.value) + " x " + str(effect.duration))
			EffectResource.EffectType.GAIN_HEALTH_REGEN:
				parts.append("回复 " + str(effect.value) + " 点生命")
			EffectResource.EffectType.GAIN_INVINCIBLE:
				parts.append("本回合无敌")
			EffectResource.EffectType.INCREASE_HAND_LIMIT:
				parts.append("手牌上限 +" + str(effect.value))
			EffectResource.EffectType.GAIN_STRENGTH_TURN:
				parts.append("本回合力量 +" + str(effect.value))
			EffectResource.EffectType.GAIN_RESISTANCE_TURN:
				parts.append("本回合抗性 +" + str(effect.value))
			EffectResource.EffectType.GAIN_ENERGY_NEXT_TURN:
				parts.append("下回合费用 +" + str(effect.value))
			EffectResource.EffectType.REDUCE_HAND_COST_TURN:
				parts.append("本回合手牌费用 -" + str(effect.value))
			EffectResource.EffectType.RESET_ENERGY:
				parts.append("重置本回合费用")
			EffectResource.EffectType.GAIN_SHIELD:
				parts.append("获得 " + str(effect.value) + " 点护盾")
			EffectResource.EffectType.DEAL_DAMAGE_DOT_BONUS:
				parts.append("若目标有 DoT，额外 +3 伤害")
			_:
				parts.append("特殊效果")

	var description := ""
	for part in parts:
		if not description.is_empty():
			description += "\n"
		description += part
	return description

func _on_button_pressed():
	print("卡牌按钮被按下了！")
	card_played.emit(card_data)
