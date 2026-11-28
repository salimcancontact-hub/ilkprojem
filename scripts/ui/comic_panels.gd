class_name ComicPanels
extends Control
## Giriş anlatımı için çizgi roman panelleri (kodla çizilir: kalın mürekkep kontur, düz renk,
## raster nokta gölge, kâğıt dokusu). Her panel ağır ağır yakınlaşıp kayar (Ken Burns), içinde
## küçük canlı hareketler vardır (çatlaklar büyür, toz uçar, liste akar, kalem yazar).
## Kullanım (diyalog): @olay cizgi kuraklik | liste | soru | gunluk ; @olay cizgi_bitti
## Görsel yalnızca 2B çizimdir: gölgelendirici derlemesi yok, zayıf GPU'da da akıcı.

const W := 1000.0
const H := 560.0
const INK := Color(0.07, 0.06, 0.06)
const PAPER := Color(0.95, 0.92, 0.84)

var _panel: String = ""
var _prev: String = ""
var _t: float = 0.0
var _swap: float = 1.0  # 0 -> 1 geçiş (yeni panel kayarak gelir)
var _alpha: float = 0.0
var _alpha_target: float = 0.0
var _rng := RandomNumberGenerator.new()
var _cracks: Array = []      # [[noktalar], başlangıç zamanı]
var _dust: Array[Vector3] = []
var _names: PackedStringArray = []
var _crowd: Array[Vector3] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 2526
	_build_cracks()
	for i in 40:
		_dust.append(Vector3(_rng.randf() * W, _rng.randf() * H, _rng.randf_range(0.4, 1.4)))
	var first := ["AYLİN", "MERT", "DEFNE", "KAAN", "SELİN", "ONUR", "EZGİ", "BARAN", "ZEYNEP", "EMRE", "İPEK", "TOLGA", "NAZ", "BURAK", "ECE", "DENİZ", "CAN", "MELİS", "ARDA", "SU"]
	var last := ["YILMAZ", "KAYA", "DEMİR", "ŞAHİN", "ÇELİK", "ARSLAN", "DOĞAN", "KOÇ", "AYDIN", "ÖZTÜRK", "KURT", "ARMAN", "POLAT", "ERDEM", "TUNA"]
	for i in 60:
		_names.append("%03d  %s %s" % [i + 1, first[_rng.randi() % first.size()], last[_rng.randi() % last.size()]])
	for i in 26:
		_crowd.append(Vector3(_rng.randf_range(-20, W + 20), _rng.randf_range(0.0, 1.0), _rng.randf_range(0.8, 1.25)))


func show_panel(id: String) -> void:
	if id == _panel:
		return
	_prev = _panel
	_panel = id
	_swap = 0.0
	_t = 0.0
	_alpha_target = 1.0


func hide_panels(time: float = 1.2) -> void:
	_alpha_target = 0.0
	_fade_speed = 1.0 / maxf(time, 0.05)


var _fade_speed: float = 1.6


func _process(delta: float) -> void:
	var dt := minf(delta, 0.1)
	_t += dt
	_swap = minf(_swap + dt / 0.7, 1.0)
	_alpha = move_toward(_alpha, _alpha_target, dt * (_fade_speed if _alpha_target < _alpha else 2.5))
	visible = _alpha > 0.001
	if visible:
		queue_redraw()


# --- Yerleşim ----------------------------------------------------------------

## Panelin ekrandaki yeri: yazı kutusunun üstünde kalan alan.
func _frame_rect() -> Rect2:
	var s := get_viewport_rect().size
	var top := s.y * 0.11
	var bottom := s.y * 0.62
	var h := bottom - top
	var w := minf(s.x * 0.9, h * W / H)
	return Rect2((s.x - w) / 2.0, top, w, h)


func _draw() -> void:
	var r := _frame_rect()
	var sc := r.size.x / W
	# Geçiş: eski panel sola kayıp söner, yenisi hafif dönük gelir ve oturur
	var e := _ease(_swap)
	if _prev != "" and _swap < 1.0:
		_draw_panel(_prev, r, sc, (1.0 - e) * _alpha, Vector2(-e * r.size.x * 0.25, 0), -0.04 * e, 99.0)
	_draw_panel(_panel, r, sc, _alpha * (e if _prev != "" else 1.0), Vector2((1.0 - e) * r.size.x * 0.18, 0), 0.035 * (1.0 - e) - 0.012, _t)


