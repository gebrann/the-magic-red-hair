extends Node
## Autoload "Game": data yang dibawa antar-scene, tombol, dan save/continue.

const MAX_HP := 20
const SAVE_PATH := "user://save.cfg"
const SAVEABLE_SCENES := ["res://scenes/overworld.tscn", "res://scenes/library.tscn"]

var hp: int = MAX_HP
var reyon_defeated: bool = false      # true = Reyon sudah kalah, hilang dari map
var skeleton_defeated: bool = false   # true = Skeleton di library sudah kalah
var enemy_type := "reyon"             # musuh pada pertarungan berikutnya
var lin_pos := Vector2.ZERO           # posisi LIN di Dark Garden (dipakai setelah battle / dari library)
var lin_saved := false
var library_pos := Vector2.ZERO       # posisi LIN di library (dipakai setelah battle Skeleton)
var library_pos_saved := false


func _ready() -> void:
	_add_action("move_up", [KEY_UP, KEY_W])
	_add_action("move_down", [KEY_DOWN, KEY_S])
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("interact", [KEY_Z, KEY_ENTER, KEY_E])
	_add_action("cancel", [KEY_X, KEY_ESCAPE])


func _add_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action_name, ev)


## Muat gambar dari res://assets kalau ada, kalau tidak kembalikan null.
func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## Dipanggil saat LIN kalah: nyawa penuh lagi. Kemajuan (Reyon/Skeleton kalah) TIDAK ikut direset,
## jadi musuh yang sudah dikalahkan tidak muncul lagi.
func reset() -> void:
	hp = MAX_HP


# ---------- MENU: PLAY / CONTINUE ----------

func new_game() -> void:
	hp = MAX_HP
	reyon_defeated = false
	skeleton_defeated = false
	enemy_type = "reyon"
	lin_pos = Vector2.ZERO
	lin_saved = false
	library_pos = Vector2.ZERO
	library_pos_saved = false
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Simpan otomatis tiap tiba di Dark Garden / library.
func save_game(scene_path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "scene", scene_path)
	cfg.set_value("save", "hp", hp)
	cfg.set_value("save", "reyon_defeated", reyon_defeated)
	cfg.set_value("save", "skeleton_defeated", skeleton_defeated)
	cfg.save(SAVE_PATH)


func continue_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var scene: String = cfg.get_value("save", "scene", SAVEABLE_SCENES[0])
	if not SAVEABLE_SCENES.has(scene):
		scene = SAVEABLE_SCENES[0]
	hp = clampi(int(cfg.get_value("save", "hp", MAX_HP)), 1, MAX_HP)
	reyon_defeated = bool(cfg.get_value("save", "reyon_defeated", false))
	skeleton_defeated = bool(cfg.get_value("save", "skeleton_defeated", false))
	enemy_type = "reyon"
	lin_saved = false
	library_pos_saved = false
	get_tree().change_scene_to_file(scene)
	return true
