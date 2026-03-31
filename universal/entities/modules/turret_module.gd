extends "res://entities/modules/module_base.gd"
class_name TurretModule
const LASER_RENDERER_SCRIPT: Script = preload("res://shared/components/laser_renderer.gd")
const TURRET_TARGETING_SCRIPT: Script = preload("res://shared/components/turret_targeting_component.gd")
const HEAT_MANAGEMENT_SCRIPT: Script = preload("res://shared/components/heat_management_component.gd")

## Data-Driven: конфиг турели загружается из .tres
const DEFAULT_CONFIG: TurretConfig = preload("res://data/turret_config.tres")

@export var config: TurretConfig = DEFAULT_CONFIG

@export var fire_cooldown_sec: float = 0.42
@export var attack_range_cells: float = 4.8
@export var turret_damage: int = 34
@export var target_mode: TurretTargetingComponent.TargetMode = TurretTargetingComponent.TargetMode.ADAPTIVE
@export var lock_on_bonus_damage: int = 8
@export var lock_on_after_shots: int = 3
@export var burst_shots: int = 2
@export var burst_interval_sec: float = 0.08
@export var heat_per_shot: float = 0.16
@export var cool_per_sec: float = 0.42
@export var overheat_threshold: float = 1.0
@export var cooldown_resume_threshold: float = 0.35
@export var laser_color: Color = Color(1.0, 0.35, 0.15, 1.0)
@export var hacked_tint: Color = Color(0.3, 0.95, 0.95, 1.0)

var _fire_timer: Timer
var _burst_timer: Timer
var _laser_renderer: LaserRenderer
var _targeting: TurretTargetingComponent
var _heat_manager: HeatManagementComponent
var _shots_left_in_burst: int = 0
var _hack_disabled_time_left_sec: float = 0.0
var _base_sprite_color: Color = Color.WHITE


func _init() -> void:
	module_id = Constants.MODULE_TURRET
	grid_size = Vector2i.ONE
	metal_cost = Constants.get_module_cost(module_id)
	sprite_color = Color(0.95, 0.32, 0.18, 1.0)
	module_texture = preload("res://assets/sprites/turret.png")
	_base_sprite_color = sprite_color
	_apply_config()


func _apply_config() -> void:
	if config == null:
		config = DEFAULT_CONFIG
	if config == null:
		return
	
	fire_cooldown_sec = config.fire_cooldown_sec
	attack_range_cells = config.attack_range_cells
	turret_damage = config.turret_damage
	lock_on_bonus_damage = config.lock_on_bonus_damage
	lock_on_after_shots = config.lock_on_after_shots
	burst_shots = config.burst_shots
	burst_interval_sec = config.burst_interval_sec
	heat_per_shot = config.heat_per_shot
	cool_per_sec = config.cool_per_sec
	overheat_threshold = config.overheat_threshold
	cooldown_resume_threshold = config.cooldown_resume_threshold
	laser_color = config.laser_color
	hacked_tint = config.hacked_tint
	max_hp = config.max_hp
	tap_damage = config.tap_damage


func _ready() -> void:
	super._ready()

	# Инициализация компонента таргетирования
	_targeting = TURRET_TARGETING_SCRIPT.new() as TurretTargetingComponent
	_targeting.name = "TurretTargetingComponent"
	_targeting.target_mode = target_mode
	_targeting.attack_range_cells = attack_range_cells
	_targeting.lock_on_after_shots = lock_on_after_shots
	add_child(_targeting)

	# Инициализация компонента перегрева
	_heat_manager = HEAT_MANAGEMENT_SCRIPT.new() as HeatManagementComponent
	_heat_manager.name = "HeatManagementComponent"
	_heat_manager.configure(heat_per_shot, cool_per_sec, overheat_threshold, cooldown_resume_threshold)
	add_child(_heat_manager)

	_fire_timer = Timer.new()
	_fire_timer.one_shot = false
	_fire_timer.wait_time = max(0.1, fire_cooldown_sec)
	_fire_timer.timeout.connect(_on_fire_timer)
	add_child(_fire_timer)
	_fire_timer.start()

	_burst_timer = Timer.new()
	_burst_timer.one_shot = false
	_burst_timer.wait_time = max(0.01, burst_interval_sec)
	_burst_timer.timeout.connect(_on_burst_timer)
	add_child(_burst_timer)

	_laser_renderer = LASER_RENDERER_SCRIPT.new() as LaserRenderer
	if _laser_renderer != null:
		_laser_renderer.name = "LaserRenderer"
		_laser_renderer.flash_duration_sec = 0.08
		add_child(_laser_renderer)
		_laser_renderer.set_width(4.0)
		_laser_renderer.set_color(laser_color)


