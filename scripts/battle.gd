extends Node2D
## Pertarungan gaya Undertale: LIN vs Reyon.
## Tampilan (kotak, menu, HP, tombol, Reyon, jiwa/hati) = node di scenes/battle.tscn
## yang bisa diedit di editor. Script ini hanya mengatur logika.
## Setiap serangan Reyon ditandai putih dulu selama `telegraph_time` detik, baru aktif.

enum S { MENU, ACT_MENU, FIGHT, MESSAGE, ENEMY, LOST }

const BOX_ENEMY := Rect2(170, 235, 300, 130)    # kotak kecil saat giliran Reyon
const BOX_WIDE := Rect2(40, 235, 560, 130)      # kotak lebar saat giliran LIN
const BTN_ICON_X := [0.18, 0.22, 0.195]         # posisi ikon di tiap tombol (untuk hati pemilih)
const LOST_FULL_WIDTH := 35.0                   # lebar isi bar HP (piksel asli gambar)
const LOST_RIGHT_EDGE := 52.0

@export var enemy_max_hp := 25
@export var whip_damage := 8
@export var telegraph_time := 2.0
## Jumlah serangan Reyon tiap gilirannya, dan jeda antar-serangan (detik).
@export var attacks_per_turn := 10
@export var attack_interval := 1.0
@export var soul_speed := 220.0
@export var invuln_time := 1.0
@onready var skeleton_voice: AudioStreamPlayer = $SkeletonVoice

@onready var enemy: Sprite2D = $Stage/Enemy
@onready var enemy_hp_bar: ProgressBar = $Stage/EnemyHPBar
@onready var whip_fx: Node2D = $Stage/WhipFx
@onready var box: Panel = $Stage/Box
@onready var message: RichTextLabel = $Stage/Box/Message
@onready var act_menu: Control = $Stage/Box/ActMenu
@onready var act_labels: Array = [$Stage/Box/ActMenu/Item0, $Stage/Box/ActMenu/Item1]
@onready var fight_bar: Control = $Stage/FightBar
@onready var cursor: ColorRect = $Stage/FightBar/Cursor
@onready var hazard_layer: Node2D = $Stage/Hazards
@onready var soul: Sprite2D = $Stage/Soul
@onready var hp_label: Label = $Stage/Hud/HPLabel
@onready var hp_lost: ColorRect = $Stage/Hud/HPBar/Lost
@onready var menu_btns: Array = [$Stage/Menu/FightBtn, $Stage/Menu/ActBtn, $Stage/Menu/MercyBtn]
@onready var game_over: CanvasLayer = $GameOver

var state: int = S.MENU
var next_state: int = S.MENU
var menu_index := 0
var act_index := 0
var enemy_hp := 25
var talk_count := 0
var won := false

var invuln := 0.0
var shake := 0.0
var enemy_flash := 0.0
var enemy_base := Vector2.ZERO

var msg := "* Reyon block your way!"
var msg_chars := 0.0

var fight_x := 60.0
var whip_t := -1.0

var hazards: Array = []
var enemy_t := 0.0
var enemy_len := 0.0
var last_attack := -1


func _ready() -> void:
	enemy_hp = enemy_max_hp
	if Game.enemy_type == "skeleton":
		enemy.texture = Game.tex("res://assets/skeleton.png")
		enemy.scale = Vector2(0.25, 0.25)
		enemy.position = Vector2(320, 120)
		enemy_max_hp = 50
		enemy_hp = enemy_max_hp
		enemy_hp_bar.max_value = enemy_max_hp
		telegraph_time = 0.35
		attacks_per_turn = 3
		invuln_time = 0.12
		soul_speed = 170.0
		skeleton_voice.play()
		msg = "* Skeleton block your way!"
	else:
		msg = "* Reyon block your way!"
	enemy_base = enemy.position
	enemy_hp_bar.max_value = enemy_max_hp
	game_over.visible = false


func say(text: String, nxt: int) -> void:
	msg = text
	msg_chars = 0.0
	state = S.MESSAGE
	next_state = nxt


