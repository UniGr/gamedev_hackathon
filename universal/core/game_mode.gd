extends Node
## Autoload: GameMode
## Хранит выбранный режим игры (обычный / бесконечный) и ведёт счёт бесконечного режима.
## Счёт = текущий размер корабля (число модулей). Рекорд = максимальный размер за всё время,
## сохраняется локально между запусками в user://endless_record.json.
##
## Изолированный модуль: остальные системы общаются с ним только через публичный API и сигналы.

signal score_changed(current_score: int, best_score: int)

## Бесконечный режим разблокирован (обычный режим пройден впервые).
signal endless_unlocked

enum Mode {
	NORMAL = 0,
	ENDLESS = 1,
}

const RECORD_PATH: String = "user://endless_record.json"

var current_mode: int = Mode.NORMAL

var _current_score: int = 0
var _best_score: int = 0
var _module_count: int = 0
## Игрок хотя бы раз прошёл обычный режим — открывает доступ к бесконечному.
var _normal_completed: bool = false


func _ready() -> void:
	# Должен работать даже на паузе, чтобы успевать реагировать на постройку/снос.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_record()
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.module_destroyed.connect(_on_module_destroyed)
	GameEvents.game_finished.connect(_on_game_finished)


# ========== Публичный API ==========

func set_mode(mode: int) -> void:
	current_mode = mode


func is_endless() -> bool:
	return current_mode == Mode.ENDLESS


## Доступен ли бесконечный режим (обычный режим пройден хотя бы раз).
func is_endless_unlocked() -> bool:
	return _normal_completed


func get_current_score() -> int:
	return _current_score


func get_best_score() -> int:
	return _best_score


## Сбрасывает счёт текущего захода. Вызывается при входе в игровую сцену.
func reset_run() -> void:
	_module_count = 0
	_update_score()


# ========== Подсчёт счёта ==========

func _on_module_built(_module_type: String, _position: Vector2) -> void:
	_module_count += 1
	_update_score()


func _on_module_destroyed(_module_type: String, _position: Vector2) -> void:
	_module_count = max(0, _module_count - 1)
	_update_score()


# ========== Разблокировка бесконечного режима ==========

func _on_game_finished(outcome: String, _reason: String) -> void:
	# Бесконечный режим открывается после первой победы в обычном режиме.
	if outcome != "win" or current_mode != Mode.NORMAL or _normal_completed:
		return
	_normal_completed = true
	_save_record()
	endless_unlocked.emit()


func _update_score() -> void:
	# Размер корабля включает ядро (которое не эмитит module_built).
	_current_score = _module_count + 1
	if is_endless() and _current_score > _best_score:
		_best_score = _current_score
		_save_record()
	score_changed.emit(_current_score, _best_score)


# ========== Сохранение рекорда ==========

func _load_record() -> void:
	if not FileAccess.file_exists(RECORD_PATH):
		return
	var file: FileAccess = FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		_best_score = int(data.get("best_score", 0))
		_normal_completed = bool(data.get("normal_completed", false))


func _save_record() -> void:
	var file: FileAccess = FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"best_score": _best_score,
			"normal_completed": _normal_completed,
		}))