func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func _draw_panel(id: String, r: Rect2, sc: float, a: float, shift: Vector2, rot: float, t: float) -> void:
	if a <= 0.01 or id == "":
		return
	var center := r.position + r.size / 2.0 + shift
	# Gölge + beyaz çerçeve payı (sayfadan kesilmiş panel)
	draw_set_transform(center, rot, Vector2.ONE)
	var hw := r.size / 2.0
	draw_rect(Rect2(-hw - Vector2(4, 4), r.size + Vector2(8, 8)), Color(PAPER, a))
	# Panel içeriği (tasarım uzayında, Ken Burns: yavaş yakınlaşma ve kayma)
	var kb := 1.0 + minf(t, 14.0) * 0.006
	var pan := Vector2(-minf(t, 14.0) * 1.6, -minf(t, 14.0) * 0.5)
	draw_set_transform(center, rot, Vector2(sc, sc))
	_clip_begin()
	match id:
		"kuraklik": _p_drought(t, a, kb, pan)
		"liste": _p_list(t, a, kb, pan)
		"soru": _p_question(t, a, kb, pan)
		"gunluk": _p_diary(t, a, kb, pan)
	# Panelin dışına taşanları siyahla örter (kırpma yerine), sonra kâğıt kenar + mürekkep çerçeve
	_mask(a)
	var bw := 9.0 / sc
	draw_rect(Rect2(-W / 2 - bw / 2, -H / 2 - bw / 2, W + bw, H + bw), Color(PAPER, a), false, bw)
	draw_rect(Rect2(-W / 2, -H / 2, W, H), Color(INK, a), false, 7.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _clip_begin() -> void:
	pass


func _mask(a: float) -> void:
	var big := 2000.0
	var c := Color(0.0, 0.0, 0.0, a)
	draw_rect(Rect2(-W / 2 - big, -H / 2 - big, big * 2 + W, big), c)
	draw_rect(Rect2(-W / 2 - big, H / 2, big * 2 + W, big), c)
	draw_rect(Rect2(-W / 2 - big, -H / 2, big, H), c)
	draw_rect(Rect2(W / 2, -H / 2, big, H), c)


## Tasarım noktası (0..W, 0..H) -> panel merkezli çizim koordinatı, Ken Burns ile.
func _p(x: float, y: float, kb: float, pan: Vector2, depth: float = 1.0) -> Vector2:
	return (Vector2(x - W / 2, y - H / 2) + pan * depth) * kb


func _poly(pts: PackedVector2Array, fill: Color, a: float, ink: float = 5.0) -> void:
	if pts.size() >= 3:
		draw_colored_polygon(pts, Color(fill, fill.a * a))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(INK, a), ink, true)


func _caption(text: String, at: Vector2, a: float, fs: int = 22) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var rect := Rect2(at, Vector2(w + 28, fs + 20))
	draw_rect(Rect2(rect.position + Vector2(5, 5), rect.size), Color(INK, a))
	draw_rect(rect, Color(0.98, 0.86, 0.32, a))
	draw_rect(rect, Color(INK, a), false, 3.0)
	draw_string(font, at + Vector2(14, fs + 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, a))


## Raster nokta gölge: bölgede, yoğunluk fonksiyonuna göre büyüyen noktalar.
func _halftone(rect: Rect2, col: Color, a: float, dens: Callable, step: float = 15.0) -> void:
	var y := rect.position.y
	var row := 0
	while y < rect.end.y:
		var x := rect.position.x + (step * 0.5 if row % 2 == 1 else 0.0)
		while x < rect.end.x:
			var d: float = dens.call(Vector2(x, y))
			if d > 0.05:
				draw_circle(Vector2(x, y), step * 0.48 * clampf(d, 0.0, 1.0), Color(col, col.a * a))
			x += step
		y += step * 0.87
		row += 1


