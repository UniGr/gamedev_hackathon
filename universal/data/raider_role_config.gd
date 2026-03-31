extends Resource
class_name RaiderRoleConfig
## Конфигурация для конкретной роли рейдера (normal, sprinter, tank).
## Используется для Data-Driven балансировки без изменения кода.

@export_group("Identity")
@export var role_name: String = "normal"

@export_group("Movement")
@export var speed_multiplier: float = 1.0
@export var path_wobble_strength: float = 0.22
@export var path_wobble_frequency_hz: float = 1.1

@export_group("Combat")
@export var bite_delay_multiplier: float = 1.0
@export var bite_damage_multiplier: float = 1.0

@export_group("Durability")
@export var hp_multiplier: float = 1.0

@export_group("Visual")
@export var body_size_px: float = 184.0
@export var body_color: Color = Color(0.93, 0.2, 0.2, 1.0)
@export var accent_color: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var texture: Texture2D


func get_speed(base_speed: float) -> float:
	return base_speed * max(0.1, speed_multiplier)


func get_bite_delay(base_delay: float) -> float:
	return base_delay * max(0.1, bite_delay_multiplier)


func get_bite_damage(base_damage: int) -> int:
	return int(ceil(float(base_damage) * max(0.1, bite_damage_multiplier)))


func get_max_hp(base_hp: int) -> int:
	return int(ceil(float(base_hp) * max(0.1, hp_multiplier)))
