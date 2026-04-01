extends Node2D
## Корневой скрипт игровой сцены.
## Отвечает за инициализацию состояния игры и запуск туториала.

@onready var tutorial_window: Node = null


func _enter_tree() -> void:
	_reset_game_state_at_scene_start()


func _ready() -> void:
	_find_and_start_tutorial()


func _find_and_start_tutorial() -> void:
	# Пытаемся найти окно обучения по нескольким путям
	if has_node("TutorialWindow"):
		tutorial_window = get_node("TutorialWindow")
	elif has_node("../TutorialWindow"):
		tutorial_window = get_node("../TutorialWindow")
	elif has_node("/root/Main/TutorialWindow"):
		tutorial_window = get_node("/root/Main/TutorialWindow")

	if tutorial_window != null and tutorial_window.has_method("start_tutorial"):
		tutorial_window.start_tutorial()


func _reset_game_state_at_scene_start() -> void:
	# Единая точка сброса рана: при каждом входе в игровую сцену.
	ResourceManager.reset_run_state()
	UpgradeManager.reset_run_state()
	# Флаги туториалов НЕ очищаются — нужны для предотвращения повторного запуска.
	
	var tree := get_tree()
	if tree != null:
		tree.paused = false