func _process(delta: float) -> void:
	msg_chars += delta * 45.0
	invuln = maxf(invuln - delta, 0.0)
	shake = maxf(shake - delta, 0.0)
	enemy_flash = maxf(enemy_flash - delta, 0.0)

	match state:
		S.MENU: _menu_input()
		S.ACT_MENU: _act_input()
		S.FIGHT: _fight(delta)
		S.MESSAGE: _message_input()
		S.ENEMY: _enemy(delta)
		S.LOST:
			if Input.is_action_just_pressed("interact"):
				Game.reset()    # nyawa penuh; Reyon/Skeleton yang sudah kalah tetap kalah
				get_tree().reload_current_scene()
	_refresh(delta)


# ---------- INPUT PER STATE ----------

func _menu_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		menu_index = (menu_index + 2) % 3
	if Input.is_action_just_pressed("move_right"):
		menu_index = (menu_index + 1) % 3
	if Input.is_action_just_pressed("interact"):
		match menu_index:
			0:
				state = S.FIGHT
				fight_x = 60.0
				whip_t = -1.0
			1:
				state = S.ACT_MENU
				act_index = 0
			2:
				_mercy()


func _act_input() -> void:
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		act_index = (act_index + 1) % 2
	if Input.is_action_just_pressed("cancel"):
		state = S.MENU
	elif Input.is_action_just_pressed("interact"):
		var skeleton := Game.enemy_type == "skeleton"
		var enemy_name := "Skeleton" if skeleton else "Reyon"
		if act_index == 0:
			if skeleton:
				say("* SKELETON - ATK 5 DEF 0\n* make of bone and rage.", S.ENEMY)
			else:
				say("* REYON - ATK 5 DEF 0\n* Some kind of thing that a live.", S.ENEMY)
		else:
			talk_count += 1
			if talk_count == 1:
				say("* I just need to get out.\n* %s kinda aware to player." % enemy_name, S.ENEMY)
			else:
				say("* I talk to him %s.\n* she become kinda mercy to player." % enemy_name, S.ENEMY)


func _mercy() -> void:
	if enemy_hp <= enemy_max_hp / 2 or talk_count >= 2:
		won = true
		if Game.enemy_type == "skeleton":
			say("* you choose mercy to Skeleton.\n* he retreat .", S.MENU)
		else:
			say("* you choose mercy for Reyon.\n* Reyon sneak away.", S.MENU)
	else:
		say("* She not surrending .\n* (Try to talk to him with ACT.)", S.ENEMY)


func _fight(delta: float) -> void:
	if whip_t < 0.0:
		fight_x += 420.0 * delta
		if Input.is_action_just_pressed("interact"):
			whip_t = 0.0
		elif fight_x > 580.0:
			say("* your whip got miss.", S.ENEMY)
	else:
		whip_t += delta
		if whip_t >= 0.45:
			whip_t = -1.0
			var center: float = 320.0
			var max_distance: float = 260.0
			var accuracy: float = clampf(1.0 - absf(fight_x - center) / max_distance, 0.0, 1.0)
			var damage: int = maxi(1, roundi(float(whip_damage) * accuracy))

			enemy_hp = maxi(enemy_hp - damage, 0)
			enemy_flash = 1.0
			shake = 0.4

			if enemy_hp <= 0:
				won = true
				if Game.enemy_type == "skeleton":
					say("* He dies become piece of bones.", S.MENU)
				else:
					say("* Reyon can't move anymore .", S.MENU)
			else:
				var enemy_name := "Skeleton" if Game.enemy_type == "skeleton" else "Reyon"
				say("* whip get to him! %s -%d HP." % [enemy_name, damage], S.ENEMY)


func _message_input() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if msg_chars < msg.length():
		msg_chars = 9999.0
		return
	if won:
		if Game.enemy_type == "skeleton":
			# Skeleton kalah / diampuni -> game tamat: layar WIN lalu kembali ke menu utama
			Game.skeleton_defeated = true
			Game.enemy_type = "reyon"
			get_tree().change_scene_to_file("res://scenes/win.tscn")
		else:
			# Reyon kalah / diampuni -> hilang dari map
			Game.reyon_defeated = true
			get_tree().change_scene_to_file("res://scenes/overworld.tscn")
	elif next_state == S.ENEMY:
		_start_enemy()
	else:
		state = next_state
		msg = "* your turns ."
		msg_chars = 0.0


