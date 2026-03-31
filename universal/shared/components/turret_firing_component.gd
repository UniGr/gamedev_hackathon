extends Node
class_name TurretFiringComponent
## Компонент управления стрельбой турели.
## Отвечает за таймеры стрельбы, burst-режим, нанесение урона.

signal shot_fired(target: Node2D, damage: int)
signal burst_started()
signal burst_ended()

@export var fire_cooldown_sec: float = 0.42
@export var burst_shots: int = 2
@export var burst_interval_sec: float = 0.08
@export var base_damage: int = 34
@export var lock_on_bonus_damage: int = 8

var _fire_timer: Timer
var _burst_timer: Timer
var _shots_left_in_burst: int = 0
var _is_firing_enabled: bool = true


func _ready() -> void:
	_fire_timer = Timer.new()
	_fire_timer.one_shot = false
	_fire_timer.wait_time = maxf(0.1, fire_cooldown_sec)
	_fire_timer.timeout.connect(_on_fire_timer)
	add_child(_fire_timer)

	_burst_timer = Timer.new()
	_burst_timer.one_shot = false
	_burst_timer.wait_time = maxf(0.01, burst_interval_sec)
	_burst_timer.timeout.connect(_on_burst_timer)
	add_child(_burst_timer)


func configure(cooldown_sec: float, shots: int, interval_sec: float, damage: int) -> void:
	fire_cooldown_sec = maxf(0.1, cooldown_sec)
	burst_shots = maxi(1, shots)
	burst_interval_sec = maxf(0.01, interval_sec)
	base_damage = maxi(1, damage)

	if _fire_timer != null:
		_fire_timer.wait_time = fire_cooldown_sec
	if _burst_timer != null:
		_burst_timer.wait_time = burst_interval_sec


func start() -> void:
	if _fire_timer != null:
		_fire_timer.start()
	_is_firing_enabled = true


func stop() -> void:
	if _fire_timer != null:
		_fire_timer.stop()
	if _burst_timer != null:
		_burst_timer.stop()
	_shots_left_in_burst = 0
	_is_firing_enabled = false


func is_in_burst() -> bool:
	return _burst_timer != null and not _burst_timer.is_stopped()


func is_firing_enabled() -> bool:
	return _is_firing_enabled


func set_firing_enabled(enabled: bool) -> void:
	_is_firing_enabled = enabled
	if not enabled:
		stop_burst()


func stop_burst() -> void:
	if _burst_timer != null:
		_burst_timer.stop()
	_shots_left_in_burst = 0


func calculate_damage(is_locked_on: bool) -> int:
	var damage: int = base_damage
	if is_locked_on:
		damage += maxi(0, lock_on_bonus_damage)
	return damage


func request_fire(target: Node2D, is_locked_on: bool) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not _is_firing_enabled:
		return false

	_shots_left_in_burst = maxi(1, burst_shots)
	_fire_single_shot(target, is_locked_on)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst > 0:
		burst_started.emit()
		_burst_timer.start()

	return true


func continue_burst(target: Node2D, is_locked_on: bool) -> bool:
	if not _is_firing_enabled:
		stop_burst()
		return false

	if _shots_left_in_burst <= 0:
		stop_burst()
		burst_ended.emit()
		return false

	if target == null or not is_instance_valid(target):
		stop_burst()
		burst_ended.emit()
		return false

	_fire_single_shot(target, is_locked_on)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst <= 0:
		stop_burst()
		burst_ended.emit()

	return true


func _fire_single_shot(target: Node2D, is_locked_on: bool) -> void:
	var damage: int = calculate_damage(is_locked_on)
	shot_fired.emit(target, damage)


func _on_fire_timer() -> void:
	pass


func _on_burst_timer() -> void:
	pass
