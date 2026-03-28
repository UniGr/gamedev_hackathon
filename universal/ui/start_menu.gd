extends Control

@onready var btn_start: Button = %BtnStart
@onready var btn_quit: Button = %BtnQuit
@onready var title: Label = %Title
@onready var buttons_container: VBoxContainer = %ButtonsContainer

func _ready() -> void:
	print("--- МЕНЮ ЗАПУЩЕНО ---")
	
	# Сбросим прозрачность для надежности, если анимация глючит
	title.modulate.a = 1.0
	buttons_container.modulate.a = 1.0
	
	# Проверка нажатий
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	# Добавим визуальный отклик на наведение
	btn_start.mouse_entered.connect(func(): print("Мышь на кнопке ИГРАТЬ"))
	btn_quit.mouse_entered.connect(func(): print("Мышь на кнопке ВЫХОД"))

func _on_btn_start_pressed() -> void:
	print("--- НАЖАТА КНОПКА ИГРАТЬ ---")
	var path = "res://main.tscn"
	if ResourceLoader.exists(path):
		var error = get_tree().change_scene_to_file(path)
		if error != OK:
			print("ОШИБКА: Код ошибки при смене сцены: ", error)
	else:
		print("ОШИБКА: Файл main.tscn не найден по пути ", path)

func _on_btn_quit_pressed() -> void:
	print("--- НАЖАТА КНОПКА ВЫХОД ---")
	get_tree().quit()
