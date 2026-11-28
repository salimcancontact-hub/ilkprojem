class_name LoadingOverlay
extends CanvasLayer
## Sahne yüklenirken siyah ekranda animasyon: gezegenin etrafında dönen küçük gemi (EMANET),
## nabız gibi atan yıldızlar ve "Yeni sahne hazırlanıyor" yazısı. Takılmalarda bile akıcı görünsün diye
## yalnızca 2B çizim kullanır (gölgelendirici derlemesi yok).

var subtitle: String = "Yeni sahne hazırlanıyor"
var _t: float = 0.0
var _canvas: Control
var _stars: Array[Vector3] = []


static func show_on(parent: Node, text: String = "Yeni sahne hazırlanıyor") -> LoadingOverlay:
	var o := LoadingOverlay.new()
	o.subtitle = text
	parent.add_child(o)
	return o


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2526
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.0, TAU)))


func _process(delta: float) -> void:
	_t += minf(delta, 0.1)
	_canvas.queue_redraw()


## İşi bitince yavaşça kaybolur.
func finish(time: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_canvas, "modulate:a", 0.0, time)
	for c in get_children():
		if c is ColorRect:
			tw.parallel().tween_property(c, "modulate:a", 0.0, time)
	await tw.finished
	queue_free()


func _draw_canvas() -> void:
	var size := _canvas.size
	var c := Vector2(size.x / 2.0, size.y * 0.44)
	# Yıldızlar
	for s in _stars:
		var a := 0.25 + 0.35 * (0.5 + 0.5 * sin(_t * 2.0 + s.z))
		_canvas.draw_circle(Vector2(s.x * size.x, s.y * size.y), 1.6, Color(0.8, 0.85, 1.0, a))
	# Gezegen (Dünya): mavi disk, aydınlık kenar
	var r := 46.0
	_canvas.draw_circle(c, r, Color(0.08, 0.2, 0.42))
	_canvas.draw_circle(c + Vector2(-8, -6), r * 0.82, Color(0.12, 0.3, 0.55))
	_canvas.draw_arc(c, r + 3.0, 0, TAU, 64, Color(0.4, 0.7, 1.0, 0.5), 3.0, true)
	# Yörünge çizgisi (eliptik, kesik kesik)
	var orbit := Vector2(150, 46)
	for i in 48:
		if i % 2 == 0:
			var a0 := i * TAU / 48.0
			var a1 := (i + 1) * TAU / 48.0
			_canvas.draw_line(c + Vector2(cos(a0) * orbit.x, sin(a0) * orbit.y), c + Vector2(cos(a1) * orbit.x, sin(a1) * orbit.y), Color(0.6, 0.75, 1.0, 0.25), 1.5, true)
	# Gemi: yörüngede döner, arkasında iz bırakır
	var ang := _t * 1.4
	for k in 14:
		var aa := ang - k * 0.07
		var p := c + Vector2(cos(aa) * orbit.x, sin(aa) * orbit.y)
		var behind := sin(aa) < 0.0 and absf(cos(aa) * orbit.x) < r
		if not behind:
			_canvas.draw_circle(p, 3.2 - k * 0.2, Color(1.0, 0.65, 0.3, 0.6 - k * 0.04))
	var sp := c + Vector2(cos(ang) * orbit.x, sin(ang) * orbit.y)
	var hidden := sin(ang) < 0.0 and absf(cos(ang) * orbit.x) < r
	if not hidden:
		var dir := Vector2(-sin(ang) * orbit.x, cos(ang) * orbit.y).normalized()
		var side := Vector2(-dir.y, dir.x)
		var hull := PackedVector2Array([sp + dir * 11.0, sp - dir * 8.0 + side * 4.5, sp - dir * 5.0, sp - dir * 8.0 - side * 4.5])
		_canvas.draw_colored_polygon(hull, Color(0.95, 0.95, 1.0))
		_canvas.draw_circle(sp - dir * 8.0, 3.0, Color(1.0, 0.6, 0.25))
	# Yazılar
	var font := ThemeDB.fallback_font
	var title := "EMANET"
	var fs := 34
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_canvas.draw_string(font, Vector2(c.x - tw / 2.0, c.y + 120), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.92, 0.55, 0.22))
	var dots := ".".repeat(int(_t * 2.5) % 4)
	var sub := subtitle + dots
	var sw := font.get_string_size(subtitle + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	_canvas.draw_string(font, Vector2(c.x - sw / 2.0, c.y + 158), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.65, 0.7, 0.82))
