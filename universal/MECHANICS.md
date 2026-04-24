# 🎮 Механики и Ключевые Концепции — Universal (Idle Clicker)

Этот документ описывает основные игровые механики и архитектурные концепции, заложенные в структуре проекта.

---

## 🏗 Архитектурные Столпы

### 1. Event Bus (Сигнальная Шина)
**Файл:** `res://core/game_events.gd`

Все модули общаются исключительно через сигналы и не держат прямых ссылок друг на друга.

**Главный принцип:** если сборщик собрал мусор, он не обновляет UI напрямую. Вместо этого:

```gdscript
GameEvents.garbage_clicked.emit(amount)
```

`ResourceManager` слушает этот сигнал:

```gdscript
GameEvents.garbage_clicked.connect(_on_garbage_clicked)
```

**Основные сигналы:**
- `garbage_clicked(amount: int)` — игрок тапнул по мусору.
- `resource_changed(type: String, new_total: int)` — обновление баланса.
- `build_requested(module_type: String, position: Vector2)` — запрос постройки.
- `module_built(module_type: String, position: Vector2)` — модуль построен.
- `module_destroyed(module_type: String, position: Vector2)` — модуль уничтожен.
- `game_started` / `game_ended` — события старта и завершения игры.


### 2. Feature-Based Folders
Ресурсы одной фичи (сцена, скрипт, спрайты) находятся в одной папке:

### 3. Composition Over Inheritance
Вместо глубокой иерархии классов функционал собирается из компонентов в `shared/`:
- `HealthComponent` — защита модуля.
- `ClickableComponent` — интерактивность.
- `ResourceGeneratorComponent` — добыча ресурсов.

---

## 🎯 Главные Игровые Механики

### 1. Ресурсная Система
**Менеджер:** `res://core/resource_manager.gd`


**Интеграция с Event Bus:**

```gdscript
GameEvents.resource_changed.emit("metal", new_metal)
```

### 2. Сбор Мусора (Garbage Collection)
**Папка:** `entities/debris/`

Игрок тапает по мусору и получает металл.

**Flow:**
1. Спавнер создает мусор в зоне над видимой областью, после чего объекты движутся вниз и входят в кадр.
2. Игрок тапает по мусору -> `GameEvents.garbage_clicked.emit(10)`.
3. `ResourceManager` добавляет металл -> `resource_changed.emit("metal", ...)`.
4. UI обновляет счетчик.

Дополнительная механика: игрок может несколько раз тапнуть по врагу, уничтожить его и собрать разлетевшийся мусор.

### 3. Сетка Корабля и Модули
**Папка:** `entities/ship/`

Корабль представляет собой сетку **12 x 20 ячеек** (размер ячейки 90 x 90 пикселей, вертикальная ориентация).

**Стартовая конфигурация (MVP):**
- **Ядро** — 2x1 ячейки (центр энергии).
- **Корпус** — 1x1 ячейка (хранилище).
- **Туррель** — 1x1 ячейка (боевая).
- **Сборщик (Collector)** — 1x1 ячейка (сбор ресурсов).
- **Реактор** — 1x1 ячейка (источник энергии).

**Типы модулей** (из `entities/modules/`):

```gdscript
enum ModuleType {
	RESOURCE = 0,
	COMBAT = 1,
	STORAGE = 2,
}
```

### 4. Постройка и Разрушение Модулей
**Flow постройки:**

```text
UI нажимает кнопку "Построить"
		↓
build_requested.emit(module_type, position)
		↓
ShipGrid проверяет место и ресурсы
		↓
module_built.emit(type, position) или build_failed
		↓
ResourceManager тратит ресурсы
		↓
UI обновляется
```

**Flow разборки:**

```text
UI нажимает кнопку "Разобрать"
		↓
destroy_requested.emit(module_type, position)
		↓
module_destroyed.emit(type, position)
		↓
ResourceManager возвращает часть ресурсов
		↓
UI обновляется
```

### 5. Нападение Врагов
Враги атакуют модули и наносят им урон (снимают HP).

Если врага не уничтожить вовремя, модуль разрушается без возврата ресурсов.

### 6. Столкновения и Оборона
Столкновение — это один из способов тормозить развитие игрока и противодействовать его жадности.

> Правило: при введении новых типов столкновений предварительно добавляйте соответствующий сигнал в `res://core/game_events.gd` и реализуйте обработку в `ResourceManager`/`ShipGrid`.
---


## 📊 Данные и Баланс

Параметры (стоимость, добыча, скорость, прочность) выносятся в `.tres` файлы в `res://data/`.

**Пример:** `res://data/room_stats/resource_module.tres`

```text
[resource]
script_class = "ModuleStats"
price_metal = 50
production_rate = 10
max_energy = 100
```

**Преимущества:**
- Баланс можно менять без правки скриптов.
- Меньше конфликтов в Git.
- Данные отделены от логики.

---

## 🎮 UI/UX Структура

**Ориентация:** вертикальная.

**Текущее направление изменений:**
- Основные кнопки располагаются снизу.
- Корабль фиксируется у нижней границы экрана.
- В режиме строительства подсвечиваются доступные ячейки.
- Постройка происходит не мгновенно: сначала отображается прогресс-бар, затем появляется модуль.




---

## 📁 Справочник Структуры

```text
res://
├── assets/                  # Спрайты, звуки, шрифты
├── core/
│   ├── game_events.gd       # Event Bus
│   ├── resource_manager.gd  # Управление ресурсами
│   └── constants.gd         # ID и константы
├── data/
│   └── room_stats/          # Параметры модулей (.tres)
├── entities/
│   ├── ship/                # Сетка корабля
│   ├── modules/             # Виды модулей
│   └── debris/              # Мусор
├── ui/                      # Интерфейс
├── shared/                  # Компоненты
└── main.tscn                # Главная сцена
```

---

## 🚀 Жизненный Цикл Игры

1. **Инициализация**
- Загружается `main.tscn`.
- Инициализируются Autoload-синглтоны (`GameEvents`, `ResourceManager`, `Constants`).
- Отправляется `GameEvents.game_started.emit()`.

2. **Игровой цикл**
- Игрок собирает мусор (`garbage_clicked`).
- Игрок строит/разбирает модули (`build_requested`, `module_destroyed`).
- Враги атакуют модули, игрок защищает корабль.
- UI обновляется по `resource_changed` и другим сигналам.

3. **Финал**
- Игрок накапливает достаточную мощность и энергию.
- Отправляется `game_ended.emit()`.
- Выполняется финальный гиперпрыжок.

---

## 💡 Практические Рекомендации

### Делай

```gdscript
GameEvents.resource_changed.emit("metal", new_amount)
var health: int = 100
@export var damage: int = 10
```

### Не Делай

```gdscript
get_node("/root/Main/UI").update_score()
var price = 50
```

---