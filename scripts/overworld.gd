extends Node2D
## Dark Garden. Begitu LIN mendekati Reyon, dialog muncul sendiri lalu pertarungan mulai.
## Semua objek (map, area jalan, LIN, Reyon, dialog, tombol sentuh) adalah node di
## scenes/overworld.tscn dan bisa digeser/diubah lewat editor.

## Jeda (detik) setelah teks dialog selesai sebelum pertarungan mulai otomatis.
@export var auto_start_delay := 1.2
@export var typing_speed := 25.0

@onready var player: CharacterBody2D = $Player
@onready var dialog_box: Control = $DialogLayer/DialogBox
@onready var dialog_text: RichTextLabel = $DialogLayer/DialogBox/Text
@onready var library_door: Area2D = $LibraryDoor

var reyon = null
var talking := false
var leaving := false
var typing := 0.0
var done_timer := 0.0


func _ready() -> void:
	dialog_box.visible = false
	Game.save_game("res://scenes/overworld.tscn")
	if Game.lin_saved:
		player.global_position = Game.lin_pos
	library_door.body_entered.connect(_on_library_door)
	reyon = get_node_or_null("Reyon")
	if reyon != null:
		if Game.reyon_defeated:
			reyon.queue_free()       # sudah kalah -> hilang dari map
			reyon = null
		else:
			reyon.player_near.connect(_on_reyon_near)


func _on_reyon_near() -> void:
	if talking:
		return
	talking = true
	player.can_move = false
	Game.lin_pos = player.global_position
	Game.lin_saved = true
	dialog_text.text = reyon.talk_text
	dialog_text.visible_characters = 0
	dialog_box.visible = true


func _process(delta: float) -> void:
	if not talking or leaving:
		return
	var total := dialog_text.get_total_character_count()
	typing += delta * typing_speed
	dialog_text.visible_characters = int(typing)
	if typing >= total:
		done_timer += delta
	if Input.is_action_just_pressed("interact"):
		if typing < total:
			typing = float(total) + 1.0
		else:
			_start_battle()
	elif typing >= total and done_timer >= auto_start_delay:
		_start_battle()


func _start_battle() -> void:
	leaving = true
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


## Jalan atas menuju perpustakaan: hanya bisa dimasuki setelah Reyon kalah.
func _on_library_door(body: Node) -> void:
	if leaving or not Game.reyon_defeated or not body.is_in_group("player"):
		return
	leaving = true
	Game.library_pos_saved = false
	get_tree().change_scene_to_file("res://scenes/library.tscn")
