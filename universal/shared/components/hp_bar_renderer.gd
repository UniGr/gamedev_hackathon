extends Node
class_name HpBarRenderer
## Универсальный компонент рендера HP-бара.
## Используется модулями и рейдерами для отображения здоровья.
## Рендерит через CanvasItem.draw_* API родителя.

@export var bar_width: float = 80.0
@export var bar_height: float = 7.0
@export var offset: Vector2 = Vector2(6.0, 6.0)
@export var background_color: Color = Color(0.12, 0.12, 0.12, 0.85)
@export var fill_color: Color = Color(0.2, 0.9, 0.35, 0.95)
@export var low_hp_color: Color = Color(1.0, 0.18, 0.18, 0.98)
@export var low_hp_threshold: float = 0.35
@export var center_horizontally: bool = false
@export var anchor_top: bool = true

var _parent_canvas_item: CanvasItem


func _ready() -> void:
	_parent_canvas_item = get_parent() as CanvasItem


func configure_for_module(module_size_px: Vector2) -> void:
	bar_width = maxf(12.0, module_size_px.x - 12.0)
	bar_height = 7.0
	offset = Vector2(6.0, 6.0)
	fill_color = Color(0.2, 0.9, 0.35, 0.95)
	anchor_top = true
	center_horizontally = false


func configure_for_raider(body_size_px: float) -> void:
	bar_width = body_size_px * 1.1
	bar_height = 10.0
	offset = Vector2(-bar_width * 0.5, -body_size_px * 0.72)
	fill_color = Color(1.0, 0.18, 0.18, 0.98)
	anchor_top = true
	center_horizontally = true


func draw_hp_bar(canvas: CanvasItem, hp_ratio: float, anchor_pos: Vector2 = Vector2.ZERO) -> void:
	var ratio: float = clampf(hp_ratio, 0.0, 1.0)
	var bar_pos: Vector2 = anchor_pos + offset
	var bar_size: Vector2 = Vector2(bar_width, bar_height)

	canvas.draw_rect(Rect2(bar_pos, bar_size), background_color, true)

	var current_fill_color: Color = fill_color
	if ratio <= low_hp_threshold:
		current_fill_color = low_hp_color

	var fill_size: Vector2 = Vector2(bar_width * ratio, bar_height)
	canvas.draw_rect(Rect2(bar_pos, fill_size), current_fill_color, true)


func get_bar_rect(anchor_pos: Vector2 = Vector2.ZERO) -> Rect2:
	return Rect2(anchor_pos + offset, Vector2(bar_width, bar_height))


static func draw_simple_hp_bar(
	canvas: CanvasItem,
	hp_ratio: float,
	pos: Vector2,
	width: float,
	height: float,
	bg_color: Color = Color(0.12, 0.12, 0.12, 0.85),
	fill_color_param: Color = Color(0.2, 0.9, 0.35, 0.95)
) -> void:
	var ratio: float = clampf(hp_ratio, 0.0, 1.0)
	var bar_size: Vector2 = Vector2(width, height)

	canvas.draw_rect(Rect2(pos, bar_size), bg_color, true)
	canvas.draw_rect(Rect2(pos, Vector2(width * ratio, height)), fill_color_param, true)
