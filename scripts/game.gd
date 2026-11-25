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
