extends CharacterBody2D
## LIN. Jalan 4 arah (keyboard atau tombol sentuh). Origin node = kaki LIN.
##
## Animasi: node Sprite (AnimatedSprite2D) punya animasi "idle_<arah>" dan "walk_<arah>"
## (arah = down / up / left / right). Gambar LIN baru ada tampak depan, jadi keempat arah
## sementara memakai frame yang sama (kaki kiri/kanan bergantian). Kalau nanti kamu punya
## gambar tampak belakang atau samping, ganti frame-nya di panel SpriteFrames pada node
## Sprite tanpa mengubah kode.
## Suara langkah = node Footsteps; diputar selama LIN berjalan.

@export var speed := 110.0
@export var can_move := true
## Area jalan (Area2D berisi CollisionShape2D persegi). Kaki LIN harus di dalamnya.
@export var walk_areas: Node
## Area terlarang (mis. panel biru di tengah map). Boleh kosong.
@export var blocked_areas: Node
## Setengah lebar kaki untuk cek tabrakan (piksel).
@export var foot_half_width := 8.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var footsteps: AudioStreamPlayer = $Footsteps

var facing := "down"


func _ready() -> void:
	footsteps.finished.connect(_on_footsteps_finished)


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if can_move:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var moved := false
	if dir != Vector2.ZERO:
		var step := dir * speed * delta
		var before := global_position
		_try_move(Vector2(step.x, 0.0))
		_try_move(Vector2(0.0, step.y))
		moved = global_position != before
		if absf(dir.x) > absf(dir.y):
			facing = "right" if dir.x > 0.0 else "left"
		else:
			facing = "down" if dir.y > 0.0 else "up"
	_animate(moved)
	_update_footsteps(moved)


func _try_move(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	var target := global_position + offset
	if _walkable(target):
		global_position = target


## Tiga titik di kaki (kiri, tengah, kanan) harus di area jalan dan di luar area terlarang.
func _walkable(p: Vector2) -> bool:
	for dx in [-foot_half_width, 0.0, foot_half_width]:
		var q := p + Vector2(dx, 0.0)
		if blocked_areas and _inside(blocked_areas, q):
			return false
		if walk_areas and not _inside(walk_areas, q):
			return false
	return true


func _inside(zone: Node, p: Vector2) -> bool:
	for c in zone.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var size: Vector2 = c.shape.size * c.global_scale
			if Rect2(c.global_position - size * 0.5, size).has_point(p):
				return true
	return false


func _animate(moving: bool) -> void:
	var anim := ("walk_" if moving else "idle_") + facing
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation == anim:
		return
	var was_walking := sprite.animation.begins_with("walk_")
	var keep_frame := sprite.frame
	sprite.play(anim)
	if moving and was_walking:
		# ganti arah saat berjalan: lanjutkan langkah, jangan mulai dari awal
		sprite.set_frame_and_progress(keep_frame, 0.0)


func _update_footsteps(moving: bool) -> void:
	if moving:
		if not footsteps.playing:
			footsteps.play()
	elif footsteps.playing:
		footsteps.stop()


func _on_footsteps_finished() -> void:
	pass   # diputar ulang otomatis di _update_footsteps selama masih berjalan
