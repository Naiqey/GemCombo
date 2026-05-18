class_name EffectResource
extends Resource

# 将 EffectType 枚举移到这里
enum EffectType { 
	DEAL_DAMAGE_SINGLE, DEAL_DAMAGE_AOE, DEAL_DAMAGE_DOT,
	GAIN_BLOCK, GAIN_HEALTH_REGEN, GAIN_INVINCIBLE,
	DRAW_CARD, GAIN_ENERGY, DISCARD_CARD,
	APPLY_VULNERABLE, APPLY_WEAK, DOUBLE_DAMAGE_NEXT,
	INCREASE_HAND_LIMIT, GAIN_STRENGTH_TURN, GAIN_RESISTANCE_TURN,
	GAIN_ENERGY_NEXT_TURN, REDUCE_HAND_COST_TURN, RESET_ENERGY,
	GAIN_SHIELD, DEAL_DAMAGE_DOT_BONUS
}

@export var type: EffectType          # 改为 EffectResource.EffectType
@export var value: int = 0
@export var duration: int = 0
@export var target_self: bool = true
