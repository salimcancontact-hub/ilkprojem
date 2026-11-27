extends Node
## Önsözdeki her QTE'yi (EĞİL, İT, KALDIR, KAÇIN, bilek İT) gerçek dokunma/kaydırmayla oynar,
## QTE sırasında ve sonrasında kare kare fotoğraf çeker. FAIL=1: hepsini kaybet.
var level
var out := OS.get_environment("OUT")
var fail := OS.get_environment("FAIL") == "1"
var n := 0
var tail := 0
var qn := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func _mouse(pos: Vector2, pressed: bool):
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; e.global_position = pos
	Input.parse_input_event(e)
func tap(p: Vector2): _mouse(p, true); _mouse(p, false)
func swipe(a: Vector2, b: Vector2):
	_mouse(a, true)
	var m := InputEventMouseMotion.new(); m.position = b; m.global_position = b; m.relative = b - a; m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m); _mouse(b, false)
func snap(tag):
	var d = level._dialog
	get_viewport().get_texture().get_image().save_png(out + "/qf_%s%03d.png" % ["f" if fail else "", n]); print("foto %03d %s düğüm=%s qte=%s ts=%.2f" % [n, tag, d.runner.current_node, d._in_qte, Engine.time_scale]); n += 1
func _run():
	var d = level._dialog
	var stage := "giris"
	var wait := 0
	var qstart := 0
	for i in 30000:
		await get_tree().process_frame
		var p = level._player
		if d._in_qte and d._qte.active:
			if tail == 0:
				qn += 1; qstart = i
				print("QTE%d oyuncu=%s arman=%s arman_görünür=%s kamera=%s model=%s" % [qn, p.global_position, level._arman.global_position, level._arman.visible, get_viewport().get_camera_3d().global_position, level._arman.model.global_position])
			tail = 40
			if i % 4 == 0: snap("Q%d" % qn)
			var q = d._qte
			var real_left: float = q._left
			if not fail:
				if q._kind == "vur":
					if i % 3 == 0: tap(Vector2(640, 500))
				elif q._kind == "kaydir" and i - qstart > 8 and i % 10 == 0:
					var dirs := {"sol": Vector2(-1, 0), "sag": Vector2(1, 0)}
					swipe(Vector2(640, 500), Vector2(640, 500) + dirs[q._dir] * 250.0)
			continue
		if tail > 0:
			tail -= 1
			if tail % 5 == 0: snap("sonra%d" % qn)
		if d.active and not d._in_qte and not d._waiting and i % 8 == 0:
			d._block_input = 0
			if d._choosing:
				var pick := 0
				if d._text_label.text.contains("Caddenin ağzında"): pick = 2
				d._pick(pick)
			else: d._finish_typing(); d._advance()
		match stage:
			"giris":
				if level._phase == "sokak" and not d.active: stage = "muhafiz"; wait = i
			"muhafiz":
				if i == wait + 5: p.global_position = Vector3(0.2, 0.1, 56.9)
				if i == wait + 15:
					Story.set_var("gorev_muhafiz", true); level._start_dialog(level._guard)
				if i == wait + 30: snap("muhafiz_konusma")
				if i > wait + 30 and not d.active: stage = "kacis"; wait = i
			"kacis":
				if i == wait + 30: p.global_position = Vector3(13.0, 0.1, 10.5)
				if level._phase == "sokak_sonu" and level._arman.interactable and not d.active:
					p.global_position = level._arman.global_position + Vector3(-1.4, 0.1, 0.2)
					await get_tree().create_timer(0.3).timeout
					level._start_dialog(level._arman); stage = "sokak"
			"sokak":
				if qn >= 5 and tail == 0: break
		if level._phase == "kart" and tail == 0: break
	print("BİTTİ qte sayısı=", qn)
	get_tree().quit()
