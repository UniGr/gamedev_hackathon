extends Node
## Глобальная шина событий (Event Bus) для всех систем игры.
## Главный принцип: никаких прямых ссылок между модулями!
## Все взаимодействие происходит через сигналы.

# ========== Сигналы взаимодействия ==========

## Игрок тапнул по мусору
signal garbage_clicked(amount: int)

## Ресурсы изменились (металл, энергия)
signal resource_changed(type: String, new_total: int)

## Улучшение куплено
signal upgrade_purchased(upgrade_id: String, new_level: int)

## Запрос на постройку модуля
signal build_requested(module_type: String, position: Vector2)

## Режим постройки отменен (например, клик по невалидному месту)
signal build_mode_cancelled(module_type: String)

## Модуль построен
signal module_built(module_type: String, position: Vector2)

## Модуль разрушен
signal module_destroyed(module_type: String, position: Vector2)

## Игра начата
signal game_started

## Игра закончена
signal game_ended

## Защита корабля изменилась
signal defence_changed(new_total: int)

## Разрешение столкновения с врагом
signal collision_resolved(hazard_class: int, success: bool, modules_lost: int, discounted_builds: int)
