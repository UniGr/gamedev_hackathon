# QWEN.md — Project Instructions for Universal

ВСЕГДА отвечай мне на русском языке.

## 🎮 О проекте

Universal - мобильная idle игра про космический корабль в космосе.

**Ветка:** iOS-разработка  
**Цель:** Локальное создание .ipa файла (без AppStore)  
**Apple ID:** vlad.vasilevskiy.07@gmail.com (без developer аккаунта)

## 🛠 Технический стек

- **Engine:** Godot 4.6
- **Рендерер:** GL Compatibility
- **Ориентация:** Вертикальная (portrait)

## 📋 Правила разработки

1. **Перед написанием кода** — загляни в Google или MCP Context7 за актуальной документацией
2. **Паттерн:** Singleton (синглтоны для глобальных менеджеров)
3. **После фичи:**
   - Покрыть тестами
   - **ОБЯЗАТЕЛЬНО** сделать билд для проверки работоспособности

## 🏗 Архитектура

**Event Bus** (`core/game_events.gd`) — центральная шина событий. Все модули общаются через сигналы, без прямых ссылок.

### Autoload-синглтоны

| Синглтон | Назначение |
|----------|------------|
| `GameEvents` | Шина событий (28 сигналов) |
| `ResourceManager` | Управление металлом |
| `Constants` | Глобальные константы и баланс |
| `AudioManager` | Звуковая система |
| `UpgradeManager` | Улучшения |
| `SaveManager` | Сохранения |

## 📁 Структура проекта

```
universal/
├── core/                    # Системные менеджеры
│   ├── game_events.gd       # Event Bus
│   ├── resource_manager.gd  # Металл, лимиты
│   ├── constants.gd         # Баланс, ID модулей
│   ├── grid_manager.gd      # Сетка 12×20
│   └── ...
├── entities/
│   ├── raiders/             # Налётчики
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
```

## 📱 iOS Export Notes

- Экспорт только с macOS
- Xcode обязателен
- Бесплатный Apple ID → только для личного тестирования
- Bundle ID: `com.yourstudio.universal` (или персональный)
