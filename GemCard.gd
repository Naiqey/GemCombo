# GemCard.gd
class_name GemCard
extends Resource

enum GemColor { RED, YELLOW, BLUE, GREEN }
enum EffectType {
	DEAL_DAMAGE_SINGLE, DEAL_DAMAGE_AOE, DEAL_DAMAGE_DOT,
	GAIN_BLOCK, GAIN_HEALTH_REGEN, GAIN_INVINCIBLE,
	DRAW_CARD, GAIN_ENERGY, DISCARD_CARD,
	APPLY_VULNERABLE, APPLY_WEAK, DOUBLE_DAMAGE_NEXT
}

@export var card_name: String
@export var color: GemColor
@export var cost: int
@export var effects: Array[EffectResource]
@export_multiline var description: String  # 可留空，用自动生成填充
