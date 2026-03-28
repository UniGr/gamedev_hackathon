extends Control

@onready var btn_start: Button = %BtnStart
@onready var btn_quit: Button = %BtnQuit

func _ready() -> void:
	print("--- МЕНЮ ЗАПУЩЕНО ВЕРСИЯ 3 ---")
	
	# Принудительно включаем кнопки
	btn_start.disabled = false
	btn_start.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_quit.disabled = false
	btn_quit.mouse_filter = Control.MOUSE_FILTER_STOP
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)

func _on_btn_start_pressed() -> void:
	print(">>> НАЖАТА КНОПКА ИГРАТЬ <<<")
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_quit_pressed() -> void:
	print(">>> НАЖАТА КНОПКА ВЫХОД <<<")
	get_tree().quit()
