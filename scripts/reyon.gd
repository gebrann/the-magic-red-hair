extends Area2D
## Reyon (Frankenstein) di Dark Garden. Origin node = kaki Reyon.
## Node TriggerZone = area pemicu: begitu LIN masuk, dialog lalu pertarungan dimulai.
## Pertarungan hanya sekali: kalau Reyon sudah kalah, node ini langsung dihapus.

signal player_near

@export_multiline var talk_text := "[color=white]who are you? You have to left now[/color][color=red]!!!![/color]"
@export var idle_bob := 3.0

@onready var sprite: Sprite2D = $Sprite

var base_y := 0.0
var t := 0.0


func _ready() -> void:
	base_y = sprite.position.y
	if Game.reyon_defeated:
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = base_y + sin(t * 2.0) * idle_bob


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		set_deferred("monitoring", false)   # pemicu sekali saja
		player_near.emit()
