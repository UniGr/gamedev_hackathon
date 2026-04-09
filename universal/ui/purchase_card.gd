extends PanelContainer
class_name PurchaseCard
## Универсальная карточка покупки для экранов магазина.
## Отображает иконку, название, описание и цену.
## Проверяет доступность покупки по металлу.

signal card_pressed(module_type: String)

@export var module_type: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D
@export var accent_color: Color = Color(0.439, 0.251, 0.690)

@onready var icon_rect: TextureRect = $ItemMargin/ItemHBox/IconRect
@onready var title_label: Label = $ItemMargin/ItemHBox/InfoVBox/TitleLabel
@onready var desc_label: Label = $ItemMargin/ItemHBox/InfoVBox/DescLabel
@onready var price_label: Label = $ItemMargin/ItemHBox/PriceLabel
@onready var card_button: Button = $CardButton

const COLOR_CAN_BUY: Color = Color(0.941, 0.816, 0.125)
const COLOR_CANNOT_BUY: Color = Color(0.8, 0.2, 0.2)
const BG_NORMAL: Color = Color(0.039, 0.020, 0.125, 1.0)
const BG_DISABLED: Color = Color(0.039, 0.020, 0.125, 0.5)

var _base_style: StyleBoxFlat
var _current_cost: int = 0


func _ready() -> void:
	_cache_base_style()
	_apply_content()
	GameEvents.resource_changed.connect(_on_resource_changed)
	card_button.pressed.connect(_on_card_pressed)
	refresh_affordability()


func setup(p_module_type: String, p_name: String, p_desc: String, p_icon: Texture2D, p_accent: Color) -> void:
	module_type = p_module_type
	display_name = p_name
	description = p_desc
	icon_texture = p_icon
	accent_color = p_accent
	if is_node_ready():
		_apply_content()
		_update_border_color()
		refresh_affordability()


func _apply_content() -> void:
	if title_label:
		title_label.text = display_name
	if desc_label:
		desc_label.text = description
	if icon_rect and icon_texture:
		icon_rect.texture = icon_texture
	_update_border_color()


func refresh_affordability() -> void:
	_current_cost = ResourceManager.get_current_module_cost(module_type)
	var metal: int = ResourceManager.metal
	var can_afford: bool = metal >= _current_cost

	if price_label:
		price_label.text = "%d ⬡" % _current_cost
		price_label.add_theme_color_override("font_color", COLOR_CAN_BUY if can_afford else COLOR_CANNOT_BUY)

	if card_button:
		card_button.disabled = not can_afford

	_update_card_style(can_afford)


func _update_card_style(can_afford: bool) -> void:
	if _base_style == null:
		return
	var style: StyleBoxFlat = _base_style.duplicate()
	style.bg_color = BG_NORMAL if can_afford else BG_DISABLED
	style.border_color = accent_color if can_afford else Color(accent_color, 0.4)
	add_theme_stylebox_override("panel", style)


func _update_border_color() -> void:
	if _base_style == null:
		return
	var style: StyleBoxFlat = _base_style.duplicate()
	style.border_color = accent_color
	add_theme_stylebox_override("panel", style)


func _cache_base_style() -> void:
	var current: StyleBox = get_theme_stylebox("panel")
	if current is StyleBoxFlat:
		_base_style = (current as StyleBoxFlat).duplicate()
	else:
		_base_style = StyleBoxFlat.new()
		_base_style.bg_color = BG_NORMAL
		_base_style.border_width_left = 3
		_base_style.border_width_top = 3
		_base_style.border_width_right = 3
		_base_style.border_width_bottom = 3
		_base_style.border_color = accent_color


func _on_resource_changed(type: String, _new_total: int) -> void:
	if type == "metal":
		refresh_affordability()


func _on_card_pressed() -> void:
	if _current_cost <= 0:
		return
	if ResourceManager.metal < _current_cost:
		return
	GameEvents.build_requested.emit(module_type, Vector2.ZERO)
	card_pressed.emit(module_type)
