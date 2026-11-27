extends Node
## Kaos testi: rastgele seçimler/QTE sonuçları/süre aşımları ile oyunu oynar, takılmaları raporlar.
var rng := RandomNumberGenerator.new()
var level
var f := 0
var stage := "giris"
var wait := 0
var last_text := ""
var same_text := 0
var black := 0
var locked := 0
var waiting := 0
var qte_dead := 0
var nodes := []
var seed_no := 0
var died := false
var qte_plan := {}
var qte_seen := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed_no = int(OS.get_environment("SEED"))
	rng.seed = seed_no
	ToonStyle.set_quality("dusuk")
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Test")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)


func tap(pos: Vector2) -> void:
	_mouse(pos, true)
	_mouse(pos, false)


func swipe(a: Vector2, b: Vector2) -> void:
	_mouse(a, true)
	var m := InputEventMouseMotion.new()
	m.position = b; m.global_position = b; m.relative = b - a; m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m)
	_mouse(b, false)


func report(kind):
	print("İzleyici kaydı: ", FileAccess.get_file_as_string(Game.BOOT_LOG).split("\n").slice(-4))
	print("TAKILMA[", seed_no, "] ", kind, " f=", f, " aşama=", stage, " faz=", level._phase, " düğüm=", level._dialog.runner.current_node, " metin='", level._dialog._text_label.text.substr(0, 50), "' son düğümler=", nodes.slice(maxi(nodes.size() - 6, 0)))
	get_tree().quit()