func _build_cracks() -> void:
	# Kurumuş nehir yatağında dallanan çatlaklar (zamanla uzar)
	for i in 14:
		var p := Vector2(_rng.randf_range(80, 920), _rng.randf_range(330, 540))
		var pts := PackedVector2Array([p])
		var dir := Vector2.RIGHT.rotated(_rng.randf() * TAU)
		for k in 7:
			dir = dir.rotated(_rng.randf_range(-0.7, 0.7))
			p += dir * _rng.randf_range(16, 34)
			pts.append(p)
		_cracks.append([pts, _rng.randf_range(0.2, 3.5)])


# --- Panel 1: Kuraklık. "Nehirler artık yalnızca haritalarda akıyor." -------------------

func _p_drought(t: float, a: float, kb: float, pan: Vector2) -> void:
	# Gök: kızgın turuncu, ufka doğru sararan
	for i in 8:
		var y0 := i * 300.0 / 8.0
		var c := Color(0.93, 0.42, 0.16).lerp(Color(0.99, 0.8, 0.42), i / 7.0)
		var p0 := _p(-60, y0, kb, pan, 0.3)
		var p1 := _p(W + 60, y0 + 300.0 / 8.0 + 1, kb, pan, 0.3)
		draw_rect(Rect2(p0, p1 - p0), Color(c, a))
	# Güneş: büyük disk, dönen ışınlar, raster hale
	var sun := _p(700, 120, kb, pan, 0.3)
	var pulse := 1.0 + sin(t * 2.2) * 0.03
	for k in 16:
		var ang := k * TAU / 16.0 + t * 0.08
		var tri := PackedVector2Array([sun + Vector2.from_angle(ang - 0.07) * 95.0, sun + Vector2.from_angle(ang) * (190.0 * pulse), sun + Vector2.from_angle(ang + 0.07) * 95.0])
		draw_colored_polygon(tri, Color(1.0, 0.93, 0.6, 0.55 * a))
	draw_circle(sun, 82.0 * pulse, Color(1.0, 0.96, 0.78, a))
	draw_arc(sun, 82.0 * pulse, 0, TAU, 48, Color(INK, a), 5.0, true)
	_halftone(Rect2(_p(-40, -40, kb, pan, 0.3), Vector2(W + 80, 330) * kb), Color(0.75, 0.25, 0.08, 0.55), a,
		func(q: Vector2) -> float: return clampf((q.distance_to(sun) - 150.0) / 420.0, 0.0, 0.8), 16.0)
	# Uzak tepeler
	var hills := PackedVector2Array([_p(-60, 300, kb, pan, 0.6)])
	for k in 11:
		hills.append(_p(-60 + k * 112.0, 250.0 + sin(k * 1.7) * 30.0, kb, pan, 0.6))
	hills.append(_p(W + 60, 300, kb, pan, 0.6))
	_poly(hills, Color(0.62, 0.36, 0.22), a, 4.0)
	# Toprak
	var ground := PackedVector2Array([_p(-60, 290, kb, pan), _p(W + 60, 290, kb, pan), _p(W + 60, H + 60, kb, pan), _p(-60, H + 60, kb, pan)])
	_poly(ground, Color(0.78, 0.6, 0.4), a, 4.0)
	# Kurumuş nehir yatağı: kıvrılan koyu şerit
	var bed_l := PackedVector2Array()
	var bed_r := PackedVector2Array()
	for k in 13:
		var yy := 292.0 + k * 22.0
		var xx := 470.0 + sin(k * 0.55) * 120.0 - k * 10.0
		var half := 30.0 + k * 13.0
		bed_l.append(_p(xx - half, yy, kb, pan))
		bed_r.append(_p(xx + half, yy, kb, pan))
	var bed := bed_l.duplicate()
	var rr := bed_r.duplicate()
	rr.reverse()
	bed.append_array(rr)
	_poly(bed, Color(0.58, 0.42, 0.28), a, 4.0)
	_halftone(Rect2(_p(200, 290, kb, pan), Vector2(600, 280) * kb), Color(0.36, 0.22, 0.12, 0.6), a,
		func(q: Vector2) -> float: return 0.55 if Geometry2D.is_point_in_polygon(q, bed) else 0.0, 13.0)
	# Çatlaklar zamanla uzar
	for c in _cracks:
		var pts: PackedVector2Array = c[0]
		var grow := clampf((t - float(c[1])) / 2.5, 0.0, 1.0)
		var n := int(round(grow * (pts.size() - 1)))
		if n >= 1:
			var seg := PackedVector2Array()
			for k in n + 1:
				seg.append(_p(pts[k].x, pts[k].y, kb, pan))
			draw_polyline(seg, Color(INK, a), 3.0, true)
	# Karaya oturmuş paslı kayık
	var b := PackedVector2Array([_p(230, 400, kb, pan), _p(380, 385, kb, pan), _p(360, 430, kb, pan), _p(255, 438, kb, pan)])
	_poly(b, Color(0.55, 0.22, 0.14), a, 5.0)
	draw_line(_p(300, 392, kb, pan), _p(292, 312, kb, pan), Color(INK, a), 5.0, true)
	# Ölü ağaç
	var trunk := _p(130, 300, kb, pan)
	draw_line(trunk, _p(120, 180, kb, pan), Color(INK, a), 9.0, true)
	draw_line(_p(122, 215, kb, pan), _p(70, 160, kb, pan), Color(INK, a), 6.0, true)
	draw_line(_p(121, 200, kb, pan), _p(170, 150, kb, pan), Color(INK, a), 6.0, true)
	draw_line(_p(80, 172, kb, pan), _p(60, 130, kb, pan), Color(INK, a), 4.0, true)
	# Toz: sağdan sola sürüklenir
	for d in _dust:
		var x := fposmod(d.x - t * 40.0 * d.z, W + 100) - 50
		var y := d.y * 0.7 + 150 + sin(t * 1.3 + d.x) * 8.0
		draw_circle(_p(x, y, kb, pan, 1.3), 2.2 * d.z, Color(0.98, 0.9, 0.7, 0.7 * a))
	# Köşede eski harita: mavi nehir yalnızca kâğıtta akıyor
	var m0 := _p(735, 380, kb, pan, 1.2)
	var mp := PackedVector2Array([m0, m0 + Vector2(220, -14) * kb, m0 + Vector2(232, 150) * kb, m0 + Vector2(8, 162) * kb])
	_poly(mp, Color(0.93, 0.89, 0.74), a, 4.0)
	var river := PackedVector2Array()
	for k in 12:
		var f := k / 11.0
		river.append(m0 + Vector2(20 + f * 195, 40 + sin(f * 7.0 + t * 0.6) * 18 + f * 70) * kb)
	draw_polyline(river, Color(0.15, 0.45, 0.85, a), 7.0 * kb, true)
	draw_polyline(river, Color(0.55, 0.8, 1.0, a), 2.5 * kb, true)
	_caption("KURAKLIĞIN 11. YILI", Vector2(-W / 2 + 24, -H / 2 + 22), a)


