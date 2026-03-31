extends Resource
class_name TurretConfig
## Конфигурация турели. Data-Driven баланс без изменения кода.

@export_group("Firing")
@export var fire_cooldown_sec: float = 0.42
@export var attack_range_cells: float = 4.8
@export var turret_damage: int = 34

@export_group("Lock-On")
@export var lock_on_bonus_damage: int = 8
@export var lock_on_after_shots: int = 3

@export_group("Burst")
@export var burst_shots: int = 2
@export var burst_interval_sec: float = 0.08

@export_group("Heat Management")
@export var heat_per_shot: float = 0.16
@export var cool_per_sec: float = 0.42
@export var overheat_threshold: float = 1.0
@export var cooldown_resume_threshold: float = 0.35

@export_group("Visual")
@export var laser_color: Color = Color(1.0, 0.35, 0.15, 1.0)
@export var hacked_tint: Color = Color(0.3, 0.95, 0.95, 1.0)

@export_group("Durability")
@export var max_hp: int = 200
@export var tap_damage: int = 32
