extends Node
var f := 0
var level
var stage := "menu"
var wait := 0
var log_steps := []
var qte_tail := 0
var shown_at := 0
var last_txt := ""
var last_txt_f := 0
var tapped_since := false
var problems := []
func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; e.global_position = pos
	Input.parse_input_event(e)
func tap(pos: Vector2) -> void:
	tapped_since = true; _mouse(pos, true); _mouse(pos, false)
func swipe(a: Vector2, b: Vector2) -> void:
	tapped_since = true; _mouse(a, true)
	var m := InputEventMouseMotion.new(); m.position = b; m.global_position = b; m.relative = b - a; m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m); _mouse(b, false)
## Her yazının ekranda kalış süresini ölç; dokunmadan ya da 0.8 sn'den kısa sürede değişenleri kaydet.
func _watch(d) -> void:
	var t: String = d._text_label.text if d._panel.visible else ""
	if t != last_txt:
		var dur := (f - last_txt_f) / 30.0
		if last_txt != "" and t != "" and dur < 0.8:
			problems.append("KISA %.2fs dokunma=%s: '%s' -> '%s'" % [dur, tapped_since, last_txt.substr(0, 40), t.substr(0, 30)])
		if last_txt != "" and t != "" and not tapped_since:
			problems.append("DOKUNMASIZ DEĞİŞTİ (%.2fs): '%s' -> '%s'" % [dur, last_txt.substr(0, 40), t.substr(0, 30)])
		if t != "": shown_at = f; tapped_since = false
		last_txt = t; last_txt_f = f
	if d._panel.visible and d._title.visible and d._title.modulate.a > 0.3:
		problems.append("BAŞLIK+YAZI çakışması: " + d._text_label.text.substr(0, 30))
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	ToonStyle.set_quality("dusuk")
	var boot = load("res://scenes/boot.tscn").instantiate()
	get_tree().root.add_child.call_deferred(boot)
	(func(): get_tree().current_scene = boot).call_deferred()
func note(s): print("[", f, "] ", s); log_steps.append(s)
func _process(_d):
	f += 1
	var cs = get_tree().current_scene
	if cs == null: return
	if stage == "menu" and cs.name == "Boot" and f > 20: cs._show_name_entry(); stage = "isim"; wait = f
	if stage == "isim" and f == wait + 10: cs._name_edit.text = "kerem"; cs._start(); stage = "yukle"
	if stage == "yukle" and cs.name == "Onsoz": level = cs; stage = "giris"; note("yüklendi")
	if stage == "bitis" and cs.name == "Binis": note("BÖLÜM 2'ye geçildi (f=%d)" % f); finish(); return
	if level == null or not is_instance_valid(level) or not level.is_inside_tree():
		if stage == "bitis" and cs.name == "Binis": note("BÖLÜM 2'ye geçildi"); finish()
		return
	var d = level.get_node("DialogUI"); var p = level.get_node("Player"); var txt: String = d._text_label.text
	_watch(d)
	if d.active and d._in_qte and d._qte.active:
		qte_tail = 30
		if d._qte._kind == "vur":
			if f % 3 == 0: tap(Vector2(640, 500))
		elif d._qte._left < d._qte._time - 0.6:
			if d._qte._kind == "bas": tap(Vector2(640, 500))
			else:
				var dirs := {"sol": Vector2(-1, 0), "sag": Vector2(1, 0), "yukari": Vector2(0, -1), "asagi": Vector2(0, 1)}
				swipe(Vector2(640, 500), Vector2(640, 500) + dirs[d._qte._dir] * 220.0)
	elif qte_tail > 0:
		qte_tail -= 1
		if f % 3 == 0: tap(Vector2(640, 500))  # insan parmağı QTE bitince hemen durmaz
	elif d.active and not d._in_qte and not d._waiting:
		if d._choosing:
			if f - shown_at > 45 and d._grid.get_child_count() > 0:
				var pick := 0
				if txt.contains("Caddenin ağzında"): pick = 2
				if txt.contains("Uzakta bir siren"): pick = 1
				var b: Control = d._grid.get_child(mini(pick, d._grid.get_child_count() - 1))
				tap(b.get_global_rect().get_center()); shown_at = f
		elif not d._typing and f - shown_at > 36:
			tap(Vector2(640, 250)); shown_at = f
	match stage:
		"giris":
			if level._phase == "sokak" and not d.active: note("sokak, ihtiyaçlar=%d/%d/%d" % [Story.need("aclik"), Story.need("susuzluk"), Story.need("yorgunluk")]); stage = "araba"; wait = f
		"araba":
			if f == wait + 3: p.global_position = Vector3(2.0, 0.1, 7.0)
			if f == wait + 15: level._start_dialog(level.get_node("Hotspots/Araba"))
			if f > wait + 20 and not d.active: note("araba, çanta=" + str(Story.inventory())); level.use_item("enerji_bari"); stage = "ye"; wait = f
		"ye":
			if f > wait + 150 and not level._using_item: note("yedi, açlık=%d çanta=%s" % [Story.need("aclik"), Story.inventory()]); stage = "arman"; wait = f
		"arman":
			if f == wait + 3: p.global_position = Vector3(2.2, 0.1, 30.2)
			if f == wait + 15: level._start_dialog(level._arman)
			if f > wait + 20 and not d.active: note("Arman, çanta=%s susuzluk=%d" % [Story.inventory(), Story.need("susuzluk")]); level.use_item("su_sisesi"); stage = "ic"; wait = f
		"ic":
			if f > wait + 150 and not level._using_item: note("içti, susuzluk=%d çanta=%s" % [Story.need("susuzluk"), Story.inventory()]); stage = "muhafiz"; wait = f
		"muhafiz":
			if f == wait + 3: p.global_position = Vector3(0.2, 0.1, 56.9)
			if f == wait + 15: level._start_dialog(level._guard)
			if f > wait + 20 and not d.active: note("isyan bitti"); stage = "kacis"; wait = f
		"kacis":
			if f == wait + 60: p.global_position = Vector3(13.0, 0.1, 10.5)
			if level._phase == "sokak_sonu": stage = "sokak"
		"sokak":
			if level._phase == "sokak_sonu" and not level._dialog.active and f % 40 == 0 and level._arman.interactable:
				level.get_node("Player").global_position = level._arman.global_position + Vector3(-1.4, 0.1, 0.2)
				level._start_dialog(level._arman)
			if level._phase == "kart": note("ölüm: " + str(Story.get_var("arman_olum", ""))); stage = "kart"; wait = f
		"kart":
			if f == wait + 40: p.global_position = level._card.global_position + Vector3(-1.0, 0.1, 0.3)
			if f == wait + 55: level._start_dialog(level._card)
			if level._phase == "final": note("final, çanta=%s ceset=%s" % [Story.inventory(), Story.get_var("ceset_yeri", "-")]); stage = "bitis"
	if f > 14000: note("ZAMAN AŞIMI " + stage + " " + str(level._phase)); finish()
func finish():
	print("SONUÇ: ", " | ".join(log_steps))
	for p in problems: print("SORUN: ", p)
	print("SORUN SAYISI: ", problems.size())
	get_tree().quit()