# ---------- GILIRAN MUSUH ----------

func _start_enemy() -> void:
	state = S.ENEMY
	soul.position = BOX_ENEMY.get_center()
	enemy_t = 0.0
	hazards.clear()
	# Reyon menyerang `attacks_per_turn` kali, jenisnya acak. Serangan berikutnya mulai
	# `attack_interval` detik setelah serangan sebelumnya dilancarkan; tiap serangan
	# ditandai putih dulu selama `telegraph_time` detik.
	if Game.enemy_type == "skeleton":
		if randi() % 2 == 0:
			_make_bone_attack(0.0)
		else:
			_make_bone_wall(0.0)
	else:
		for i in attacks_per_turn:
			var t0 := i * attack_interval
			match randi() % 3:
				0: _make_slash(t0)
				1: _make_crack(t0)
				2: _make_pinch(t0)
	enemy_len = 0.0
	for h in hazards:
		enemy_len = maxf(enemy_len, h.delay + telegraph_time + h.active)
	enemy_len += 0.4


## 1) slash: serangan ngasal, kena -3
func _make_slash(t0: float) -> void:
	for i in 3:
		var a: Vector2
		var b: Vector2
		if randf() < 0.5:
			a = Vector2(randf_range(BOX_ENEMY.position.x, BOX_ENEMY.end.x), BOX_ENEMY.position.y - 10)
			b = Vector2(randf_range(BOX_ENEMY.position.x, BOX_ENEMY.end.x), BOX_ENEMY.end.y + 10)
		else:
			a = Vector2(BOX_ENEMY.position.x - 10, randf_range(BOX_ENEMY.position.y, BOX_ENEMY.end.y))
			b = Vector2(BOX_ENEMY.end.x + 10, randf_range(BOX_ENEMY.position.y, BOX_ENEMY.end.y))
		hazards.append({"kind": "line", "a": a, "b": b, "delay": t0 + i * 0.3, "active": 0.15, "dmg": 3, "hit": false})


## 2) retakan: bagian kiri kotak jadi spike, kena -2
func _make_crack(t0: float) -> void:
	var r := Rect2(BOX_ENEMY.position.x, BOX_ENEMY.position.y, 150, BOX_ENEMY.size.y)
	hazards.append({"kind": "spikes", "rect": r, "delay": t0, "active": 1.4, "dmg": 3, "hit": false})


## 3) cabitan: bagian atas kotak, muncul cepat, kena -5
func _make_pinch(t0: float) -> void:
	var r := Rect2(BOX_ENEMY.position.x, BOX_ENEMY.position.y, BOX_ENEMY.size.x, 45)
	hazards.append({"kind": "pinch", "rect": r, "delay": t0, "active": 0.25, "dmg": 5, "hit": false})
	hazards.append({"kind": "pinch", "rect": r, "delay": t0 + 0.9, "active": 0.15, "dmg": 7, "hit": false})


## Bone Attack: sepuluh tulang melesat beruntun dengan jeda sangat singkat.
func _make_bone_attack(t0: float) -> void:
	for i in 10:
		var vertical := (i % 2 == 0)
		var a: Vector2
		var b: Vector2
		if vertical:
			var x := randf_range(BOX_ENEMY.position.x + 8, BOX_ENEMY.end.x - 8)
			a = Vector2(x, BOX_ENEMY.position.y - 8)
			b = Vector2(x + randf_range(-35, 35), BOX_ENEMY.end.y + 8)
		else:
			var y := randf_range(BOX_ENEMY.position.y + 8, BOX_ENEMY.end.y - 8)
			a = Vector2(BOX_ENEMY.position.x - 8, y)
			b = Vector2(BOX_ENEMY.end.x + 8, y + randf_range(-22, 22))
		hazards.append({"kind": "bone_line", "a": a, "b": b, "delay": t0 + i * 0.14, "active": 0.12, "dmg": 3, "hit": false})


