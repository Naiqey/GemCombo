class_name EffectResource
extends Resource

@export var type: GemCard.EffectType
@export var value: int = 0
@export var duration: int = 0      # 用于持续伤害、易伤等
@export var target_self: bool = true  # 目标是自己还是敌人
# 可以按需要扩展
