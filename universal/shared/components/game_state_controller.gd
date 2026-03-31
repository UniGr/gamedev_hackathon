extends Node
class_name GameStateController
## Управление состоянием игры: победа, поражение, флаги.
## Отделено от GameBoard для соблюдения SRP.

signal game_won(reason: String)
signal game_lost(reason: String)

var _is_game_finished: bool = false
var _placed_modules: Array[ModuleBase] = []
var _core_module: CoreModule


func is_game_finished() -> bool:
	return _is_game_finished


func set_modules_reference(modules: Array[ModuleBase], core: CoreModule) -> void:
	_placed_modules = modules
	_core_module = core


func check_win_condition() -> void:
	if _is_game_finished:
		return

	var result: Dictionary = GameConditionChecker.check_win(_placed_modules, _is_game_finished)
	if result.get("won", false):
		_finish_game_win(result.get("reason", ""))


func handle_core_destroyed(source: String) -> void:
	if _is_game_finished:
		return

	var reason: String = "core_destroyed"
	if source == "raider":
		reason = "core_eaten_by_raiders"
	_finish_game_lose(reason)


func _finish_game_win(reason: String) -> void:
	if _is_game_finished:
		return
	_is_game_finished = true
	game_won.emit(reason)
	GameEvents.game_finished.emit("win", reason)
	GameEvents.game_ended.emit()


func _finish_game_lose(reason: String) -> void:
	if _is_game_finished:
		return
	_is_game_finished = true
	game_lost.emit(reason)
	GameEvents.game_finished.emit("lose", reason)
	GameEvents.game_ended.emit()
