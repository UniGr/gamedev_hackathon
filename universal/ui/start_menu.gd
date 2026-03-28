extends CanvasLayer

@onready var btn_start: Button = %BtnStart

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	
	if btn_start:
		btn_start.pressed.connect(_on_btn_start_pressed)
	else:
		push_error("Кнопка BtnStart не найдена!")
	
	# Авто-запуск через 5 сек для тестов
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self) and get_tree().current_scene == self:
		print("Автоматический запуск игры...")
		_on_btn_start_pressed()

func _on_btn_start_pressed() -> void:
	var path1 = "res://main.tscn"
	var path2 = "res://universal/main.tscn"
	
	if FileAccess.file_exists(path1):
		print("Загрузка: ", path1)
		get_tree().change_scene_to_file(path1)
	elif FileAccess.file_exists(path2):
		print("Загрузка: ", path2)
		get_tree().change_scene_to_file(path2)
	else:
		push_error("Не удалось найти main.tscn ни по одному из путей!")