## Bone Wall: jalur aman sempit bergerak ke samping dan menarik jiwa ke arahnya.
func _make_bone_wall(t0: float) -> void:
	var gap := randf_range(BOX_ENEMY.position.x + 42, BOX_ENEMY.end.x - 42)
	hazards.append({
		"kind": "bone_wall",
		"rect": BOX_ENEMY,
		"gap_x": gap,
		"gap_width": 40.0,
		"direction": 1.0 if randf() < 0.5 else -1.0,
		"delay": t0,
		"active": 3.2,
		"dmg": 5,
		"hit": false
	})


func _enemy(delta: float) -> void:
	enemy_t += delta
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var p := soul.position + dir * soul_speed * delta
	var inner := BOX_ENEMY.grow(-12)
	soul.position = Vector2(clampf(p.x, inner.position.x, inner.end.x), clampf(p.y, inner.position.y, inner.end.y))

	for h in hazards:
		var local: float = enemy_t - h.delay
		if h.kind == "bone_wall" and local >= telegraph_time and local < telegraph_time + h.active:
			h.gap_x += h.direction * 115.0 * delta
			var min_gap: float = BOX_ENEMY.position.x + h.gap_width * 0.5 + 8.0
			var max_gap: float = BOX_ENEMY.end.x - h.gap_width * 0.5 - 8.0
			if h.gap_x < min_gap or h.gap_x > max_gap:
				h.direction *= -1.0
				h.gap_x = clampf(h.gap_x, min_gap, max_gap)
			soul.position.x = move_toward(soul.position.x, h.gap_x, 115.0 * delta)
		if local >= telegraph_time and local < telegraph_time + h.active and not h.hit and invuln <= 0.0:
			if _hits(h):
				h.hit = true
				_damage(h.dmg)

	if state == S.ENEMY and enemy_t >= enemy_len:
		hazards.clear()
		state = S.MENU
		msg = "* your turn."
		msg_chars = 0.0


func _hits(h: Dictionary) -> bool:
	if h.kind == "line" or h.kind == "bone_line":
		var closest := Geometry2D.get_closest_point_to_segment(soul.position, h.a, h.b)
		return closest.distance_to(soul.position) < 10.0
	if h.kind == "bone_wall":
		return absf(soul.position.x - h.gap_x) > h.gap_width * 0.5
	var r: Rect2 = h.rect
	return r.grow(4).has_point(soul.position)


func _damage(n: int) -> void:
	Game.hp = maxi(Game.hp - n, 0)
	invuln = invuln_time
	if Game.hp <= 0:
		state = S.LOST


# ---------- PERBARUI TAMPILAN (node) ----------

func _refresh(delta: float) -> void:
	# kotak: lebar saat giliran LIN, kecil saat giliran Reyon
	var target := BOX_ENEMY if state == S.ENEMY else BOX_WIDE
	box.position = box.position.lerp(target.position, minf(1.0, 12.0 * delta))
	box.size = box.size.lerp(target.size, minf(1.0, 12.0 * delta))

	message.visible = state == S.MENU or state == S.MESSAGE
	if message.text != msg:
		message.text = msg
	message.visible_characters = int(msg_chars)
	act_menu.visible = state == S.ACT_MENU
	fight_bar.visible = state == S.FIGHT
	if state == S.FIGHT:
		cursor.position.x = fight_x - 4.0
		var blink := whip_t >= 0.0 and int(whip_t * 20.0) % 2 == 0
		cursor.color = Color(0.9, 0.1, 0.1) if blink else Color.WHITE

	# Reyon: bergetar & berkedip saat kena
	enemy.visible = not (enemy_flash > 0.0 and int(enemy_flash * 10.0) % 2 == 0)
	enemy.position = enemy_base + (Vector2(randf_range(-6.0, 6.0), 0.0) if shake > 0.0 else Vector2.ZERO)
	enemy_hp_bar.visible = enemy_flash > 0.0
	enemy_hp_bar.value = maxi(enemy_hp, 0)

	# efek cambuk
	whip_fx.visible = whip_t >= 0.0
	if whip_t >= 0.0:
		whip_fx.modulate.a = 1.0 - whip_t / 0.45

	# HP: bagian putih = nyawa yang hilang (dari kanan)
	hp_label.text = "%d / %d" % [Game.hp, Game.MAX_HP]
	var lost := 1.0 - float(Game.hp) / Game.MAX_HP
	hp_lost.visible = lost > 0.0
	var w := LOST_FULL_WIDTH * lost
	hp_lost.size.x = w
	hp_lost.position.x = LOST_RIGHT_EDGE - w

	# tombol menu: yang dipilih terang
	for i in 3:
		var selected := (state == S.MENU and i == menu_index) or (state == S.ACT_MENU and i == 1) or (state == S.FIGHT and i == 0)
		var btn: TextureRect = menu_btns[i]
		btn.modulate.a = 1.0 if selected else 0.55

	_update_soul()
	hazard_layer.queue_redraw()
	game_over.visible = state == S.LOST