# --- Panel 2: Liste. "Beş yüz isim. Sekiz milyar insan." ---------------------------------

func _p_list(t: float, a: float, kb: float, pan: Vector2) -> void:
	# Gece göğü ve şehir silueti
	var sky := Rect2(_p(-60, -60, kb, pan, 0.3), Vector2(W + 120, H + 120) * kb)
	draw_rect(sky, Color(0.09, 0.1, 0.2, a))
	_halftone(Rect2(_p(-40, -40, kb, pan, 0.3), Vector2(W + 80, 340) * kb), Color(0.25, 0.3, 0.55, 0.7), a,
		func(q: Vector2) -> float: return clampf(0.7 - (q.y + H / 2) / 520.0, 0.0, 0.7), 16.0)
	# Projektör ışıkları göğü tarar
	for k in 2:
		var base := _p(200 + k * 600, 330, kb, pan, 0.5)
		var ang := -PI / 2 + sin(t * 0.7 + k * 2.0) * 0.45
		var tip := base + Vector2.from_angle(ang) * 520.0
		var side := Vector2.from_angle(ang + PI / 2) * 60.0
		draw_colored_polygon(PackedVector2Array([base, tip + side, tip - side]), Color(0.75, 0.85, 1.0, 0.16 * a))
	var sk := PackedVector2Array([_p(-60, 340, kb, pan, 0.5)])
	var xs := [-60, -60, 40, 40, 110, 110, 170, 170, 260, 260, 300, 300, 700, 700, 780, 780, 860, 860, 930, 930, 1060, 1060]
	var ys := [340, 210, 210, 160, 160, 240, 240, 120, 120, 200, 200, 330, 330, 150, 150, 220, 220, 100, 100, 190, 190, 340]
	for k in xs.size():
		sk.append(_p(xs[k], ys[k], kb, pan, 0.5))
	_poly(sk, Color(0.05, 0.05, 0.1), a, 4.0)
	# Dev ekran: başlık ve yukarı akan isimler
	var s0 := _p(320, 40, kb, pan, 0.8)
	var s1 := _p(680, 330, kb, pan, 0.8)
	var scr := Rect2(s0, s1 - s0)
	draw_rect(Rect2(scr.position - Vector2(14, 14) * kb, scr.size + Vector2(28, 28) * kb), Color(0.12, 0.12, 0.14, a))
	draw_rect(scr, Color(0.06, 0.2, 0.26, a))
	var font := ThemeDB.fallback_font
	var fs := int(22 * kb)
	draw_string(font, scr.position + Vector2(18, 34) * kb, "KOMİTE — SON LİSTE", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * kb), Color(0.95, 0.85, 0.4, a))
	draw_line(scr.position + Vector2(14, 46) * kb, scr.position + Vector2(scr.size.x - 14 * kb, 46 * kb), Color(0.95, 0.85, 0.4, a), 2.0)
	var line_h := 28.0 * kb
	var scroll := fmod(t * 34.0 * kb, line_h * _names.size())
	var top_y := scr.position.y + 58 * kb
	var bottom_y := scr.end.y - 50 * kb
	for k in _names.size():
		var y := top_y + k * line_h - scroll
		if y < top_y - 4 or y > bottom_y:
			if y < top_y - 4:
				y += line_h * _names.size()
			if y < top_y - 4 or y > bottom_y:
				continue
		draw_string(font, Vector2(scr.position.x + 22 * kb, y + fs), _names[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.6, 0.95, 1.0, 0.9 * a))
	draw_string(font, Vector2(scr.position.x + 22 * kb, scr.end.y - 16 * kb), "500 / 8.000.000.000", HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * kb), Color(1.0, 0.45, 0.3, a))
	draw_rect(scr, Color(INK, a), false, 5.0)
	# Ekranın ışığı kalabalığın başlarına vurur; ön planda baş/omuz siluetleri
	for c in _crowd:
		var x := c.x + sin(t * 0.8 + c.x) * 3.0
		var y := 470.0 + c.y * 70.0
		var sc := c.z
		var head := _p(x, y - 55 * sc, kb, pan, 1.3)
		var sh := PackedVector2Array([_p(x - 48 * sc, H + 60, kb, pan, 1.3), _p(x - 40 * sc, y - 14 * sc, kb, pan, 1.3), _p(x + 40 * sc, y - 14 * sc, kb, pan, 1.3), _p(x + 48 * sc, H + 60, kb, pan, 1.3)])
		_poly(sh, Color(0.03, 0.03, 0.05), a, 3.0)
		draw_circle(head, 27 * sc * kb, Color(0.03, 0.03, 0.05, a))
		draw_arc(head, 27 * sc * kb, -PI * 0.95, -PI * 0.15, 12, Color(0.45, 0.9, 1.0, 0.8 * a), 3.0, true)
	_caption("SEÇİM GECESİ", Vector2(-W / 2 + 24, -H / 2 + 22), a)