func configure(cell_pos: Vector2i, cell_size: float) -> void:
	super.configure(cell_pos, cell_size)
	if _targeting != null:
		_targeting.set_cell_size(cell_size)


func _process(delta: float) -> void:
	if _hack_disabled_time_left_sec > 0.0:
		_hack_disabled_time_left_sec = max(0.0, _hack_disabled_time_left_sec - delta)
		if _hack_disabled_time_left_sec <= 0.0:
			sprite_color = _base_sprite_color
			queue_redraw()


func _on_fire_timer() -> void:
	if _is_build_mode_active():
		return
	if _is_hacked_disabled():
		return
	if _heat_manager != null and _heat_manager.is_overheated():
		return
	if _burst_timer != null and not _burst_timer.is_stopped():
		return

	var current_target: Node2D = null
	if _targeting != null:
		current_target = _targeting.find_target(get_world_center())
	if current_target == null:
		return

	_shots_left_in_burst = max(1, burst_shots)
	_fire_single_shot(current_target)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst > 0:
		_burst_timer.start()


func _on_burst_timer() -> void:
	var is_overheated: bool = _heat_manager != null and _heat_manager.is_overheated()
	if _is_build_mode_active() or is_overheated or _is_hacked_disabled():
		_burst_timer.stop()
		return

	if _shots_left_in_burst <= 0:
		_burst_timer.stop()
		return

	var current_target: Node2D = null
	if _targeting != null:
		current_target = _targeting.get_current_target()
		if current_target == null or not is_instance_valid(current_target):
			current_target = _targeting.find_target(get_world_center())
			if current_target == null:
				_burst_timer.stop()
				return

	var center: Vector2 = get_world_center()
	var range_px: float = attack_range_cells * cell_size_px
	if current_target != null and center.distance_to(current_target.global_position) > range_px:
		if _targeting != null:
			current_target = _targeting.find_target(center)
		if current_target == null:
			_burst_timer.stop()
			return

	if current_target != null:
		_fire_single_shot(current_target)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst <= 0:
		_burst_timer.stop()


func _fire_single_shot(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	_show_laser_to(target.global_position)
	AudioManager.play_turret_shot()

	var is_locked_on: bool = _targeting != null and _targeting.is_locked_on()
	var damage: int = turret_damage
	if is_locked_on:
		damage += max(0, lock_on_bonus_damage)

	if target.has_method("take_damage"):
		target.call("take_damage", damage, "turret")
	elif target.has_method("take_tap_damage"):
		target.call("take_tap_damage", damage)

	if _targeting != null:
		_targeting.register_hit(target)

	if _heat_manager != null:
		_heat_manager.add_heat()


func _show_laser_to(target_world: Vector2) -> void:
	if _laser_renderer == null:
		return
	_laser_renderer.flash_from_center_to_global(target_world, cell_size_px, grid_size)


func _hide_laser() -> void:
	if _laser_renderer != null:
		_laser_renderer.hide_laser()


func apply_hack_disable(duration_sec: float) -> void:
	_hack_disabled_time_left_sec = max(_hack_disabled_time_left_sec, max(0.3, duration_sec))
	sprite_color = hacked_tint
	if _targeting != null:
		_targeting.clear_target()
	if _burst_timer != null:
		_burst_timer.stop()
	_hide_laser()
	queue_redraw()


func _is_hacked_disabled() -> bool:
	return _hack_disabled_time_left_sec > 0.0
