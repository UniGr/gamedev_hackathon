extends Node2D
class_name ModuleBase

const CLICKABLE_COMPONENT_SCRIPT: Script = preload("res://shared/components/clickable_component.gd")

signal destroy_requested(module: ModuleBase, source: String)
signal hp_changed(module: ModuleBase, current_hp: int, max_hp: int, source: String)

@export var module_id: String = ""
@export var grid_size: Vector2i = Vector2i.ONE
@export var metal_cost: int = 0
@export var defence_bonus: int = 0
@export var energy_radius_cells: int = 0
@export var facing_direction: Vector2 = Vector2.UP
@export var sprite_color: Color = Color(0.55, 0.55, 0.55, 1.0)

@export_group("Durability")
@export var max_hp: int = 140
@export var tap_damage: int = 28

var grid_position: Vector2i = Vector2i.ZERO
var cell_size_px: float = 90.0
var current_hp: int = 0

var _clickable: Area2D
var _collision_shape: CollisionShape2D


func configure(cell_pos: Vector2i, cell_size: float) -> void:
	grid_position = cell_pos
	cell_size_px = cell_size
	position = Vector2(cell_pos.x * cell_size_px, cell_pos.y * cell_size_px)
	if current_hp <= 0:
		current_hp = max(1, max_hp)
	_ensure_clickable()
	_update_click_shape_size()
	queue_redraw()


func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(grid_position.x, grid_position.x + grid_size.x):
		for y in range(grid_position.y, grid_position.y + grid_size.y):
			result.append(Vector2i(x, y))
	return result


func get_world_center() -> Vector2:
	return global_position + Vector2(grid_size.x, grid_size.y) * cell_size_px * 0.5


func set_facing_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()


func take_damage(amount: int, source: String = "unknown") -> bool:
	var damage: int = max(0, amount)
	if damage <= 0:
		return false

	if current_hp <= 0:
		current_hp = max(1, max_hp)

	current_hp = max(0, current_hp - damage)
	hp_changed.emit(self, current_hp, max_hp, source)
	GameEvents.module_damaged.emit(module_id, current_hp, max_hp, Vector2(grid_position), source)
	queue_redraw()

	if current_hp <= 0:
		destroy_requested.emit(self, source)
		return true

	return false


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clamp(float(current_hp) / float(max_hp), 0.0, 1.0)


func _ensure_clickable() -> void:
	if _clickable != null and is_instance_valid(_clickable):
		return

	_clickable = Area2D.new()
	_clickable.name = "ClickableComponent"
	_clickable.script = CLICKABLE_COMPONENT_SCRIPT
	_clickable.set("one_shot", false)
	add_child(_clickable)

	_collision_shape = CollisionShape2D.new()
	_collision_shape.name = "CollisionShape2D"
	_clickable.add_child(_collision_shape)

	if _clickable.has_signal("clicked"):
		_clickable.connect("clicked", _on_tapped)


func _update_click_shape_size() -> void:
	if _collision_shape == null or not is_instance_valid(_collision_shape):
		return

	var rect_shape: RectangleShape2D
	if _collision_shape.shape is RectangleShape2D:
		rect_shape = _collision_shape.shape as RectangleShape2D
	else:
		rect_shape = RectangleShape2D.new()
		_collision_shape.shape = rect_shape

	rect_shape.size = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	_collision_shape.position = Vector2(rect_shape.size.x * 0.5, rect_shape.size.y * 0.5)


func _on_tapped() -> void:
	if _is_build_mode_active():
		return
	take_damage(tap_damage, "tap")


func _is_build_mode_active() -> bool:
	var cursor: Node = get_parent()
	while cursor != null:
		if cursor.has_method("is_build_mode_active"):
			return bool(cursor.call("is_build_mode_active"))
		cursor = cursor.get_parent()
	return false


func _draw() -> void:
	var size_px: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	var fill_rect: Rect2 = Rect2(Vector2.ZERO, size_px)

	draw_rect(fill_rect, sprite_color, true)
	draw_rect(fill_rect, Color(0.08, 0.08, 0.08, 1.0), false, 2.0)

	var hp_ratio: float = get_hp_ratio()
	var hp_back_size: Vector2 = Vector2(max(12.0, size_px.x - 12.0), 7.0)
	var hp_back_pos: Vector2 = Vector2(6.0, 6.0)
	draw_rect(Rect2(hp_back_pos, hp_back_size), Color(0.12, 0.12, 0.12, 0.85), true)
	draw_rect(Rect2(hp_back_pos, Vector2(hp_back_size.x * hp_ratio, hp_back_size.y)), Color(0.2, 0.9, 0.35, 0.95), true)
