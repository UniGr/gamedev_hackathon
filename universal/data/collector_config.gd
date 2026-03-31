extends Resource
class_name CollectorConfig
## Конфигурация коллектора. Data-Driven баланс без изменения кода.

@export_group("Collection")
@export var collect_cooldown_sec: float = 5.0
@export var collect_radius_from_ship_edge_cells: float = 5.0
@export var mark_radius_from_ship_edge_cells: float = 7.0

@export_group("Visual")
@export var laser_color: Color = Color(0.30, 0.95, 1.0, 1.0)

@export_group("Durability")
@export var max_hp: int = 165
@export var tap_damage: int = 28