func _update_soul() -> void:
	match state:
		S.MENU:
			soul.visible = true
			var btn: TextureRect = menu_btns[menu_index]
			var tx := btn.texture
			var w := minf(btn.size.x, tx.get_width() * btn.size.y / tx.get_height())
			var left := btn.position.x + (btn.size.x - w) * 0.5
			soul.position = Vector2(left + w * BTN_ICON_X[menu_index], btn.position.y + btn.size.y * 0.5)
		S.ACT_MENU:
			soul.visible = true
			var label: Label = act_labels[act_index]
			soul.position = box.position + act_menu.position + label.position + Vector2(-22.0, 18.0)
		S.ENEMY:
			soul.visible = int(invuln * 10.0) % 2 == 0
		_:
			soul.visible = false


## Dipanggil oleh node Hazards (hazard_layer.gd) untuk menggambar serangan.
func draw_hazards(ci: CanvasItem) -> void:
	if state != S.ENEMY:
		return
	for h in hazards:
		var local: float = enemy_t - h.delay
		if local < 0.0 or local >= telegraph_time + h.active:
			continue
		var active := local >= telegraph_time
		if h.kind == "line" or h.kind == "bone_line":
			var bone_color := Color(1, 0.2, 0.2) if active else Color.WHITE
			ci.draw_line(h.a, h.b, bone_color, 9.0 if h.kind == "bone_line" else 10.0)
			if h.kind == "bone_line":
				var mid: Vector2 = (h.a + h.b) * 0.5
				var side: Vector2 = (h.b - h.a).normalized().orthogonal() * 7.0
				ci.draw_line(mid - side, mid + side, bone_color, 5.0)
			continue
		if h.kind == "bone_wall":
			var r_wall: Rect2 = h.rect
			var half: float = h.gap_width * 0.5
			var left_rect := Rect2(r_wall.position, Vector2(h.gap_x - half - r_wall.position.x, r_wall.size.y))
			var right_rect := Rect2(Vector2(h.gap_x + half, r_wall.position.y), Vector2(r_wall.end.x - (h.gap_x + half), r_wall.size.y))
			var wall_color := Color(1, 1, 1, 0.28) if not active else Color(0.95, 0.95, 1.0)
			ci.draw_rect(left_rect, wall_color)
			ci.draw_rect(right_rect, wall_color)
			ci.draw_rect(left_rect, Color.WHITE, false, 2.0)
			ci.draw_rect(right_rect, Color.WHITE, false, 2.0)
			continue
		var r: Rect2 = h.rect
		if not active:
			ci.draw_rect(r, Color(1, 1, 1, 0.3))
			ci.draw_rect(r, Color.WHITE, false, 2.0)
		elif h.kind == "spikes":
			var x := r.position.x
			while x < r.end.x - 1.0:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, r.end.y), Vector2(x + 25, r.end.y), Vector2(x + 12.5, r.end.y - 50)]), Color(1, 0.3, 0.3))
				x += 25.0
		else:
			var x2 := r.position.x
			while x2 < r.end.x - 1.0:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x2, r.position.y), Vector2(x2 + 30, r.position.y), Vector2(x2 + 15, r.position.y + r.size.y)]), Color(1, 0.2, 0.2))
				x2 += 30.0
