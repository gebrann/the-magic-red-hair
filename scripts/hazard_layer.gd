extends Node2D
## Lapisan gambar serangan Reyon. Isi gambarnya diurus battle.gd (draw_hazards).


func _draw() -> void:
	var battle := owner
	if battle and battle.has_method("draw_hazards"):
		battle.draw_hazards(self)
