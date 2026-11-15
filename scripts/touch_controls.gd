extends CanvasLayer
## Tombol layar sentuh untuk HP/tablet: panah (naik/turun/kiri/kanan), A = interact, B = cancel.
## Tiap tombol adalah node TouchScreenButton dengan properti "Action", jadi sama
## dengan menekan keyboard. Geser/ubah ukuran tombol langsung di editor.

## Tampilkan juga di PC (berguna untuk mencoba tata letak). Matikan sebelum rilis di PC.
@export var show_on_desktop := true


func _ready() -> void:
	visible = show_on_desktop or DisplayServer.is_touchscreen_available()