# --- Panel 3: Soru. "Neden onlar? Neden ben değil?" --------------------------------------

func _p_question(t: float, a: float, kb: float, pan: Vector2) -> void:
	draw_rect(Rect2(_p(-60, -60, kb, pan, 0.3), Vector2(W + 120, H + 120) * kb), Color(0.55, 0.12, 0.1, a))
	# Merkezden patlayan hız çizgileri (çizgi roman gerilimi)
	var c := _p(720, 130, kb, pan, 0.4)
	for k in 40:
		var ang := k * TAU / 40.0 + sin(t * 0.3) * 0.02
		var r0 := 120.0 + fmod(k * 37.0, 60.0)
		draw_line(c + Vector2.from_angle(ang) * r0, c + Vector2.from_angle(ang) * 1100.0, Color(0.85, 0.3, 0.15, 0.55 * a), 6.0)
	_halftone(Rect2(_p(-40, -40, kb, pan, 0.3), Vector2(W + 80, H + 80) * kb), Color(0.25, 0.04, 0.04, 0.55), a,
		func(q: Vector2) -> float: return clampf(q.distance_to(c) / 700.0, 0.0, 0.75), 16.0)
	# Gökte uzaklaşan gemi EMANET: ışıklı gövde, motor izi
	var ship := c + Vector2(sin(t * 0.25) * 30.0, -t * 2.0) * kb
	var hull := PackedVector2Array([ship + Vector2(-110, 0) * kb, ship + Vector2(-60, -22) * kb, ship + Vector2(120, -8) * kb, ship + Vector2(140, 6) * kb, ship + Vector2(-60, 20) * kb])
	_poly(hull, Color(0.85, 0.86, 0.9), a, 4.0)
	for k in 6:
		draw_circle(ship + Vector2(-40 + k * 26, 0) * kb, 3.0 * kb, Color(1.0, 0.85, 0.4, a))
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-110, -8) * kb, ship + Vector2(-200 - sin(t * 9.0) * 12.0, 0) * kb, ship + Vector2(-110, 8) * kb]), Color(1.0, 0.7, 0.3, 0.9 * a))
	# Yukarı bakan yüzler: profil siluetleri (burun, dudak, çene), göğe dönük; sert ışık kenarı
	var prof := [Vector2(-70, 0), Vector2(20, 0), Vector2(24, -80), Vector2(55, -112), Vector2(64, -128), Vector2(58, -136),
		Vector2(72, -146), Vector2(64, -156), Vector2(98, -182), Vector2(76, -192), Vector2(80, -214), Vector2(70, -234),
		Vector2(40, -264), Vector2(-10, -280), Vector2(-60, -266), Vector2(-92, -222), Vector2(-88, -160), Vector2(-72, -118)]
	for k in 5:
		var bx := 60.0 + k * 215.0
		var by := 600.0 - (k % 2) * 36.0
		var s := 0.95 + (k % 3) * 0.1
		var tilt := -0.32 - (k % 2) * 0.1 + sin(t * 0.7 + k) * 0.02
		var face := PackedVector2Array()
		for v: Vector2 in prof:
			var w := (v * s).rotated(tilt)
			face.append(_p(bx + w.x, by + w.y, kb, pan, 1.3))
		_poly(face, Color(0.08, 0.05, 0.05), a, 4.0)
		var rim := PackedVector2Array()
		for i in range(2, 13):
			rim.append(face[i])
		draw_polyline(rim, Color(1.0, 0.75, 0.45, 0.9 * a), 4.0, true)
		# Gözde ışık
		var eye := (Vector2(52, -206) * s).rotated(tilt)
		draw_circle(_p(bx + eye.x, by + eye.y, kb, pan, 1.3), 4.0 * kb, Color(1.0, 0.85, 0.6, a))
	# Patlama balonunda soru
	var font := ThemeDB.fallback_font
	var bpos := Vector2(-W / 2 + 40, -H / 2 + 40)
	var burst := PackedVector2Array()
	for k in 22:
		var ang := k * TAU / 22.0
		var rad: float = (32.0 if k % 2 == 0 else 0.0) + 118.0
		burst.append(bpos + Vector2(190, 70) + Vector2(cos(ang) * rad * 1.75, sin(ang) * rad * 0.62))
	var pop := 1.0 + maxf(0.0, 0.25 - t * 0.6)
	for i in burst.size():
		burst[i] = bpos + Vector2(190, 70) + (burst[i] - bpos - Vector2(190, 70)) * pop
	_poly(burst, Color(1.0, 0.97, 0.88), a, 5.0)
	draw_string(font, bpos + Vector2(62, 62), "NEDEN ONLAR?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(INK, a))
	draw_string(font, bpos + Vector2(70, 108), "NEDEN BEN DEĞİL?", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.65, 0.08, 0.05, a))


