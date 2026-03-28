extends CanvasLayer

@onready var btn_start: Button = %BtnStart

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	
	# Привязываем сигнал
	btn_start.pressed.connect(_on_btn_start_pressed)
	
	# На случай, если клики не работают на Mac, авто-запуск через 5 сек
	print("Ожидание 5 секунд до автоматического старта...")
	await get_tree().create_timer(5.0).timeout
	if get_tree().current_scene == self:
		print("Автоматический запуск игры...")
		_on_btn_start_pressed()

func _on_btn_start_pressed() -> void:
	print("--- СМЕНА СЦЕНЫ НА res://main.tscn ---")
	get_tree().change_scene_to_file("res://main.tscn")
