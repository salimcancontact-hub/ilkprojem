extends Node
var f := 0
var level
var stage := "menu"
var wait := 0
var log_steps := []
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
	if stage == "bitis" and cs.name == "Binis":
		note("BÖLÜM 2 yüklendi, çanta=" + str(Story.inventory()) + " cinsiyet=" + str(Story.get_var("cinsiyet", "?")))
		var drv = load("res://tests_tmp/ship_chaos.gd").new()
		drv.noload = true
		add_child(drv)
		stage = "bolum2"; level = null
		return
	if stage == "bolum2":
		if cs.name == "Boot": note("MENÜYE DÖNÜLDÜ, kayıt=" + str(Game.has_checkpoint())); finish()
		if f > 40000: note("ZAMAN AŞIMI bölüm 2"); finish()
		return
	if level == null or not is_instance_valid(level) or not level.is_inside_tree():
		return
	var d = level.get_node("DialogUI"); var p = level.get_node("Player"); var txt: String = d._text_label.text
	if d.active and d._in_qte and d._qte.active:
		if d._qte._kind == "vur":
			if f % 3 == 0: d._qte._hit()
		elif d._qte._left < d._qte._time - 0.6: d._qte._end(true)
	elif d.active and not d._in_qte and not d._waiting and f % 7 == 0:
		d._block_input = 0
		if d._choosing:
			var pick := 0
			if txt.contains("Caddenin ağzında"): pick = 2
			if txt.contains("Uzakta bir siren"): pick = 1
			d._pick(pick)
		else: d._finish_typing(); d._advance()
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
	if f > 20000: note("ZAMAN AŞIMI " + stage + " " + str(level._phase)); finish()
func finish(): print("SONUÇ: ", " | ".join(log_steps)); get_tree().quit()