# --- Panel 4: Günlük. "— Selim Arslan'ın günlüğünden" -----------------------------------

func _p_diary(t: float, a: float, kb: float, pan: Vector2) -> void:
	draw_rect(Rect2(_p(-60, -60, kb, pan, 0.3), Vector2(W + 120, H + 120) * kb), Color(0.27, 0.17, 0.11, a))
	_halftone(Rect2(_p(-40, -40, kb, pan, 0.3), Vector2(W + 80, H + 80) * kb), Color(0.12, 0.07, 0.04, 0.6), a,
		func(q: Vector2) -> float: return 0.45, 18.0)
	# Açık defter
	var l := PackedVector2Array([_p(140, 60, kb, pan), _p(500, 80, kb, pan), _p(500, 520, kb, pan), _p(120, 505, kb, pan)])
	var r := PackedVector2Array([_p(500, 80, kb, pan), _p(860, 58, kb, pan), _p(880, 503, kb, pan), _p(500, 520, kb, pan)])
	_poly(l, Color(0.96, 0.93, 0.83), a, 5.0)
	_poly(r, Color(0.97, 0.94, 0.85), a, 5.0)
	for k in 12:
		var y := 120.0 + k * 32.0
		draw_line(_p(160, y, kb, pan), _p(480, y + 6, kb, pan), Color(0.5, 0.65, 0.85, 0.5 * a), 1.5)
		draw_line(_p(520, y + 6, kb, pan), _p(850, y, kb, pan), Color(0.5, 0.65, 0.85, 0.5 * a), 1.5)
	# Kahve lekesi
	draw_arc(_p(770, 420, kb, pan), 46.0 * kb, 0.3, TAU - 0.2, 40, Color(0.55, 0.35, 0.2, 0.5 * a), 7.0 * kb, true)
	# Sol sayfada kenetli fotoğraf: iki kardeş
	var ph := PackedVector2Array([_p(190, 150, kb, pan), _p(420, 165, kb, pan), _p(410, 360, kb, pan), _p(180, 345, kb, pan)])
	_poly(ph, Color(0.88, 0.84, 0.75), a, 4.0)
	var ip := PackedVector2Array([_p(205, 168, kb, pan), _p(403, 181, kb, pan), _p(395, 320, kb, pan), _p(197, 307, kb, pan)])
	_poly(ip, Color(0.55, 0.62, 0.68), a, 3.0)
	for k in 2:
		var hx := 265.0 + k * 75.0
		var hs := 1.0 - k * 0.22
		draw_circle(_p(hx, 230 + k * 12, kb, pan), 22 * hs * kb, Color(0.15, 0.13, 0.12, a))
		_poly(PackedVector2Array([_p(hx - 34 * hs, 318, kb, pan), _p(hx - 26 * hs, 258 + k * 12, kb, pan), _p(hx + 26 * hs, 258 + k * 12, kb, pan), _p(hx + 34 * hs, 318, kb, pan)]), Color(0.15, 0.13, 0.12), a, 2.0)
	draw_line(_p(300, 140, kb, pan), _p(300, 175, kb, pan), Color(0.6, 0.6, 0.62, a), 6.0 * kb)
	# Sağ sayfada el yazısı: kalem satır satır yazar
	var lines := 7
	var written := t * 0.9
	var pen := Vector2.ZERO
	for k in lines:
		var prog := clampf(written - k, 0.0, 1.0)
		if prog <= 0.0:
			break
		var y := 132.0 + k * 32.0
		var len := (300.0 if k < lines - 1 else 170.0) * prog
		var pts := PackedVector2Array()
		var steps := int(len / 6.0) + 2
		for i in steps:
			var x := 530.0 + i * len / float(steps - 1)
			pts.append(_p(x, y + sin(x * 0.21 + k) * 5.0 + sin(x * 0.07) * 2.0, kb, pan))
		draw_polyline(pts, Color(0.1, 0.12, 0.3, a), 2.6, true)
		pen = pts[pts.size() - 1]
	if pen != Vector2.ZERO:
		var tip := pen + Vector2(0, -2) * kb
		_poly(PackedVector2Array([tip, tip + Vector2(30, -70) * kb, tip + Vector2(44, -64) * kb]), Color(0.2, 0.2, 0.25), a, 3.0)
	_caption("SELİM ARSLAN'IN GÜNLÜĞÜ", Vector2(-W / 2 + 24, H / 2 - 74), a, 20)
