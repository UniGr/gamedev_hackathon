# AGENTS.MD

ВСЕГДА отвечай мне на русском языке.

Universal - мобильная idle игра про космический корабль в космосе.

В этой ветке идет разработка только iOS версии. Мы не делаем это для выгрузки в AppStore, только локальное создание .ipa файла.
У меня нет apple developer аккаунт, только обычный аккаунт vlad.vasilevskiy.07@gmail.com

Стек:
Godot 4.6, рендерер: GL Compatibility

Ориентация: вертикальная

Перед написанием кода обязательно загляни в google или в mcp context7 чтобы получить актуальную документацию по техническому стеку.

Патерн написания кода: singltone.

После написания фичи обязательно покрывай её тестами и ОБЯЗАТЕЛЬНО делай билд, чтобы проверить работоспособность.

🏗 Архитектура
Event Bus (core/game_events.gd) — центральная шина событий. Все модули общаются через сигналы, без прямых ссылок.

Ключевые autoload-синглтоны:

Синглтон	Назначение
GameEvents	Шина событий
ResourceManager	Управление металлом
Constants	Глобальные константы и баланс
AudioManager	Звуковая система
UpgradeManager	Улучшения
SaveManager	Сохранения


📁 Структура проекта
universal/
├── core/                    # Системные менеджеры
│   ├── game_events.gd       # Event Bus (28 сигналов)
│   ├── resource_manager.gd  # Металл, лимиты
│   ├── constants.gd         # Баланс, ID модулей
│   ├── grid_manager.gd      # Сетка 12×20
│   └── ...
├── entities/
│   ├── raiders/             # ✅ Налётчики
│   │   ├── raider.gd
│   │   ├── raider_spawner.gd
│   │   └── raider.tscn
│   ├── modules/             # Модули корабля
│   │   ├── core_module.gd
│   │   ├── collector_module.gd
│   │   ├── reactor_module.gd
│   │   ├── hull_module.gd
│   │   └── turret_module.gd
│   ├── debris/              # Мусор для сбора
│   ├── effects/             # VFX/SFX
│   └── ship/                # ShipGrid, ShipSway
├── ui/                      # HUD, меню, туториалы
├── shared/components/       # Переиспользуемые компоненты
└── data/room_stats/         # .tres конфиги баланса
