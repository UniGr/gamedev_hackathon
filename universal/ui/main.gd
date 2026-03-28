extends Node2D

@onready var tutorial_window: Node = null

func _enter_tree() -> void:
	_reset_game_state_at_scene_start()


func _ready() -> void:

	print("Main._ready() running. children: ", get_child_count())
	for c in get_children():
		print(" - child: ", c.name, " type=", c.get_class())

	#пытаемся найти окно обучения локально и через несколько возможных путей
	if has_node("TutorialWindow"):
		tutorial_window = get_node("TutorialWindow")
	elif has_node("../TutorialWindow"):
		tutorial_window = get_node("../TutorialWindow")
	elif has_node("/root/Main/TutorialWindow"):
		tutorial_window = get_node("/root/Main/TutorialWindow")
	else:
		print("TutorialWindow not found by direct/relative/global path")

	if tutorial_window != null:
		print("Found tutorial_window: ", tutorial_window.name, " -> ", tutorial_window.get_path())
		if tutorial_window.has_method("start_tutorial"):
			print("Calling tutorial_window.start_tutorial()")
			tutorial_window.start_tutorial()
		else:
			print("tutorial_window exists but has no method start_tutorial")
	else:
		print("tutorial_window is null")


func _reset_game_state_at_scene_start() -> void:
	# Единая точка сброса ранa: при каждом входе в игровую сцену.
	ResourceManager.reset_run_state()
	UpgradeManager.reset_run_state()
	# Флаги туториалов НЕ очищаются! Они нужны для того, чтобы Надя
	# не запускалась повторно при перезагрузке приложения.
	
	var tree := get_tree()
	if tree != null:
		tree.paused = false
