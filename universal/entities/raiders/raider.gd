extends Node2D
class_name Raider
## Враг-налётчик, атакующий модули корабля.
## Использует компонентную архитектуру: AI, Movement, Combat.

enum RaiderRole {
	NORMAL,  ## Стандартный налётчик
	TANK,    ## Медленный, но прочный
	SPRINTER ## Быстрый, но хрупкий
}

const TempCombatVfxScript: Script = preload("res://entities/effects/temp_combat_vfx.gd")
const TempCombatSfxScript: Script = preload("res://entities/effects/temp_combat_sfx.gd")
const HealthComponentScript: Script = preload("res://shared/components/health_component.gd")
const HpBarRendererScript: Script = preload("res://shared/components/hp_bar_renderer.gd")

const RaiderAIComponentScript: Script = preload("res://shared/components/raider_ai_component.gd")
const RaiderMovementComponentScript: Script = preload("res://shared/components/raider_movement_component.gd")
const RaiderCombatComponentScript: Script = preload("res://shared/components/raider_combat_component.gd")
const ViewportBoundsComponentScript: Script = preload("res://shared/components/viewport_bounds_component.gd")
const RaiderAnimationComponentScript: Script = preload("res://shared/components/raider_animation_component.gd")

## Data-Driven: конфиги ролей загружаются из .tres файлов
const ROLE_CONFIG_NORMAL: RaiderRoleConfig = preload("res://data/raider_role_normal.tres")
const ROLE_CONFIG_SPRINTER: RaiderRoleConfig = preload("res://data/raider_role_sprinter.tres")
const ROLE_CONFIG_TANK: RaiderRoleConfig = preload("res://data/raider_role_tank.tres")

@export_group("Raider Movement")
@export var movement_speed_px_per_sec: float = 285.0
@export var attack_distance_px: float = 96.0
@export var retarget_interval_sec: float = 0.35
@export var path_wobble_strength: float = 0.22
@export var path_wobble_frequency_hz: float = 1.1
@export var path_wobble_strength_random_range: float = 0.12
@export var path_wobble_frequency_random_range: float = 0.3
@export var speed_random_range: float = 0.12

@export_group("Raider Attack")
@export var bite_delay_sec: float = 0.85
@export var bite_damage: int = 54

@export_group("Raider Durability")
@export var max_hp: int = 180
@export var player_tap_damage: int = 42

@export_group("Raider Roles")
@export var role_name: String = "normal"

@export_group("Raider Visual")
@export var body_size_px: float = 184.0
@export var body_color: Color = Color(0.93, 0.2, 0.2, 1.0)
@export var accent_color: Color = Color(1.0, 0.45, 0.45, 1.0)

var _board: Node
var _role: int = RaiderRole.NORMAL
var _role_config: RaiderRoleConfig
var _is_biting: bool = false

var _vfx: TempCombatVfx
var _sfx: TempCombatSfx
var _health: HealthComponent
var _hp_bar: HpBarRenderer
var _body_sprite: Sprite2D
var _clickable: Area2D
var _collision_shape: CollisionShape2D

var _ai: RaiderAIComponent
var _movement: RaiderMovementComponent
var _combat: RaiderCombatComponent
var _viewport_bounds: ViewportBoundsComponent
var _animation: RaiderAnimationComponent
var _base_movement_speed: float = 285.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("raiders")

	_body_sprite = get_node_or_null("BodySprite") as Sprite2D
	_apply_role_sprite()
	_ensure_health_component()
	_ensure_hp_bar_renderer()
	_ensure_runtime_components()

	_vfx = TempCombatVfxScript.new() as TempCombatVfx
	if _vfx != null:
		if _vfx.has_method("set_palette"):
			_vfx.call("set_palette", body_color, accent_color)
		add_child(_vfx)
		_vfx.play_spawn(global_position)
	GameEvents.raider_spawned.emit(global_position)

	_sfx = TempCombatSfxScript.new() as TempCombatSfx
	if _sfx != null:
		add_child(_sfx)
		_sfx.play_spawn(global_position)

	_ensure_clickable()
	_update_click_shape()
	_configure_components_from_exports()
	_setup_animation_from_role()
	_clamp_to_viewport()
	queue_redraw()