func _process(_d):
	f += 1
	if f < 10: return
	var cs = get_tree().current_scene
	if f % 300 == 0: print("SAHNE f=", f, " ", cs.name if cs else "YOK", " level_geçerli=", is_instance_valid(level), " ağaçta=", is_instance_valid(level) and level.is_inside_tree(), " faz=", level._phase if is_instance_valid(level) else "-", " siyah=", level._dialog._fade.color.a if is_instance_valid(level) else -1)
	if cs and (cs.name == "Boot" or cs.name == "Binis"):
		print("BİTTİ[", seed_no, "] f=", f, " ölüm=", Story.get_var("arman_olum", ""), " qte_ölüm=", died, " ceset=", Story.get_var("ceset_yeri", "-"), " düğüm sayısı=", nodes.size()); get_tree().quit(); return
	if not is_instance_valid(level) or not level.is_inside_tree(): return
	var d = level._dialog; var p = level.get_node("Player")
	var node = d.runner.current_node
	if f % 600 == 0: print("DURUM f=", f, " aşama=", stage, " faz=", level._phase, " aktif=", d.active, " düğüm=", node, " metin='", d._text_label.text.substr(0, 30), "' panel=", d._panel.visible, " bekle=", d._waiting, " qte=", d._in_qte)
	if nodes.is_empty() or nodes[-1] != node: nodes.append(node)
	# --- sür (gerçek dokunma olaylarıyla)
	if d.active and d._in_qte:
		if d._qte.active:
			qte_dead = 0
			if not qte_plan.has(d._qte):
				qte_plan.clear(); qte_plan[d._qte] = rng.randf() < 0.4
			var want_fail: bool = qte_plan[d._qte] and d._qte._time < 5.5
			var c := Vector2(640, 500)
			if d._qte._kind == "vur":
				if not want_fail and f % 3 == 0: tap(c)
			elif d._qte._left < d._qte._time * 0.5 and not want_fail and f % 4 == 0:
				if d._qte._kind == "bas": tap(c)
				else:
					var dirs := {"sol": Vector2(-1, 0), "sag": Vector2(1, 0), "yukari": Vector2(0, -1), "asagi": Vector2(0, 1)}
					swipe(c, c + dirs[d._qte._dir] * 220.0)
		else:
			qte_dead += 1
			if d._title.text == "ÖLDÜN": died = true
			qte_plan.clear()
			if qte_dead > 200: report("QTE sonucu gelmiyor")
	elif d.active and d._waiting:
		waiting += 1
		if waiting > 300: report("@bekle bitmiyor")
	elif d.active:
		waiting = 0
		if d._choosing:
			if f % 9 == 0 and rng.randf() < 0.85 and d._grid.get_child_count() > 0:
				var b: Control = d._grid.get_child(rng.randi_range(0, d._grid.get_child_count() - 1))
				tap(b.get_global_rect().get_center())
		elif f % 7 == 0:
			var t: String = d._text_label.text
			if t == last_text and not d._typing: same_text += 1
			else: same_text = 0
			last_text = t
			if same_text > 25: report("metin ilerlemiyor (dokunma işlemiyor)")
			tap(Vector2(640, 250))
	else:
		waiting = 0
		if d._fade.color.a > 0.9 and level._phase != "final": black += 1
		else: black = 0
		if black > 150: report("siyah ekranda kaldı")
		if not p.input_enabled and not level._using_item and level._phase != "final": locked += 1
		else: locked = 0
		if locked > 150: report("oyuncu kilitli kaldı")
	# --- ilerle
	match stage:
		"giris":
			if level._phase == "sokak" and not d.active: stage = "gez"; wait = f
		"gez":
			if f == wait + 5:
				var spots = ["Su", "Araba", "Grafiti", "Liste", "Terminal"]
				spots.shuffle()
				p.global_position = level.get_node("Hotspots/" + spots[0]).global_position + Vector3(0.8, 0.1, 0)
			if f == wait + 15 and level._nearby_npc: level._start_dialog(level._nearby_npc)
			if f > wait + 20 and not d.active: stage = "arman"; wait = f
		"arman":
			if f == wait + 3: p.global_position = Vector3(2.2, 0.1, 30.2)
			if f == wait + 15: level._start_dialog(level._arman)
			if f > wait + 20 and not d.active:
				if Story.has_item("su_sisesi") and rng.randf() < 0.5: level.use_item("su_sisesi")
				stage = "muhafiz"; wait = f
		"muhafiz":
			if f == wait + 60: p.global_position = Vector3(0.2, 0.1, 56.9)
			if f == wait + 75: level._start_dialog(level._guard)
			if f > wait + 80 and not d.active: stage = "kacis"; wait = f
		"kacis":
			# Yarısında gerçekten yürü, yarısında ışınlan
			if rng.randf() < 0.002 or f > wait + 600:
				p.global_position = Vector3(12.5, 0.1, 10.5)
			elif f > wait + 30:
				var to: Vector3 = Vector3(12.5, 0, 10.5) - p.global_position; to.y = 0
				var cb: Basis = p._camera_pivot.global_basis
				var fw: Vector3 = -cb.z; fw.y = 0; fw = fw.normalized()
				var rt: Vector3 = cb.x; rt.y = 0; rt = rt.normalized()
				var v: Vector3 = to.normalized()
				p.move_input = Vector2(v.dot(rt), -v.dot(fw))
			if level._phase != "isyan": p.move_input = Vector2.ZERO; stage = "sokak"
		"sokak":
			if level._phase == "sokak_sonu" and not level._dialog.active and f % 40 == 0 and level._arman.interactable:
				level.get_node("Player").global_position = level._arman.global_position + Vector3(-1.4, 0.1, 0.2)
				level._start_dialog(level._arman)
			if level._phase == "kart": stage = "kart"; wait = f
		"kart":
			if f == wait + 60: p.global_position = level._card.global_position + Vector3(-1.0, 0.1, 0.3)
			if f == wait + 75:
				if level._nearby_npc == level._card: level._start_dialog(level._card)
				else: report("kart incelenemiyor (yakın=" + str(level._nearby_npc) + ", etkileşim=" + str(level._card.interactable) + ")")
	if f > 9000: report("zaman aşımı")
