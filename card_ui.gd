extends Control

signal card_played(card_data: GemCard)

@export var card_data: GemCard

@onready var color_rect = $Button/ColorBg
@onready var number_label = $Button/NumberLabel
@onready var function_label = $Button/FunctionLabel

func _ready():
	update_display()
	$Button.pressed.connect(_on_button_pressed)

func update_display():
	if not card_data:
		return
	# 根据颜色设置背景色
	match card_data.color:
		GemCard.GemColor.RED:
			color_rect.color = Color.RED
		GemCard.GemColor.YELLOW:
			color_rect.color = Color.BLACK
		GemCard.GemColor.BLUE:
			color_rect.color = Color.BLUE
		GemCard.GemColor.GREEN:
			color_rect.color = Color.GREEN
	number_label.text = str(card_data.cost)
	function_label.text = str(card_data.function_name)

func _on_button_pressed():
	print("卡牌按钮被按下了！")
	card_played.emit(card_data)
