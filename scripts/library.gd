extends Node2D
## Perpustakaan. LIN masuk dari Dark Garden (jalan atas, setelah Reyon kalah).
## Dekati benda "interactable" lalu tekan interact / A untuk membacanya.
## Keluar lewat bagian bawah ruangan (node Exit) kembali ke Dark Garden.

@export var typing_speed := 10.0

@onready var player: CharacterBody2D = $Player
@onready var exit_zone: Area2D = $Exit
@onready var dialog_box: Control = $DialogLayer/DialogBox
@onready var dialog_text: RichTextLabel = $DialogLayer/DialogBox/Text
@onready var prompt: Label = $DialogLayer/Prompt

var reading := false
var leaving := false
var typing := 0.0


func _ready() -> void:
	dialog_box.visible = false
	if Game.library_pos_saved:
		player.global_position = Game.library_pos    # kembali dari battle Skeleton
	Game.save_game("res://scenes/library.tscn")
	if Game.skeleton_defeated:
		var skeleton_node := get_node_or_null("SkeletonEncounter")
		if skeleton_node:
			skeleton_node.queue_free()
	prompt.visible = false
	exit_zone.body_entered.connect(_on_exit_entered)


func _on_exit_entered(body: Node) -> void:
	if leaving or not body.is_in_group("player"):
		return
	leaving = true
	Game.library_pos_saved = false
	# kembali ke jalan atas Dark Garden, tepat di bawah pintu perpustakaan
	Game.lin_pos = Vector2(472, 70)
	Game.lin_saved = true
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")


func _process(delta: float) -> void:
	if reading:
		typing += delta * typing_speed
		dialog_text.visible_characters = int(typing)
		if Input.is_action_just_pressed("interact"):
			if typing < dialog_text.get_total_character_count():
				typing = 9999.0
			else:
				_close()
		return
	var target = _find_interactable()
	prompt.visible = target != null
	if target != null and Input.is_action_just_pressed("interact"):
		if target.name == "SkeletonEncounter":
			Game.enemy_type = "skeleton"
			Game.library_pos = player.global_position
			Game.library_pos_saved = true
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
			return
		_open(target)


func _find_interactable():
	for a in get_tree().get_nodes_in_group("interactable"):
		if a.overlaps_body(player):
			return a
	return null


func _open(target) -> void:
	reading = true
	typing = 0.0
	player.can_move = false
	prompt.visible = false
	dialog_text.text = target.text
	dialog_text.visible_characters = 0
	dialog_box.visible = true


func _close() -> void:
	reading = false
	player.can_move = true
	dialog_box.visible = false