func _process(delta: float) -> void:
	if _is_biting:
		return
	if _board == null:
		_queue_despawn()
		return
	if _ai == null or _movement == null:
		_queue_despawn()
		return

	if not _ai.is_target_valid():
		_ai.acquire_target()
	if not _ai.is_target_valid():
		_queue_despawn()
		return

	var target: ModuleBase = _ai.get_target()
	if target == null or not is_instance_valid(target):
		_queue_despawn()
		return

	var reached: bool = _movement.move_toward_target(target.get_world_center(), delta)
	if reached:
		_start_bite(target)
		return

	_clamp_to_viewport()


func set_game_board(board: Node) -> void:
	_board = board
	if _ai != null:
		_ai.set_board(board)
	if _combat != null:
		_combat.set_board(board)


func configure_from_balance(balance: RaiderBalance) -> void:
	if balance == null:
		return

	movement_speed_px_per_sec = max(10.0, balance.raider_speed_px_per_sec)
	_base_movement_speed = movement_speed_px_per_sec
	attack_distance_px = max(8.0, balance.raider_attack_distance_px)
	bite_delay_sec = max(0.1, balance.raider_bite_delay_sec)
	retarget_interval_sec = max(0.1, balance.raider_retarget_interval_sec)
	max_hp = max(1, balance.raider_max_hp)
	bite_damage = max(1, balance.raider_bite_damage)
	player_tap_damage = max(1, balance.player_tap_damage_to_raider)
	_set_health_to(max_hp)
	_configure_components_from_exports()


func configure_role_hp(role_hp: int) -> void:
	max_hp = max(1, role_hp)
	_set_health_to(max_hp)
	queue_redraw()


func configure_role(role: int) -> void:
	_role = clamp(role, RaiderRole.NORMAL, RaiderRole.SPRINTER)
	_role_config = _get_role_config(_role)
	_apply_role_from_config()
	if _ai != null:
		_ai.set_role(_role)
	queue_redraw()


func _get_role_config(role: int) -> RaiderRoleConfig:
	match role:
		RaiderRole.SPRINTER:
			return ROLE_CONFIG_SPRINTER
		RaiderRole.TANK:
			return ROLE_CONFIG_TANK
		_:
			return ROLE_CONFIG_NORMAL


func _apply_role_from_config() -> void:
	if _role_config == null:
		_role_config = ROLE_CONFIG_NORMAL
	
	role_name = _role_config.role_name
	body_size_px = _role_config.body_size_px
	body_color = _role_config.body_color
	accent_color = _role_config.accent_color
	path_wobble_strength = _role_config.path_wobble_strength
	path_wobble_frequency_hz = _role_config.path_wobble_frequency_hz
	movement_speed_px_per_sec = _role_config.get_speed(_base_movement_speed)
	
	_apply_role_sprite()
	_update_click_shape()
	_configure_components_from_exports()
	_setup_animation_from_role()
	
	# Обновляем HP bar под новый размер
	if _hp_bar != null:
		_hp_bar.configure_for_raider(body_size_px)


func take_damage(amount: int, source: String = "unknown") -> bool:
	var damage: int = max(1, amount)
	_ensure_health_component()
	if _health == null:
		return false
	return _health.take_damage(damage, source)


func take_tap_damage(amount: int) -> bool:
	return take_damage(amount, "tap")


func get_hp_ratio() -> float:
	if _health != null:
		return _health.get_hp_ratio()
	if max_hp <= 0:
		return 0.0
	return 1.0


func get_role_name() -> String:
	return role_name


func _start_bite(target: ModuleBase) -> void:
	if _combat == null or _is_biting:
		return
	_is_biting = true
	_combat.start_bite(target)


func _on_bite_started() -> void:
	GameEvents.raider_bite.emit(global_position)
	if _sfx != null:
		_sfx.play_bite(global_position)
	if _vfx != null:
		_vfx.play_bite(global_position)


