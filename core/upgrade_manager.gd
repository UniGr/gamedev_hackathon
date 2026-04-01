extends Node
## Менеджер улучшений. Держит уровни улучшений и проверяет покупку.

var _upgrade_levels: Dictionary = {
	Constants.UPGRADE_CORE_ID: 0,
}


func get_upgrade_ids() -> Array[String]:
	return Constants.UPGRADE_IDS.duplicate()


func get_upgrade_name(upgrade_id: String) -> String:
	if upgrade_id == Constants.UPGRADE_CORE_ID:
		return Constants.UPGRADE_CORE_NAME
	return upgrade_id


func get_upgrade_level(upgrade_id: String) -> int:
	return int(_upgrade_levels.get(upgrade_id, 0))


func get_upgrade_max_level(upgrade_id: String) -> int:
	if upgrade_id == Constants.UPGRADE_CORE_ID:
		return Constants.get_core_upgrade_max_level()
	return 0


func get_upgrade_next_cost(upgrade_id: String) -> int:
	if upgrade_id == Constants.UPGRADE_CORE_ID:
		return Constants.get_core_upgrade_next_cost(get_upgrade_level(upgrade_id))
	return -1


func is_upgrade_maxed(upgrade_id: String) -> bool:
	return get_upgrade_level(upgrade_id) >= get_upgrade_max_level(upgrade_id)


func can_purchase(upgrade_id: String) -> bool:
	var next_cost: int = get_upgrade_next_cost(upgrade_id)
	if next_cost < 0:
		return false
	return ResourceManager.metal >= next_cost


func purchase(upgrade_id: String) -> bool:
	var next_cost: int = get_upgrade_next_cost(upgrade_id)
	if next_cost < 0:
		return false
	if not ResourceManager.spend_metal(next_cost):
		return false

	_upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	GameEvents.upgrade_purchased.emit(upgrade_id, get_upgrade_level(upgrade_id))
	return true


func get_metal_reward_for_debris(debris_type: int) -> int:
	return Constants.get_core_upgrade_reward(debris_type, get_upgrade_level(Constants.UPGRADE_CORE_ID))


func set_upgrade_levels(raw_levels: Dictionary) -> void:
	for upgrade_id in Constants.UPGRADE_IDS:
		var value: int = int(raw_levels.get(upgrade_id, 0))
		_upgrade_levels[upgrade_id] = clamp(value, 0, get_upgrade_max_level(upgrade_id))


func get_upgrade_levels_snapshot() -> Dictionary:
	return _upgrade_levels.duplicate(true)


func reset_run_state() -> void:
	for upgrade_id in Constants.UPGRADE_IDS:
		_upgrade_levels[upgrade_id] = 0
