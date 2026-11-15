extends Control
## Menu utama: KREDIT (kiri), CONTINUE (tengah), PLAY (kanan).
## Kontrol: kiri/kanan memilih, interact (Z / Enter / tombol A) menekan, atau sentuh/klik tombolnya.
## Semua tampilan = node di scenes/main_menu.tscn (judul, tombol, panel kredit) dan bisa diedit.

const KREDIT := 0
const CONTINUE := 1
const PLAY := 2

@onready var buttons: Array = [$Kredit, $Continue, $Play]
@onready var soul: Sprite2D = $Soul
@onready var credits: CanvasLayer = $Credits

var index := PLAY


func _ready() -> void:
	credits.visible = false
	for i in buttons.size():
		var b: TextureButton = buttons[i]
		b.pressed.connect(_activate.bind(i))
		b.mouse_entered.connect(_select.bind(i))
	$Credits/CloseArea.pressed.connect(_close_credits)
	_refresh()


func _process(_delta: float) -> void:
	if credits.visible:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			_close_credits()
		return
	if Input.is_action_just_pressed("move_left"):
		_move(-1)
	elif Input.is_action_just_pressed("move_right"):
		_move(1)
	elif Input.is_action_just_pressed("interact"):
		_activate(index)


func _move(step: int) -> void:
	var i := index
	for _n in buttons.size():
		i = posmod(i + step, buttons.size())
		if _enabled(i):
			index = i
			break
	_refresh()


func _enabled(i: int) -> bool:
	return i != CONTINUE or Game.has_save()


func _select(i: int) -> void:
	if _enabled(i) and not credits.visible:
		index = i
		_refresh()


func _activate(i: int) -> void:
	if credits.visible or not _enabled(i):
		return
	match i:
		KREDIT:
			credits.visible = true
		CONTINUE:
			Game.continue_game()
		PLAY:
			Game.new_game()


func _close_credits() -> void:
	credits.visible = false


func _refresh() -> void:
	for i in buttons.size():
		var b: TextureButton = buttons[i]
		if not _enabled(i):
			b.modulate = Color(0.35, 0.35, 0.35, 1.0)      # CONTINUE mati kalau belum ada save
		elif i == index:
			b.modulate = Color.WHITE
		else:
			b.modulate = Color(0.65, 0.65, 0.65, 1.0)
	# hati magenta menunjuk tombol yang dipilih (di sebelah kirinya)
	var sel: TextureButton = buttons[index]
	soul.position = Vector2(sel.position.x - 26.0, sel.position.y + sel.size.y * 0.5)
