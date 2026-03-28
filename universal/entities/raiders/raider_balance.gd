extends Resource
class_name RaiderBalance

@export_group("Raider")
@export var raider_speed_px_per_sec: float = 230.0
@export var raider_attack_distance_px: float = 28.0
@export var raider_bite_delay_sec: float = 0.85
@export var raider_retarget_interval_sec: float = 0.35
@export var raider_max_hp: int = 180
@export var raider_bite_damage: int = 54
@export var player_tap_damage_to_raider: int = 42

@export_group("Spawner")
@export var spawn_interval_start_sec: float = 3.2
@export var spawn_interval_min_sec: float = 1.15
@export var spawn_acceleration_per_sec: float = 0.015
@export_range(0.0, 1.0, 0.01) var spawn_chance_start: float = 0.45
@export_range(0.0, 1.0, 0.01) var spawn_chance_max: float = 0.85
@export var spawn_chance_growth_per_sec: float = 0.018
@export var max_raiders_start: int = 2
@export var max_raiders_cap: int = 7
@export var max_raiders_growth_per_90_sec: int = 1

@export_group("Evolution")
@export var evolution_step_sec: float = 75.0
@export var evolution_max_level: int = 8
@export var evolution_level_per_6_kills: int = 1
@export var speed_gain_per_level: float = 0.12
@export var hp_gain_per_level: float = 0.16
@export var bite_damage_gain_per_level: float = 0.14
@export var bite_delay_reduction_per_level: float = 0.07
