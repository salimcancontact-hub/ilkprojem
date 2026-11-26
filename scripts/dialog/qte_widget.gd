extends Control
## Telltale tarzı anlık tuşa basma (QTE) göstergesi.
## Türler: "bas" (zamanında dokun), "vur" (hızlı hızlı dokun), "kaydir" (doğru yöne kaydır).

signal finished(success: bool)

const RADIUS := 78.0
const DIRS := {"sol": Vector2.LEFT, "sag": Vector2.RIGHT, "yukari": Vector2.UP, "asagi": Vector2.DOWN}
const KEYS := {"sol": KEY_LEFT, "sag": KEY_RIGHT, "yukari": KEY_UP, "asagi": KEY_DOWN}

var active: bool = false
var _kind: String = ""
var _label: String = ""
var _time: float = 1.0
var _left: float = 0.0
var _count: int = 1
var _fill: float = 0.0
var _dir: String = ""
var _press_pos: Vector2
var _pressing: bool = false
var _result_t: float = 0.0
var _result_ok: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func start(step: Dictionary) -> void:
	_kind = step["kind"]
	_label = step["label"]
	_time = maxf(step["time"], 0.3)
	_left = _time
	_count = maxi(step["count"], 1)
	_dir = step["dir"]
	_fill = 0.0
	_result_t = 0.0
	_pressing = false
	active = true
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	if _result_t > 0.0:
		_result_t -= delta
		if _result_t <= 0.0:
			visible = false
			finished.emit(_result_ok)
		queue_redraw()
		return
	if not active:
		return
	_left -= delta
	if _kind == "vur":
		_fill = maxf(_fill - delta * 0.12, 0.0)
	if _left <= 0.0:
		_end(false)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
			_pressing = true
			if _kind != "kaydir":
				_hit()
		elif _pressing and _kind == "kaydir":
			_pressing = false
			_check_swipe(event.position - _press_pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if _kind == "kaydir":
			if KEYS.has(_dir) and k == KEYS[_dir]:
				_end(true)
			elif k in KEYS.values():
				_end(false)
		elif k == KEY_SPACE or k == KEY_ENTER:
			_hit()
		get_viewport().set_input_as_handled()


func _hit() -> void:
	if _kind == "bas":
		_end(true)
	elif _kind == "vur":
		_fill += 1.0 / _count
		if _fill >= 1.0:
			_end(true)


func _check_swipe(v: Vector2) -> void:
	if v.length() < 60.0:
		return  # kaydırma değil, dokunma
	var want: Vector2 = DIRS.get(_dir, Vector2.LEFT)
	_end(v.normalized().dot(want) > 0.6)


func _end(ok: bool) -> void:
	active = false
	_result_ok = ok
	_result_t = 0.35
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y * 0.73)
	var t := clampf(_left / _time, 0.0, 1.0)
	var col := Color(1, 1, 1)
	if _result_t > 0.0:
		col = Color(0.4, 1.0, 0.55) if _result_ok else Color(1.0, 0.35, 0.3)
		var grow := (0.35 - _result_t) * 160.0
		draw_arc(c, RADIUS + grow, 0, TAU, 64, Color(col, _result_t * 2.5), 6.0, true)
		return
	var pulse := 1.0 + sin(_pulse * 12.0) * 0.04
	draw_circle(c, RADIUS * pulse, Color(0, 0, 0, 0.55))
	# Kalan süre halkası
	draw_arc(c, RADIUS + 14, -PI / 2, -PI / 2 + TAU * t, 64, Color(1, 0.85, 0.4, 0.9), 7.0, true)
	if _kind == "vur":
		draw_arc(c, RADIUS - 6, -PI / 2, -PI / 2 + TAU * _fill, 64, Color(0.4, 0.9, 1.0), 12.0, true)
	draw_arc(c, RADIUS * pulse, 0, TAU, 64, col, 4.0, true)
	var font := get_theme_default_font()
	var text: String = _label if not _label.is_empty() else {"bas": "DOKUN", "vur": "HIZLI DOKUN", "kaydir": "KAYDIR"}.get(_kind, "")
	var fs := 30
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	if _kind == "kaydir":
		var d: Vector2 = DIRS.get(_dir, Vector2.LEFT)
		var shift := d * (sin(_pulse * 6.0) * 0.5 + 0.5) * 16.0
		var tip := c + d * 44.0 + shift
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([tip, tip - d * 34.0 + side * 26.0, tip - d * 34.0 - side * 26.0]), col)
		draw_line(c - d * 40.0 + shift, tip - d * 20.0, col, 10.0, true)
		draw_string(font, c + Vector2(-tw / 2.0, RADIUS + 58), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	else:
		draw_string(font, c + Vector2(-tw / 2.0, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if _kind == "vur":
			var sub := "x%d" % _count
			var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_CENTER, -1, 20).x
			draw_string(font, c + Vector2(-sw / 2.0, 40), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.7))
