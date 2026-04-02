extends RefCounted
class_name AudioCatalog
## Единый каталог аудио-тегов и их метаданных.
## Новые звуки/музыку добавляем сюда, чтобы не разносить пути по проекту.

enum AudioClass {
	MUSIC,
	SFX_UI,
	SFX_GAMEPLAY,
	SFX_COMBAT,
	SFX_SYSTEM,
}

const TAG_MUSIC_BGM_MAIN: String = "music.bgm.main"
const TAG_MUSIC_ENGINE_LOOP: String = "music.engine.loop"

const TAG_UI_OPEN: String = "ui.open"

const TAG_GAMEPLAY_BUILD_PLACE: String = "gameplay.build.place"
const TAG_GAMEPLAY_COIN: String = "gameplay.coin"
const TAG_GAMEPLAY_COLLECTOR_GATHER: String = "gameplay.collector.gather"
const TAG_GAMEPLAY_TURRET_SHOT: String = "gameplay.turret.shot"

const TAG_COMBAT_MODULE_HIT: String = "combat.module.hit"
const TAG_COMBAT_MODULE_DESTROY: String = "combat.module.destroy"
const TAG_COMBAT_RAIDER_BITE: String = "combat.raider.bite"
const TAG_COMBAT_RAIDER_DAMAGE: String = "combat.raider.damage"
const TAG_COMBAT_RAIDER_DESTROY: String = "combat.raider.destroy"

const TAG_SYSTEM_WIN: String = "system.win"
const TAG_SYSTEM_LOSE: String = "system.lose"

const ENTRIES: Dictionary = {
	TAG_MUSIC_BGM_MAIN: {
		"path": "res://assets/audio/music/Glass_Orbiting.mp3",
		"audio_class": AudioClass.MUSIC,
		"base_db": -18.0,
		"loop": true,
	},
	TAG_MUSIC_ENGINE_LOOP: {
		"path": "res://assets/audio/dima_sfx/engine.mp3",
		"audio_class": AudioClass.MUSIC,
		"base_db": -30.0,
		"loop": true,
	},
	TAG_UI_OPEN: {
		"path": "res://assets/audio/game_sfx/ui_open.wav",
		"audio_class": AudioClass.SFX_UI,
		"base_db": -8.0,
		"loop": false,
	},
	TAG_GAMEPLAY_BUILD_PLACE: {
		"path": "res://assets/audio/dima_sfx/build_place_dima.wav",
		"audio_class": AudioClass.SFX_GAMEPLAY,
		"base_db": -8.0,
		"loop": false,
	},
	TAG_GAMEPLAY_COIN: {
		"path": "res://assets/audio/game_sfx/pick_up.mp3",
		"audio_class": AudioClass.SFX_GAMEPLAY,
		"base_db": -1.0,
		"loop": false,
	},
	TAG_GAMEPLAY_COLLECTOR_GATHER: {
		"path": "res://assets/audio/dima_sfx/sbor.mp3",
		"audio_class": AudioClass.SFX_GAMEPLAY,
		"base_db": -16.0,
		"loop": false,
	},
	TAG_GAMEPLAY_TURRET_SHOT: {
		"path": "res://assets/audio/game_sfx/turret_shot.mp3",
		"audio_class": AudioClass.SFX_GAMEPLAY,
		"base_db": -10.0,
		"loop": false,
	},
	TAG_COMBAT_MODULE_HIT: {
		"path": "res://assets/audio/game_sfx/module_hit.wav",
		"audio_class": AudioClass.SFX_COMBAT,
		"base_db": -10.0,
		"loop": false,
	},
	TAG_COMBAT_MODULE_DESTROY: {
		"path": "res://assets/audio/game_sfx/module_destroy.wav",
		"audio_class": AudioClass.SFX_COMBAT,
		"base_db": -8.0,
		"loop": false,
	},
	TAG_COMBAT_RAIDER_BITE: {
		"path": "res://assets/audio/dima_sfx/raider_bite_dima.wav",
		"audio_class": AudioClass.SFX_COMBAT,
		"base_db": -9.0,
		"loop": false,
	},
	TAG_COMBAT_RAIDER_DAMAGE: {
		"path": "res://assets/audio/dima_sfx/testovy_damag.mp3",
		"audio_class": AudioClass.SFX_COMBAT,
		"base_db": -8.0,
		"loop": false,
	},
	TAG_COMBAT_RAIDER_DESTROY: {
		"path": "res://assets/audio/dima_sfx/enemy_death_dima1.wav",
		"audio_class": AudioClass.SFX_COMBAT,
		"base_db": -2.0,
		"loop": false,
	},
	TAG_SYSTEM_WIN: {
		"path": "res://assets/audio/game_sfx/win.wav",
		"audio_class": AudioClass.SFX_SYSTEM,
		"base_db": -8.0,
		"loop": false,
	},
	TAG_SYSTEM_LOSE: {
		"path": "res://assets/audio/game_sfx/lose.wav",
		"audio_class": AudioClass.SFX_SYSTEM,
		"base_db": -8.0,
		"loop": false,
	},
}


static func has_tag(tag: String) -> bool:
	return ENTRIES.has(tag)


static func get_entry(tag: String) -> Dictionary:
	if not ENTRIES.has(tag):
		return {}
	return (ENTRIES[tag] as Dictionary).duplicate(true)


static func get_stream_path(tag: String) -> String:
	var entry: Dictionary = get_entry(tag)
	return str(entry.get("path", ""))


static func is_looped(tag: String) -> bool:
	var entry: Dictionary = get_entry(tag)
	return bool(entry.get("loop", false))


static func get_audio_class(tag: String) -> AudioClass:
	var entry: Dictionary = get_entry(tag)
	return int(entry.get("audio_class", AudioClass.SFX_SYSTEM)) as AudioClass


static func get_base_db(tag: String) -> float:
	var entry: Dictionary = get_entry(tag)
	return float(entry.get("base_db", -8.0))