func _on_bite_executed(target, success: bool) -> void:
	var target_world: Vector2 = global_position
	if target != null and is_instance_valid(target) and target is ModuleBase:
		target_world = (target as ModuleBase).get_world_center()

	if success:
		if _vfx != null:
			_vfx.play_destroy(target_world)
		if _sfx != null:
			_sfx.play_destroy(target_world)

	_is_biting = false
	if _ai != null and not _ai.is_target_valid():
		_ai.acquire_target()


func _on_tapped() -> void:
	take_tap_damage(player_tap_damage)


func _queue_despawn() -> void:
	if is_queued_for_deletion():
		return
	queue_free()


func _ensure_runtime_components() -> void:
	if _ai == null:
		_ai = get_node_or_null("RaiderAIComponent") as RaiderAIComponent
		if _ai == null:
			_ai = RaiderAIComponentScript.new() as RaiderAIComponent
			_ai.name = "RaiderAIComponent"
			add_child(_ai)
	if _movement == null:
		_movement = get_node_or_null("RaiderMovementComponent") as RaiderMovementComponent
		if _movement == null:
			_movement = RaiderMovementComponentScript.new() as RaiderMovementComponent
			_movement.name = "RaiderMovementComponent"
			add_child(_movement)
	if _combat == null:
		_combat = get_node_or_null("RaiderCombatComponent") as RaiderCombatComponent
		if _combat == null:
			_combat = RaiderCombatComponentScript.new() as RaiderCombatComponent
			_combat.name = "RaiderCombatComponent"
			add_child(_combat)
	if _viewport_bounds == null:
		_viewport_bounds = get_node_or_null("ViewportBoundsComponent") as ViewportBoundsComponent
		if _viewport_bounds == null:
			_viewport_bounds = ViewportBoundsComponentScript.new() as ViewportBoundsComponent
			_viewport_bounds.name = "ViewportBoundsComponent"
			add_child(_viewport_bounds)
	if _animation == null:
		_animation = get_node_or_null("RaiderAnimationComponent") as RaiderAnimationComponent
		if _animation == null:
			_animation = RaiderAnimationComponentScript.new() as RaiderAnimationComponent
			_animation.name = "RaiderAnimationComponent"
			add_child(_animation)

	if not _combat.bite_started.is_connected(_on_bite_started):
		_combat.bite_started.connect(_on_bite_started)
	if not _combat.bite_executed.is_connected(_on_bite_executed):
		_combat.bite_executed.connect(_on_bite_executed)


func _configure_components_from_exports() -> void:
	if _ai != null:
		_ai.configure_retarget_interval(retarget_interval_sec)
		_ai.set_role(_role)
		_ai.set_board(_board)

	if _movement != null:
		_movement.configure_speed(movement_speed_px_per_sec)
		_movement.configure_attack_distance(attack_distance_px)
		_movement.path_wobble_strength = path_wobble_strength
		_movement.path_wobble_frequency_hz = path_wobble_frequency_hz
		_movement.path_wobble_strength_random_range = path_wobble_strength_random_range
		_movement.path_wobble_frequency_random_range = path_wobble_frequency_random_range
		_movement.speed_random_range = speed_random_range
		_movement.randomize_parameters()

	if _combat != null:
		_combat.configure_bite(bite_delay_sec, bite_damage)
		_combat.set_board(_board)

	if _viewport_bounds != null:
		_viewport_bounds.enabled = false
		_viewport_bounds.set_half_size(Vector2(body_size_px * 0.5, body_size_px * 0.5))
		_viewport_bounds.set_margins(0.0, body_size_px * 0.72 + 10.0 - (body_size_px * 0.5), 0.0)


func _ensure_clickable() -> void:
	if _clickable != null and is_instance_valid(_clickable):
		return

	var setup: Dictionary = ClickableSetup.create_clickable(self, _on_tapped, false)
	_clickable = setup.get("clickable") as Area2D
	_collision_shape = setup.get("collision") as CollisionShape2D


