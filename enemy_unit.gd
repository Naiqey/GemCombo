extends Button

signal enemy_clicked(enemy_index: int)

const TYPE_SMALL := "small"
const TYPE_BIG := "big"
const TYPE_BOSS := "boss"

const COLOR_BG := Color("#1A1A2E")
const COLOR_BORDER := Color("#2A2A3E")
const COLOR_DISABLED := Color("#4A4A6A")
const COLOR_TEXT := Color("#EAECEE")
const COLOR_TEXT_MUTED := Color("#A0A4A8")
const COLOR_DANGER := Color("#E74C3C")
const COLOR_HP := Color("#27AE60")
const COLOR_DOT := Color("#E67E22")
const COLOR_BOSS := Color("#8E44AD")
const COLOR_TARGET := Color("#F4D03F")

var enemy_index: int = -1
var enemy_type: String = TYPE_SMALL
var level_number: int = 1
var max_health: int = 1
var current_health: int = 1
var target_highlight: bool = false

@onready var sprite_container: Control = $SpriteContainer
@onready var sprite_rect: TextureRect = $SpriteContainer/SpriteRect
@onready var fallback_sprite: ColorRect = $SpriteContainer/FallbackSprite
@onready var target_frame: Panel = $SpriteContainer/TargetFrame
@onready var dead_overlay: ColorRect = $SpriteContainer/DeadOverlay
@onready var hp_back: ColorRect = $HpBar/HpBack
@onready var hp_fill: ColorRect = $HpBar/HpFill
@onready var boss_tag: Label = $StatsRow/BossTag
@onready var atk_label: Label = $StatsRow/AtkLabel
@onready var dot_container: HBoxContainer = $StatsRow/DotContainer
@onready var dot_icon: Label = $StatsRow/DotContainer/DotIcon
@onready var dot_label: Label = $StatsRow/DotContainer/DotLabel
@onready var hp_label: Label = $HpLabel
@onready var name_label: Label = $NameLabel

func _ready():
	focus_mode = Control.FOCUS_NONE
	text = ""
	flat = true
	pressed.connect(_on_pressed)
	_apply_button_style()
	_apply_target_style()

func setup(enemy_data: Dictionary, index: int, wave_level_number: int):
	enemy_index = index
	level_number = max(1, wave_level_number)
	enemy_type = str(enemy_data.get("type", enemy_data.get("kind", TYPE_SMALL)))
	max_health = max(1, int(enemy_data.get("max_health", enemy_data.get("health", 1))))
	current_health = max(0, int(enemy_data.get("health", max_health)))

	name_label.text = str(enemy_data.get("name", "敌人"))
	atk_label.text = "ATK " + str(enemy_data.get("attack", 0))
	boss_tag.visible = bool(enemy_data.get("is_boss", false)) or enemy_type == TYPE_BOSS
	set_dot(int(enemy_data.get("dot_damage", 0)), int(enemy_data.get("dot_duration", 0)))
	update_hp(current_health)
	_apply_type_size()
	_load_sprite()
	set_dead(current_health <= 0)

func update_hp(value: int):
	current_health = max(0, value)
	var percent := clamp(float(current_health) / float(max_health), 0.0, 1.0)
	hp_fill.anchor_right = percent
	hp_fill.color = COLOR_DANGER if percent <= 0.3 else COLOR_HP
	hp_label.text = str(current_health) + "/" + str(max_health)

func set_dot(damage: int, duration: int):
	dot_container.visible = duration > 0
	dot_icon.text = "DoT"
	dot_label.text = str(damage) + "x" + str(duration)

func set_dead(is_dead: bool = true):
	dead_overlay.visible = is_dead
	disabled = is_dead
	modulate.a = 0.65 if is_dead else 1.0

func set_target_highlight(on: bool):
	target_highlight = on
	_apply_target_style()

func _on_pressed():
	if disabled:
		return
	enemy_clicked.emit(enemy_index)

func _load_sprite():
	var sprite_path = "res://assets/enemies/level_%d/enemy_%d_%s_sprite.png" % [level_number, level_number, enemy_type]
	if ResourceLoader.exists(sprite_path):
		sprite_rect.texture = load(sprite_path)
		sprite_rect.visible = true
		fallback_sprite.visible = false
	else:
		sprite_rect.texture = null
		sprite_rect.visible = false
		fallback_sprite.visible = true

func _apply_type_size():
	match enemy_type:
		TYPE_BOSS:
			custom_minimum_size = Vector2(178, 150)
			sprite_container.custom_minimum_size = Vector2(150, 96)
			fallback_sprite.color = COLOR_BOSS
		TYPE_BIG:
			custom_minimum_size = Vector2(128, 150)
			sprite_container.custom_minimum_size = Vector2(104, 96)
			fallback_sprite.color = Color("#2A2A3E")
		_:
			custom_minimum_size = Vector2(104, 150)
			sprite_container.custom_minimum_size = Vector2(80, 80)
			fallback_sprite.color = COLOR_DISABLED

func _apply_button_style():
	add_theme_stylebox_override("normal", _make_style(COLOR_BG, COLOR_BORDER))
	add_theme_stylebox_override("hover", _make_style(Color("#2A2A3E"), COLOR_TARGET))
	add_theme_stylebox_override("pressed", _make_style(Color("#2A2A3E"), COLOR_TARGET))
	add_theme_stylebox_override("disabled", _make_style(COLOR_BG, COLOR_BORDER))
	add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	hp_label.add_theme_color_override("font_color", COLOR_TEXT)
	boss_tag.add_theme_color_override("font_color", COLOR_BOSS)
	atk_label.add_theme_color_override("font_color", COLOR_DANGER)
	dot_icon.add_theme_color_override("font_color", COLOR_DOT)
	dot_label.add_theme_color_override("font_color", COLOR_DOT)
	hp_back.color = Color("#0D0D14")

func _apply_target_style():
	target_frame.visible = target_highlight
	target_frame.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), COLOR_TARGET, 2))

func _make_style(bg_color: Color, border_color: Color, border_width := 2) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style
