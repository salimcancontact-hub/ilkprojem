extends Node
## Oyun genelindeki durumu tutar (autoload olarak "Game" adıyla yüklenir).

signal gems_changed(collected: int, total: int)

var gems_collected: int = 0
var gems_total: int = 0


func _ready() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("attack", [KEY_J, KEY_F])
	_add_key_action("interact", [KEY_E])


# --- Açılış teşhisi -----------------------------------------------------------
# Yükleme adımları bir dosyaya yazılır. Oyun çökerse bir sonraki açılışta
# açılış ekranı en son hangi adımda kalındığını gösterir.

const BOOT_LOG := "user://acilis_kaydi.txt"
const BOOT_OK := "TAMAM"

var _boot_frames: int = -1


func boot_log(step: String, fresh: bool = false) -> void:
	var f: FileAccess
	if fresh or not FileAccess.file_exists(BOOT_LOG):
		f = FileAccess.open(BOOT_LOG, FileAccess.WRITE)
	else:
		f = FileAccess.open(BOOT_LOG, FileAccess.READ_WRITE)
		f.seek_end()
	if f:
		f.store_line("%s  %s" % [Time.get_time_string_from_system(), step])
		f.flush()


## Önceki açılış düzgün bitmediyse son adımları döndürür, yoksa "".
func previous_boot_failure() -> String:
	if not FileAccess.file_exists(BOOT_LOG):
		return ""
	var lines := FileAccess.get_file_as_string(BOOT_LOG).strip_edges().split("\n")
	if lines.is_empty() or lines[-1].ends_with(BOOT_OK):
		return ""
	return "\n".join(lines.slice(maxi(lines.size() - 4, 0)))


## Seviye ilk kez çizilmeye başladıktan birkaç kare sonra "TAMAM" yazılır.
func mark_level_started() -> void:
	boot_log("sahne hazır, ilk kareler çiziliyor")
	_boot_frames = 30


func _process(_delta: float) -> void:
	if _boot_frames > 0:
		_boot_frames -= 1
		if _boot_frames == 0:
			boot_log(BOOT_OK)


func reset(total_gems: int) -> void:
	gems_collected = 0
	gems_total = total_gems
	gems_changed.emit(gems_collected, gems_total)


func collect_gem() -> void:
	gems_collected += 1
	gems_changed.emit(gems_collected, gems_total)


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