func _update_click_shape() -> void:
	ClickableSetup.update_circle_shape(_collision_shape, body_size_px * 0.6)


func _apply_role_sprite() -> void:
	if _body_sprite == null or not is_instance_valid(_body_sprite):
		return

	if _role_config != null and _role_config.texture != null:
		_body_sprite.texture = _role_config.texture
		return

	# Fallback: загрузка текстур напрямую если конфиг не установлен
	match role_name:
		"sprinter":
			_body_sprite.texture = preload("res://assets/sprites/sprinter.png")
		"tank":
			_body_sprite.texture = preload("res://assets/sprites/tank.png")
		_:
			_body_sprite.texture = preload("res://assets/sprites/normal.png")


func _setup_animation_from_role() -> void:
	if _animation == null or _body_sprite == null:
		return
	if _role_config == null or not _role_config.use_frame_animation:
		_animation.stop()
		return
	_animation.configure(
		_body_sprite,
		_role_config.animation_frames_base_path,
		_role_config.animation_frame_count,
		_role_config.animation_fps
	)


func _clamp_to_viewport() -> void:
	if _viewport_bounds != null:
		_viewport_bounds.clamp_parent_position()
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var body_half: float = body_size_px * 0.5
	var hp_top_padding: float = body_size_px * 0.72 + 10.0
	global_position = ViewportBoundsComponent.clamp_position(
		global_position,
		viewport_size,
		Vector2(body_half, body_half),
		0.0,
		hp_top_padding - body_half,
		0.0
	)


func _draw() -> void:
	# HP bar рендерится через компонент
	if _hp_bar != null:
		_hp_bar.draw_hp_bar(self, get_hp_ratio())


func _ensure_hp_bar_renderer() -> void:
	if _hp_bar != null and is_instance_valid(_hp_bar):
		return

	var existing: Node = get_node_or_null("HpBarRenderer")
	if existing is HpBarRenderer:
		_hp_bar = existing as HpBarRenderer
	else:
		_hp_bar = HpBarRendererScript.new() as HpBarRenderer
		_hp_bar.name = "HpBarRenderer"
		add_child(_hp_bar)

	_hp_bar.configure_for_raider(body_size_px)


func _ensure_health_component() -> void:
	if _health != null and is_instance_valid(_health):
		return

	var existing: Node = get_node_or_null("HealthComponent")
	if existing is HealthComponent:
		_health = existing as HealthComponent
	else:
		_health = HealthComponentScript.new() as HealthComponent
		_health.name = "HealthComponent"
		_health.max_hp = max(1, max_hp)
		_health.initial_hp = _health.max_hp
		add_child(_health)

	_health.set_max_hp(max(1, max_hp), true)
	max_hp = _health.max_hp

	if not _health.damaged.is_connected(_on_health_damaged):
		_health.damaged.connect(_on_health_damaged)
	if not _health.died.is_connected(_on_health_died):
		_health.died.connect(_on_health_died)
	if not _health.hp_changed.is_connected(_on_health_hp_changed):
		_health.hp_changed.connect(_on_health_hp_changed)


func _set_health_to(new_max_hp: int) -> void:
	_ensure_health_component()
	if _health == null:
		return
	_health.set_max_hp(max(1, new_max_hp), true)
	max_hp = _health.max_hp
	queue_redraw()


func _on_health_damaged(_amount: int, current_hp: int, health_max_hp: int, _source: String) -> void:
	max_hp = health_max_hp
	GameEvents.raider_damaged.emit(current_hp, max_hp, global_position)

	if _vfx != null:
		_vfx.play_bite(global_position)
	if _sfx != null:
		_sfx.play_bite(global_position)

	queue_redraw()


func _on_health_died(source: String) -> void:
	if _vfx != null:
		_vfx.play_destroy(global_position)
	if _sfx != null:
		_sfx.play_destroy(global_position)
	GameEvents.raider_destroyed.emit(global_position, 0, source)
	queue_free()


func _on_health_hp_changed(_current_hp: int, health_max_hp: int) -> void:
	max_hp = health_max_hp
	queue_redraw()
