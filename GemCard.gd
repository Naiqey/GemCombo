class_name GemCard
extends Resource

enum GemColor { RED, YELLOW, BLUE, GREEN }

@export var card_name: String
@export var color: GemColor
@export var cost: int
@export var effects: Array[EffectResource] = []
@export var description: String = ""
