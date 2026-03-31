extends RefCounted
class_name ShopStateController

var _shop_open: bool = false


func is_shop_open() -> bool:
	return _shop_open


func set_shop_open(value: bool, sync_pause: bool, shop_overlay: ColorRect) -> void:
	_shop_open = value
	if shop_overlay != null:
		shop_overlay.visible = value

	if sync_pause:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.paused = value

	if value:
		GameEvents.shop_opened.emit()
	else:
		GameEvents.shop_closed.emit()
