extends Control
## Layar WIN setelah Skeleton dikalahkan (atau diampuni): game tamat, lalu kembali ke menu utama.
## Sentuh layar / tekan interact untuk kembali sekarang, atau tunggu `auto_return_delay` detik.

@export var auto_return_delay := 8.0

var t := 0.0
var leaving := false


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.0)
	# kemajuan tersimpan: CONTINUE membawa LIN ke library (Skeleton sudah tidak ada)
	Game.skeleton_defeated = true
	Game.enemy_type = "reyon"
	Game.library_pos_saved = false
	Game.save_game("res://scenes/library.tscn")
	$TapArea.pressed.connect(_try_back)


func _process(delta: float) -> void:
	if leaving:
		return
	t += delta
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel") or t >= auto_return_delay:
		_try_back()


func _try_back() -> void:
	if leaving or t < 1.0:      # jeda 1 detik supaya tidak terlewat oleh tombol terakhir di battle
		return
	leaving = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
