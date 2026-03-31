extends Node2D
class_name ModuleBase

const HEALTH_COMPONENT_SCRIPT: Script = preload("res://shared/components/health_component.gd")

signal destroy_requested(module: ModuleBase, source: String)
signal hp_changed(module: ModuleBase, current_hp: int, max_hp: int, source: String)

@export var module_id: String = ""
@export var grid_size: Vector2i = Vector2i.ONE
@export var metal_cost: int = 0
@export var defence_bonus: int = 0
@export var energy_radius_cells: int = 0
@export var facing_direction: Vector2 = Vector2.UP
@export var sprite_color: Color = Color(0.55, 0.55, 0.55, 1.0)
@export var module_texture: Texture2D

@export_group("Durability")
@export var max_hp: int = 140
@export var tap_damage: int = 28
@export var allow_player_tap_damage: bool = false

var grid_position: Vector2i = Vector2i.ZERO
var cell_size_px: float = float(GridManager.CELL_SIZE)
var current_hp: int = 0

var _clickable: Area2D
var _collision_shape: CollisionShape2D
var _is_build_mode_active_cached: bool = false
var _health: HealthComponent


func _ready() -> void:
	if GameEvents.has_signal("build_mode_changed"):
		GameEvents.build_mode_changed.connect(_on_build_mode_changed)
	_ensure_health_component()


func configure(cell_pos: Vector2i, cell_size: float) -> void:
	grid_position = cell_pos
	cell_size_px = cell_size
	position = Vector2(cell_pos.x * cell_size_px, cell_pos.y * cell_size_px)
	if current_hp <= 0:
		current_hp = max(1, max_hp)
		if _health != null:
			_health.set_max_hp(max_hp, true)
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

	_ensure_health_component()
	if _health == null:
		return false
	return _health.take_damage(damage, source)


func get_hp_ratio() -> float:
	if _health != null:
		return _health.get_hp_ratio()
	if max_hp <= 0:
		return 0.0
	return clamp(float(current_hp) / float(max_hp), 0.0, 1.0)


func _ensure_clickable() -> void:
	if _clickable != null and is_instance_valid(_clickable):
		return

	var setup: Dictionary = ClickableSetup.create_clickable(self, _on_tapped, false)
	_clickable = setup.get("clickable") as Area2D
	_collision_shape = setup.get("collision") as CollisionShape2D


func _update_click_shape_size() -> void:
	var size: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	ClickableSetup.update_rect_shape(_collision_shape, size)


func _on_tapped() -> void:
	if _is_build_mode_active():
		return
	if not allow_player_tap_damage:
		return
	take_damage(tap_damage, "tap")


func _is_build_mode_active() -> bool:
	return _is_build_mode_active_cached


func _on_build_mode_changed(is_active: bool) -> void:
	_is_build_mode_active_cached = is_active


func _ensure_health_component() -> void:
	if _health != null and is_instance_valid(_health):
		return

	var existing: Node = get_node_or_null("HealthComponent")
	if existing is HealthComponent:
		_health = existing as HealthComponent
	else:
		_health = HEALTH_COMPONENT_SCRIPT.new() as HealthComponent
		_health.name = "HealthComponent"
		add_child(_health)

	_health.max_hp = max(1, max_hp)
	_health.initial_hp = max(1, current_hp) if current_hp > 0 else _health.max_hp
	_health.reset(current_hp <= 0)
	max_hp = _health.max_hp
	current_hp = _health.current_hp

	if not _health.damaged.is_connected(_on_health_damaged):
		_health.damaged.connect(_on_health_damaged)
	if not _health.died.is_connected(_on_health_died):
		_health.died.connect(_on_health_died)
	if not _health.hp_changed.is_connected(_on_health_hp_changed):
		_health.hp_changed.connect(_on_health_hp_changed)


func _on_health_damaged(_amount: int, new_hp: int, health_max_hp: int, source: String) -> void:
	current_hp = new_hp
	max_hp = health_max_hp
	hp_changed.emit(self, current_hp, max_hp, source)
	GameEvents.module_damaged.emit(module_id, current_hp, max_hp, Vector2(grid_position), source)
	queue_redraw()


func _on_health_died(source: String) -> void:
	destroy_requested.emit(self, source)


func _on_health_hp_changed(new_hp: int, health_max_hp: int) -> void:
	current_hp = new_hp
	max_hp = health_max_hp
	queue_redraw()


func _draw() -> void:
	var size_px: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	var fill_rect: Rect2 = Rect2(Vector2.ZERO, size_px)

	if module_texture != null:
		draw_texture_rect(module_texture, fill_rect, false)
	else:
		draw_rect(fill_rect, sprite_color, true)
		draw_rect(fill_rect, Color(0.08, 0.08, 0.08, 1.0), false, 2.0)

	var hp_ratio: float = get_hp_ratio()
	var hp_back_size: Vector2 = Vector2(max(12.0, size_px.x - 12.0), 7.0)
	var hp_back_pos: Vector2 = Vector2(6.0, 6.0)
	draw_rect(Rect2(hp_back_pos, hp_back_size), Color(0.12, 0.12, 0.12, 0.85), true)
	draw_rect(Rect2(hp_back_pos, Vector2(hp_back_size.x * hp_ratio, hp_back_size.y)), Color(0.2, 0.9, 0.35, 0.95), true)
