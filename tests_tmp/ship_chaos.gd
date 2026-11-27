extends Node
## Biniş bölümü kaos testi: rastgele seçimler, rastgele inceleme sırası, kaybedilen QTE'ler, gerçek dokunmalar.
## FULL=1 ise menüden başlar ve önsözü de (önceki e2e mantığıyla) oynar.
var rng := RandomNumberGenerator.new()
var seed_no := 0
var f := 0
var level
var stage := ""
var wait := 0
var last_text := ""
var same := 0
var waiting := 0
var plan := []
var qte_plan := {}
var log_steps := []
var next_at := 0
var pending := false
var noload := false
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed_no = int(OS.get_environment("SEED"))
	rng.seed = seed_no
	plan = ["dunya", "ekran", "yolcu"]; plan.shuffle()
	if noload: return
	ToonStyle.set_quality("dusuk")
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Test"); Story.set_var("cinsiyet", "k" if seed_no % 2 else "e")
	Story.set_var("arman_olum", ["kesici", "bogma", "yalvar"][seed_no % 3]); Story.add_item("kimlik_karti")
	if seed_no % 3 == 0: Story.add_item("kesici")
	var s = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(s)
	(func(): get_tree().current_scene = s).call_deferred()
	plan = ["dunya", "ekran", "yolcu"]; plan.shuffle()
func note(s): log_steps.append(s)
func report(kind):
	print("TAKILMA[", seed_no, "] ", kind, " f=", f, " aşama=", stage, " faz=", level._phase if level else "-", " düğüm=", level._dialog.runner.current_node if level else "-", " metin='", level._dialog._text_label.text.substr(0, 40) if level else "", "' ", log_steps.slice(-5))
	get_tree().quit()
func _mouse(pos: Vector2, pressed: bool):
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; e.global_position = pos
	Input.parse_input_event(e)
func tap(pos: Vector2): _mouse(pos, true); _mouse(pos, false)
func go(id: String) -> bool:
	var n = level._hot.get(id, level._npcs.get(id))
	if n == null or not n.interactable: return false
	var p = level._player
	p.global_position = n.global_position + Vector3(rng.randf_range(-0.3, 0.3), 0.1, rng.randf_range(-0.3, 0.3))
	return true
func _process(_d):
	f += 1
	if f < 10: return
	var cs = get_tree().current_scene
	if cs and cs.name == "Boot":
		print("BİTTİ[", seed_no, "] f=", f, " ", " | ".join(log_steps), " çanta=", Story.inventory(), " bayıldı=", Story.get_var("kalkis_bayildi", "-")); get_tree().quit(); return
	if cs == null or cs.name != "Binis": return
	level = cs
	var d = level._dialog; var p = level._player
	if f % 600 == 0: print("DURUM f=", f, " faz=", level._phase, " aktif=", d.active, " bekle=", d._waiting, " düğüm=", d.runner.current_node, " plan=", plan, " yakın=", level._nearby_npc.start_node if level._nearby_npc else "-", " siyah=", d._fade.color.a, " zaman=", Time.get_ticks_msec() / 1000)
	if level._hud._overlay.visible: report("ÖLDÜN ekranı")
	# --- diyalog sürücüsü (gerçek dokunma)
	if d.active and d._in_qte:
		if d._qte.active:
			if not qte_plan.has(d._qte): qte_plan.clear(); qte_plan[d._qte] = rng.randf() < 0.4
			if not qte_plan[d._qte] and f % 3 == 0: tap(Vector2(640, 500))
	elif d.active and d._waiting:
		waiting += 1
		if waiting > 400: report("@bekle bitmiyor")
	elif d.active:
		waiting = 0
		if d._choosing:
			if f % 11 == 0 and rng.randf() < 0.8 and d._grid.get_child_count() > 0:
				var b: Control = d._grid.get_child(rng.randi_range(0, d._grid.get_child_count() - 1))
				tap(b.get_global_rect().get_center())
		elif f % 7 == 0:
			var t: String = d._text_label.text
			if t == last_text and not d._typing: same += 1
			else: same = 0
			last_text = t
			if same > 40: report("metin ilerlemiyor")
			tap(Vector2(640, 250))
		return
	waiting = 0
	# --- akış (adım adım: önce git, sonra konuş)
	if f > 30000: report("zaman aşımı")
	if f < next_at or level._using_item: return
	if level._phase != stage:
		stage = level._phase
		match stage:
			"iskele": plan = ["dunya", "ekran", "yolcu"]; plan.shuffle(); plan = plan.slice(0, rng.randi_range(0, 3)); plan.append("gorevli")
			"meydan": plan = ["hologram", "bahce", "anit", "kadin"]; plan.shuffle(); plan = plan.slice(0, rng.randi_range(0, 3)); plan.append("asansor")
			"guverte8": plan = ["tabela", "kapi411"]; plan.shuffle(); plan = plan.slice(0, rng.randi_range(0, 2)); plan.append("kapi412"); plan.append("_gir")
			"kamara": plan = ["kutu", "alet", "kayit", "yatak", "pencere"]; plan.shuffle(); plan = plan.slice(0, rng.randi_range(1, 4)); plan.insert(rng.randi_range(0, plan.size()), "erzak")
			_: plan = []
		note("faz:" + stage)
	if stage in ["kamara", "anons"] and level._hot["koltuk"].interactable and not plan.has("koltuk"):
		plan = ["koltuk"]
	if pending:
		pending = false
		if level._nearby_npc:
			note(">" + level._nearby_npc.start_node + (" (aktif!)" if level._dialog.active else ""))
			level._start_dialog(level._nearby_npc)
		next_at = f + 30
		return
	if plan.is_empty():
		# Son nokta kaçırıldıysa (yakın nokta henüz güncellenmemişti) tekrar dene
		if level._nearby_npc and stage in ["iskele", "meydan", "guverte8"]:
			level._start_dialog(level._nearby_npc)
		next_at = f + 30
		return
	var id = plan.pop_front()
	if id == "_gir":
		p.global_position = level.Z2 + Vector3(3.2, 0.1, 7.0); note("kamaraya_gir")
	elif go(id):
		note(id); pending = true
		if stage == "kamara" and rng.randf() < 0.3 and Story.has_item("su_paketi"): level.use_item("su_paketi"); note("su_ic")
	next_at = f + 25
