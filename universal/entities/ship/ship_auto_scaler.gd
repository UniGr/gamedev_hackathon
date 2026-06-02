extends Node
class_name ShipAutoScaler
## Авто-масштабирование корабля.
## Единственный владелец трансформа ModulesRoot/HighlightsRoot: задаёт и scale, и position.
## Когда корабль разрастается к границам экрана — плавно уменьшает масштаб, чтобы он влезал
## в игровую область (между верхней панелью и нижним навбаром), оставаясь по центру.
##
## ShipSway не пишет в узлы напрямую, а передаёт сюда смещение через set_sway_offset().

@export var modules_root_path: NodePath = NodePath("../ModulesRoot")
@export var highlights_root_path: NodePath = NodePath("../HighlightsRoot")

## Запас по краям игровой области.
@export var side_margin_px: float = 24.0
## Высота верхней панели HUD (зона, которую нельзя занимать).
@export var top_margin_px: float = 230.0
## Высота нижнего навбара + отступ (совпадает с bottom_ui_offset в game_board).
@export var bottom_margin_px: float = 250.0
## Минимально допустимый масштаб (предел отдаления).
@export var min_scale: float = 0.16
## Скорость сглаживания изменения масштаба/позиции.
@export var smooth_speed: float = 6.0

var _modules_root: Node2D
var _highlights_root: Node2D
var _game_board: Node

var _scale: float = 1.0
var _base_position: Vector2 = Vector2.ZERO
var _sway_offset: Vector2 = Vector2.ZERO
var _initialized: bool = false


func _ready() -> void:
	# Должен работать и на паузе (модули ставятся в режиме строительства при paused == true).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_board = get_parent()


func set_sway_offset(offset: Vector2) -> void:
	_sway_offset = offset


func _process(delta: float) -> void:
	if not _ensure_bindings():
		return

	var targets: Array = _compute_targets()
	var target_scale: float = targets[0]
	var target_base: Vector2 = targets[1]

	if not _initialized:
		_scale = target_scale
		_base_position = target_base
		_initialized = true
	else:
		var t: float = clampf(smooth_speed * delta, 0.0, 1.0)
		_scale = lerpf(_scale, target_scale, t)
		_base_position = _base_position.lerp(target_base, t)

	_apply_transform()


## Возвращает [target_scale: float, target_base_position: Vector2].
func _compute_targets() -> Array:
	var viewport: Vector2 = get_viewport().get_visible_rect().size

	var avail_w: float = max(1.0, viewport.x - side_margin_px * 2.0)
	var avail_h: float = max(1.0, viewport.y - top_margin_px - bottom_margin_px)

	var bounds: Rect2 = Rect2()
	if _game_board != null and _game_board.has_method("get_ship_local_bounds"):
		bounds = _game_board.call("get_ship_local_bounds")

	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return [1.0, _base_position]

	var fit: float = min(avail_w / bounds.size.x, avail_h / bounds.size.y)
	var target_scale: float = clampf(min(1.0, fit), min_scale, 1.0)

	# Корабль строится только вверх от ядра, поэтому якорим его НИЗ к низу игровой области
	# и центрируем по горизонтали. Так ядро остаётся внизу, а рост идёт вверх.
	var ship_center_x: float = bounds.position.x + bounds.size.x * 0.5
	var ship_bottom_y: float = bounds.position.y + bounds.size.y
	var play_bottom: float = top_margin_px + avail_h

	var target_base: Vector2 = Vector2(
		viewport.x * 0.5 - ship_center_x * target_scale,
		play_bottom - ship_bottom_y * target_scale
	)

	return [target_scale, target_base]


func _apply_transform() -> void:
	var final_position: Vector2 = _base_position + _sway_offset
	var scale_vec: Vector2 = Vector2(_scale, _scale)
	_modules_root.scale = scale_vec
	_modules_root.position = final_position
	if _highlights_root != null and is_instance_valid(_highlights_root):
		_highlights_root.scale = scale_vec
		_highlights_root.position = final_position


func _ensure_bindings() -> bool:
	if _modules_root == null or not is_instance_valid(_modules_root):
		_modules_root = get_node_or_null(modules_root_path) as Node2D
	if _highlights_root == null or not is_instance_valid(_highlights_root):
		_highlights_root = get_node_or_null(highlights_root_path) as Node2D
	if _game_board == null or not is_instance_valid(_game_board):
		_game_board = get_parent()
	return _modules_root != null and is_instance_valid(_modules_root)
