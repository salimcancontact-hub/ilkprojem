extends GameLevel
## Bölüm 2: "Biniş" — Yörünge İskelesi, Halka Meydanı, asansör, Güverte 8, Kamara 412, kalkış.

const DLG := "res://dialogs/binis.dlg"
const MENU_SCENE := "res://scenes/boot.tscn"
const Z2 := GemiSet.ZONE2

var _z1: Dictionary
var _z2: Dictionary
var _z3: Dictionary  # köprü
var _z4: Dictionary  # dış çekim
var _z5: Dictionary  # yörüngeye tırmanış
var _phase: String = "baslangic"
var _loading: CanvasLayer
var _npcs: Dictionary = {}
var _hot: Dictionary = {}
var _card_hold: Node3D
var _card: Node3D
var _wrist: Node3D
var _frame: Node3D
var _riding: bool = false
var _inspected: Dictionary = {}
var _cabin_time: float = 0.0
var _launch_t: float = 2400.0  # kalkışa kalan saniye (kamara saati)
var _holo_t: float = 0.0
var _deniz_holo: HoloCall
var _seat_cam_target: Vector3


func _ready() -> void:
	# Önce siyah ekranda "Yükleniyor" çizilsin (donmuş gri ekran yerine), sonra set kurulsun.
	_dialog.fade_to(1.0, 0.0)
	cinematic_hold = true  # yükleme uzun sürerse gözetçi "siyah ekran" sanıp açmasın
	var loading := LoadingOverlay.show_on(self, "Gemiye biniliyor")
	await get_tree().process_frame
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	# Set ve karakterler, GameLevel sinyallerini bağlamadan önce kurulur.
	_z1 = GemiSet.build_zone1(self)
	_z2 = GemiSet.build_zone2(self)
	_z3 = GemiSet.build_bridge(self)
	var t1 := Time.get_ticks_msec()
	_spawn_people()
	_spawn_hotspots()
	Game.boot_log("gemi seti %d ms, karakterler %d ms" % [t1 - t0, Time.get_ticks_msec() - t1])
	super()
	_loading = loading
	live_world = true  # gemi canlı: konuşurken de insanlar, hologram, kabin hareket eder
	_player.face_point(Vector3(8, 0, 20))
	camera_shots = {
		"iskele": [Vector3(15.0, 3.4, -0.6), Vector3(6.5, 1.4, 8.5), true],
		"koltuk": [Z2 + Vector3(6.9, 1.45, 6.1), Z2 + Vector3(5.0, 1.0, 7.05), true],
		"pencere": [Z2 + Vector3(5.3, 1.35, 8.65), Z2 + Vector3(6.4, 1.2, 6.9), true],
		"yuz": [Z2 + Vector3(6.0, 1.3, 7.25), Z2 + Vector3(5.0, 1.15, 7.0), true],
		# Köprü ve dış çekim
		"kopru": [GemiSet.ZONE3 + Vector3(3.6, 2.5, -3.4), GemiSet.ZONE3 + Vector3(0, 1.3, 2.2), true],
		"reyes": [GemiSet.ZONE3 + Vector3(0.7, 1.75, 2.0), GemiSet.ZONE3 + Vector3(0.0, 1.6, 0.4), true],
		"pilot": [GemiSet.ZONE3 + Vector3(-1.45, 1.45, 2.2), GemiSet.ZONE3 + Vector3(-2.6, 1.3, 1.65), true],
		"dis": [GemiSet.ZONE4 + Vector3(330, 18, 300), GemiSet.ZONE4 + Vector3(0, 80, -60), true],
		# Bölge 1 incelemeleri
		"c_dunya": [Vector3(-0.6, 1.7, 6.5), Vector3(-80.0, 28.0, -90.0), true],
		"c_ekran": [Vector3(14.2, 2.0, 2.8), Vector3(17.4, 2.2, 4.5), true],
		"c_hologram": [Vector3(8.0, 2.3, 15.0), Vector3(8.0, 2.4, 20.0), true],
		"c_bahce": [Vector3(14.6, 1.8, 15.0), Vector3(17.5, 1.1, 17.4), true],
		"c_anit": [Vector3(14.8, 1.9, 22.4), Vector3(17.8, 1.7, 24.8), true],
		"c_kart": [Vector3(4.3, 1.75, 7.5), Vector3(6.1, 1.15, 9.1), true],
		"c_kapi": [Vector3(8.0, 2.3, 4.6), Vector3(8.0, 1.6, 12.0), true],
		"c_asansor_dis": [Vector3(8.0, 2.0, 22.4), Vector3(8.0, 1.4, 27.6), true],
		# Bölge 2
		"c_tabela": [Z2 + Vector3(0.7, 1.7, 2.6), Z2 + Vector3(-1.6, 1.6, 0.9), true],
		"c_411": [Z2 + Vector3(0.9, 1.7, 4.9), Z2 + Vector3(-1.6, 1.6, 7.0), true],
		"c_kapi412": [Z2 + Vector3(-1.0, 1.8, 4.4), Z2 + Vector3(1.6, 1.2, 7.0), true],
		"c_kamara": [Z2 + Vector3(7.2, 2.3, 5.5), Z2 + Vector3(3.0, 0.9, 8.0), true],
		"c_pencere": [Z2 + Vector3(4.6, 1.65, 7.6), Z2 + Vector3(7.7, 1.3, 6.9), true],
		"c_yatak": [Z2 + Vector3(2.5, 1.8, 6.0), Z2 + Vector3(4.6, 0.6, 8.4), true],
		"c_kutu": [Z2 + Vector3(7.25, 1.6, 6.5), Z2 + Vector3(6.2, 0.6, 8.3), true],
		"c_masa": [Z2 + Vector3(6.6, 1.6, 7.3), Z2 + Vector3(5.0, 0.9, 5.4), true],
		"c_alet": [Z2 + Vector3(5.2, 1.7, 7.4), Z2 + Vector3(6.9, 0.3, 5.5), true],
		"c_kayit": [Z2 + Vector3(6.6, 1.5, 6.0), Z2 + Vector3(5.0, 1.2, 5.3), true],
		"c_erzak": [Z2 + Vector3(3.95, 1.6, 6.2), Z2 + Vector3(2.6, 1.2, 5.2), true],
	}
	_dialog.fade_to(1.0, 0.0)
	_set_zone(2, true)
	_set_zone(3, true)
	(_z2["earth"] as Node3D).visible = true
	await get_tree().process_frame
	await _prewarm()
	if _loading:
		(_loading as LoadingOverlay).finish(0.6)  # ilk çizim ve gölgelendirici derlemesi bitti
	(_z2["earth"] as Node3D).visible = false
	_set_zone(2, false)
	_set_zone(3, false)
	Story.set_var("bolum", "binis")
	cinematic_hold = false
	await play_dialog(DLG, "giris")
	_phase = "iskele"


func _process(delta: float) -> void:
	super(delta)
	if _z3.is_empty():
		return  # set henüz kuruluyor
	var holo: Node3D = _z1.get("ship_holo")
	if holo and _z1["root"].visible:
		holo.rotation.y += delta * 0.35
	if _riding or _cab_cam:
		_follow_cab()
	if _phase == "kamara":
		_cabin_time += delta
		if _cabin_time > 75.0 and not _dialog.active and not _using_item:
			_announce()
	# Kamara saati
	if _z2["root"].visible:
		_launch_t = maxf(_launch_t - delta * (12.0 if _phase in ["kamara", "anons"] else 1.0), 0.0)
		var s := int(_launch_t)
		(_z2["clock"] as Label3D).text = "KALKIŞ  T-%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
		_holo_t += delta
		var tt: Label3D = _z2["terminal_text"]
		if Story.get_var("deniz_kaydi", "") == "":
			tt.modulate.a = 0.55 + 0.45 * sin(_holo_t * 4.0)


# --- Kurulum -------------------------------------------------------------------

func _npc(id: String, model_path: String, pos: Vector3, yaw: float, start: String, idle: String = "Idle", interact: bool = true) -> Npc:
	var n: Npc = load("res://scenes/npc.tscn").instantiate()
	n.npc_id = id
	n.dialog_path = DLG
	n.start_node = start
	n.model_scene = load(model_path)
	n.idle_animation = idle
	n.interactable = interact
	n.position = pos
	add_child(n)
	n.get_node("Visual").rotation.y = yaw
	return n


func _spawn_people() -> void:
	var C := "res://scenes/characters/"
	_npcs["gorevli"] = _npc("GOREVLI", C + "muhafiz_model.tscn", Vector3(10.2, 0, 8.6), 0.0, "kapi")
	_npcs["gorevli"].prompt = "KARTI OKUT"
	_npcs["yolcu"] = _npc("YOLCU", C + "kalabalik/c3_model.tscn", Vector3(2.2, 0, 5.2), -PI / 2, "yolcu")
	_npcs["selim"] = _npc("SELIM", C + "yasli_model.tscn", Vector3(9.9, 0, 26.2), PI, "asansor", "Idle_FoldArms", false)
	# Köprüde uçuş ekibi (kalkışta görünür)
	var Z3 := GemiSet.ZONE3
	_crew("REYES", C + "deniz_model.tscn", Z3 + Vector3(0.0, 0, 0.4), PI, "Idle_FoldArms", false)
	_crew("PILOT", C + "deniz_k_model.tscn", Z3 + Vector3(-2.6, 0.02, 2.02), PI, "Sitting_Idle", true)
	_crew("SUBAY", C + "kalabalik/c4_model.tscn", Z3 + Vector3(2.6, 0.02, 2.02), PI, "Sitting_Idle", true)
	# Arkadaki kuyruk ve meydandaki kalabalık (konuşulmaz, sadece canlı)
	var extras := [
		["c1", Vector3(7.6, 0, 0.2), PI, "Idle"], ["c2", Vector3(8.4, 0, -0.8), PI, "Idle_FoldArms"],
		["c5", Vector3(7.9, 0, -1.0), PI, "Idle"],
		["c4", Vector3(11.5, 0, 16.5), PI / 2, "Idle_Talking"], ["c6", Vector3(10.4, 0, 16.6), -PI / 2, "Idle"],
		["c7", Vector3(4.6, 0, 22.0), 0.3, "Idle"], ["c8", Vector3(15.5, 5.0, 21.0), PI / 2, "Idle_Rail"],
	]
	for e in extras:
		var m: CharacterModel = load(C + "kalabalik/%s_model.tscn" % e[0]).instantiate()
		m.start_animation = e[3]
		add_child(m)
		m.position = e[1]
		m.rotation.y = e[2]
		if e[0] in ["c5", "c7"]:
			m.add_to_group("detay")


var _crew_models: Dictionary = {}


func _crew(id: String, path: String, pos: Vector3, yaw: float, anim: String, seated: bool) -> void:
	var m: CharacterModel = load(path).instantiate()
	m.start_animation = anim
	add_child(m)
	m.position = pos
	m.rotation.y = yaw
	if seated:
		m.process_mode = Node.PROCESS_MODE_ALWAYS
	_crew_models[id] = m


const MARKERS := {
	"dunya": Vector3(-1.9, 2.2, 3.5), "ekran": Vector3(17.35, 2.9, 4.5), "hologram": Vector3(8, 3.4, 20),
	"bahce": Vector3(17.3, 2.9, 17.0), "anit": Vector3(17.7, 2.9, 24.2), "asansor": Vector3(5.9, 1.45, 26.5),
}
const MARKERS_Z2 := {
	"tabela": Vector3(-1.5, 2.15, 0.9), "kapi411": Vector3(-1.5, 2.15, 7.0), "kapi412": Vector3(1.48, 1.5, 6.05),
	"pencere": Vector3(7.55, 1.6, 7.0), "yatak": Vector3(3.75, 0.85, 8.3), "kutu": Vector3(6.4, 0.62, 8.4),
	"kayit": Vector3(5.2, 1.75, 5.1), "alet": Vector3(6.9, 0.3, 5.45), "erzak": Vector3(2.7, 1.62, 5.35),
	"koltuk": Vector3(5.0, 1.0, 7.0),
}


func _hotspot(id: String, pos: Vector3, start: String, prompt: String = "İNCELE", focus: float = 1.3, radius: float = 1.2, anim: String = "") -> Npc:
	var n: Npc = load("res://scenes/npc.tscn").instantiate()
	if MARKERS.has(id):
		n.marker_at = MARKERS[id]
	elif MARKERS_Z2.has(id):
		n.marker_at = Z2 + MARKERS_Z2[id]
	n.npc_id = "IPUCU"
	n.dialog_path = DLG
	n.start_node = start
	n.prompt = prompt
	n.focus_height = focus
	n.inspect_anim = anim
	n.collision_layer = 0
	n.position = pos
	add_child(n)
	var cs: CollisionShape3D = n.get_node("TalkArea/CollisionShape3D")
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 2.0
	cs.shape = sh
	_hot[id] = n
	return n


func _spawn_hotspots() -> void:
	_hotspot("ekran", Vector3(16.7, 0, 4.5), "ipucu_ekran", "İNCELE", 2.0, 1.5)
	_hotspot("hologram", Vector3(8, 0, 17.6), "ipucu_hologram", "İNCELE", 2.4, 1.4)
	_hotspot("bahce", Vector3(16.6, 0, 17.0), "ipucu_bahce", "İNCELE", 1.2, 1.4)
	_hotspot("anit", Vector3(16.7, 0, 24.4), "ipucu_anit", "İNCELE", 1.5, 1.4)
	_hotspot("asansor", Vector3(6.4, 0, 25.8), "asansor", "ASANSÖR", 1.2, 1.3)
	_hotspot("tabela", Z2 + Vector3(-0.9, 0, 0.9), "ipucu_tabela", "İNCELE", 1.6, 1.0)
	_hotspot("kapi411", Z2 + Vector3(-0.9, 0, 7.0), "ipucu_411", "İNCELE", 1.6, 0.9)
	_hotspot("kapi412", Z2 + Vector3(0.9, 0, 6.6), "kamara_kapi", "KAPIYI AÇ", 1.3, 0.9)
	_hotspot("pencere", Z2 + Vector3(7.1, 0, 7.0), "ipucu_pencere", "BAK", 1.5, 0.75)
	_hotspot("yatak", Z2 + Vector3(4.0, 0, 7.75), "ipucu_yatak", "İNCELE", 0.7, 0.8)
	_hotspot("kutu", Z2 + Vector3(6.2, 0, 7.95), "esya_kutu", "AÇ", 0.5, 0.75)
	_hotspot("kayit", Z2 + Vector3(5.2, 0, 6.05), "esya_kayit", "İNCELE", 1.3, 0.8)
	_hotspot("alet", Z2 + Vector3(6.85, 0, 6.0), "esya_alet", "İNCELE", 0.3, 0.7)
	_hotspot("erzak", Z2 + Vector3(2.7, 0, 5.85), "erzak", "AÇ", 1.25, 0.8)
	_hotspot("koltuk", Z2 + Vector3(4.2, 0, 7.0), "koltuk", "OTUR", 0.9, 0.9)
	for id in ["kapi412", "pencere", "yatak", "kutu", "kayit", "alet", "erzak", "koltuk"]:
		_hot[id].interactable = false
	# Tetikleyiciler
	_trigger(Vector3(8, 1, 12.6), Vector3(16, 2, 1.5), _on_atrium)
	_trigger(Z2 + Vector3(4.6, 1, 7.0), Vector3(4.6, 2, 3.4), _on_cabin)


func _trigger(pos: Vector3, size: Vector3, cb: Callable) -> void:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	a.position = pos
	add_child(a)
	a.body_entered.connect(func(b: Node3D) -> void:
		if b is Player:
			cb.call())


func _set_zone(zone: int, on: bool) -> void:
	var r: Node3D = [_z1, _z2, _z3][zone - 1]["root"]
	r.visible = on


## Birbirine yakın inceleme noktalarında en yakındakini seç.
## Açılış konuşması bitmeden etkileşim yok (yoksa açılış yarıda kalır, ekran siyah kalır).
func _start_dialog(npc: Npc) -> void:
	if _phase == "baslangic" or _dialog.active:
		return
	super(npc)


func _on_npc_nearby(_npc_ref: Npc, _is_near: bool) -> void:
	refresh_interactions()


func refresh_interactions() -> void:
	_nearby_npc = null
	var best := 1e9
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc.interactable and npc.visible and npc.is_player_near():
			var d := npc.global_position.distance_to(_player.global_position)
			if d < best:
				best = d
				_nearby_npc = npc
	_hud.set_talk_available(_nearby_npc != null, _nearby_npc.prompt if _nearby_npc else "KONUŞ")


func _physics_process(_delta: float) -> void:
	# Hareket ettikçe en yakın noktayı güncelle (alanlar iç içe)
	if not _dialog.active and Engine.get_physics_frames() % 6 == 0:
		refresh_interactions()


# --- Ön ısıtma -------------------------------------------------------------------

func _prewarm() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var holder := Node3D.new()
	add_child(holder)
	holder.global_transform = cam.global_transform.translated_local(Vector3(0, 0, -2.0))
	var items: Array[Node3D] = [Props.card(), Props.wrist_screen(), Props.cutter(), Props.water_bottle(), Props.energy_bar(), _make_frame()]
	var x := -0.6
	for it in items:
		holder.add_child(it)
		it.position = Vector3(x, 0, 0)
		x += 0.22
	var holo := HoloCall.new()
	holo.caller_scene = load("res://scenes/characters/arman_model.tscn")
	holo.caller_name = "TEST"
	holder.add_child(holo)
	holo.position = Vector3(0.7, -0.2, 0)
	# Bölge 2'yi de bir kez kameranın önünde çiz
	var saved := cam.global_transform
	for k in 4:
		await get_tree().process_frame
	cam.global_transform = Transform3D(Basis.looking_at(Vector3(1, -0.1, 0.3)), Z2 + Vector3(2.5, 1.5, 6.5))
	for k in 4:
		await get_tree().process_frame
	cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, -0.1, 1)), Z2 + Vector3(0, 1.6, 0))
	for k in 3:
		await get_tree().process_frame
	# Köprü ve kamara penceresindeki Dünya / kalkış bulutları
	cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, -0.1, 1)), GemiSet.ZONE3 + Vector3(0, 1.8, -3.0))
	for k in 3:
		await get_tree().process_frame
	for c: Node3D in _z2["ascent_clouds"]:
		c.visible = true
	(_z2["earth"] as Node3D).visible = true
	cam.global_transform = Transform3D(Basis.looking_at(Vector3(1, -0.4, 0)), Z2 + Vector3(5.0, 1.2, 7.0))
	for k in 3:
		await get_tree().process_frame
	# Ön ısıtma bitti: kalkış bulutları ve Dünya gizlenir (gemi yerdeyken pencerede yok)
	for c: Node3D in _z2["ascent_clouds"]:
		c.visible = false
	for k in 3:
		await get_tree().process_frame
	cam.global_transform = saved
	holder.queue_free()


# --- Hikâye olayları --------------------------------------------------------------

func _on_story_event(event_name: String, args: PackedStringArray) -> void:
	match event_name:
		# İskele: kart okutma
		"kart_cikar":
			# Okuyucunun önündeki işarete yürür, sonra kartı cebinden çıkarır
			var rp: Vector3 = _z1["reader_point"].global_position
			busy += 1
			await walk_to(Vector3(rp.x + 0.1, 0, rp.z - 0.5), rp)
			_card = Props.card()
			_player.model.attach(_card, "hand_r", Vector3(0, 0.08, 0.03), Vector3(0.3, 0, 0))
			# Kartı göğüs hizasına kaldırıp bakar (ekranda görünsün)
			if _card_hold == null:
				_card_hold = Node3D.new()
				add_child(_card_hold)
			var fwd := (rp - _player.global_position)
			fwd.y = 0
			_card_hold.global_position = _player.global_position + Vector3(0, 1.2, 0) + fwd.normalized() * 0.3
			_player.model.reach("r", _card_hold, 0.45)
			await get_tree().create_timer(0.5, true, false, true).timeout
			busy -= 1
		"kart_okut":
			_player.model.reach("r", _z1["reader_point"], 0.5)
			_beep(_z1["reader_light"], Color(0.35, 0.8, 1.0))
		"kart_geri":
			_player.model.release("r", 0.5)
		"okuyucu_kirmizi":
			_reader_state(Color(1.0, 0.2, 0.15), "isik_kirmizi", "KART OKUNAMADI")
			shake(0.04, 0.2)
		"gorevli_bak":
			var g: Npc = _npcs["gorevli"]
			g.face_point(_player.global_position)
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(g, "global_position", g.global_position.lerp(_player.global_position, 0.25), 0.8)
			g.model.play("Walk", 0.15)
			tw.tween_callback(func() -> void: g.model.play("Idle_FoldArms", 0.3))
		"okuyucu_yesil":
			_reader_state(Color(0.3, 1.0, 0.5), "isik_yesil", "DENİZ ARMAN\nKAMARA 412 · GÜVERTE 8")
		"kart_cebe":
			_player.model.release("r", 0.4)
			await _pocket(_card)
			_card = null
		"kol_ekrani_ver":
			var g: Npc = _npcs["gorevli"]
			_wrist = Props.wrist_screen()
			g.model.attach(_wrist, "hand_r", Vector3(0, 0.07, 0.04))
			var mid := _point((g.global_position + _player.global_position) / 2.0 + Vector3(0, 1.15, 0))
			g.model.reach("r", mid, 0.6)
			_hand_point = mid
		"kol_ekrani_al":
			var g: Npc = _npcs["gorevli"]
			if _hand_point:
				_player.model.reach("r", _hand_point, 0.45)
				await _wait(0.5)
			if _wrist:
				g.model.detach(_wrist)
				_player.model.attach(_wrist, "hand_l", Vector3(0, 0.0, 0.0), Vector3(0, 0, 0))
				_wrist.position = Vector3(0.0, -0.06, 0.02)
			g.model.release("r", 0.5)
			_player.model.release("r", 0.6)
		"kapi_ac":
			_open_gate()
		# Meydan
		"anit_yaz":
			_player.face_point(_z1["memorial_point"].global_position)
			_player.model.reach("r", _z1["memorial_point"], 0.5)
			await _wait(1.0)
			var txt := "Deniz Arman\niçin." if Story.get_var("anit_not", "") != "ada" else "Ada\niçin."
			if args.size() == 0:
				var l := GemiSet.label(_z1["root"], _z1["memorial_point"].position + Vector3(0.05, 0, 0), "", 26, Color(1, 0.95, 0.8), -PI / 2, 0.0028)
				l.text = txt
				_memorial_label = l
			_player.model.release("r", 0.5)
		"pencereye_yaslan":
			_player.global_position = Vector3(-0.3, _player.global_position.y, 20.6)
			_player.face_point(Vector3(-10, 0, 20.6))
			_player.model.play("Idle_Rail", 0.4)
		"yaslanma_bitti":
			_player.model.play("Idle", 0.4)
		# Asansör
		"asansor_bin":
			await _board_elevator()
		"ekran_goster":
			var p := _point(_player.global_position + _player_fwd() * 0.35 + Vector3(0, 1.3, 0))
			_player.model.reach("l", p, 0.5)
		"ekran_indir":
			_player.model.release("l", 0.5)
		"asansor_dur":
			_riding_stop()
		"asansor_in":
			await _arrive_deck8()
		# Güverte 8 / kamara
		"bilek_okut":
			_player.face_point(_z2["door_panel_point"].global_position)
			_player.model.reach("l", _z2["door_panel_point"], 0.5)
			await _wait(0.7)
			(_z2["door_panel"] as MeshInstance3D).material_override = GemiSet.mat("isik_yesil")
			_player.model.release("l", 0.5)
		"kamara_kapi_ac":
			var door: Node3D = _z2["cabin_door"]
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(door, "position:z", 8.25, 0.9).set_trans(Tween.TRANS_SINE)
			_hot["kapi412"].set_interactable(false)
			for b in door.find_children("*", "StaticBody3D", true, false):
				(b as StaticBody3D).collision_layer = 0
		"kutu_ac":
			_player.face_point(_z2["crate_lid"].global_position)
			_player.model.play("Crouch_Idle", 0.25)
			_player.model.reach("r", _z2["crate_lid"], 0.4)
			await _wait(0.4)
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(_z2["crate_lid"], "rotation:x", deg_to_rad(105), 0.8).set_trans(Tween.TRANS_SINE)
			await _wait(0.5)
			_player.model.release("r", 0.4)
		"cerceve_al":
			_frame = _make_frame()
			add_child(_frame)
			_frame.global_position = _z2["crate_inside"].global_position
			_player.model.reach("r", _frame, 0.45)
			await _wait(0.5)
			_player.model.attach(_frame, "hand_r", Vector3(0, 0.08, 0.05), Vector3(0, 0, PI / 2))
			_player.model.release("r", 0.3)
			_player.model.play("Idle", 0.3)
			var look := _point(_player.global_position + _player_fwd() * 0.32 + Vector3(0, 1.3, 0))
			_player.model.reach("r", look, 0.6)
		"cerceve_masaya", "cerceve_kapat":
			await _place_frame(_z2["desk_spot"].global_position, event_name == "cerceve_kapat")
		"cerceve_kutuya":
			await _place_frame(_z2["crate_inside"].global_position, false, true)
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(_z2["crate_lid"], "rotation:x", 0.0, 0.7)
		"kesici_yuvaya":
			var slot: Node3D = _z2["tool_slot"]
			_player.face_point(slot.global_position)
			_player.model.play("Crouch_Idle", 0.25)
			var cutter := Props.cutter()
			_player.model.attach(cutter, "hand_r", Vector3(0, 0.08, 0.03))
			await _wait(0.4)
			_player.model.reach("r", slot, 0.5)
			await _wait(0.7)
			_player.model.detach(cutter)
			add_child(cutter)
			cutter.global_position = slot.global_position
			cutter.rotation = Vector3(0, 0, PI / 2)
			_player.model.release("r", 0.4)
			await _wait(0.4)
			_player.model.play("Idle", 0.3)
		"kayit_ac":
			_deniz_holo = HoloCall.new()
			_deniz_holo.caller_scene = load("res://scenes/characters/arman_model.tscn")
			_deniz_holo.caller_name = "DENİZ ARMAN · KAYIT"
			add_child(_deniz_holo)
			_deniz_holo.global_position = _z2["holo_spot"].global_position
			_deniz_holo.scale = Vector3.ONE * 2.2
			_deniz_holo.set_talking(true)
			(_z2["terminal_text"] as Label3D).text = "▶ OYNATILIYOR"
			camera_shots["kayit"] = [Z2 + Vector3(5.75, 1.5, 6.9), Z2 + Vector3(5.2, 1.25, 5.45), true]
			_set_camera("kayit")
		"kayit_kapat":
			if _deniz_holo:
				_deniz_holo.queue_free()
				_deniz_holo = null
			(_z2["terminal_text"] as Label3D).text = "KAYIT SONA ERDİ"
			(_z2["terminal_text"] as Label3D).modulate.a = 1.0
		"terminal_dokun":
			_player.face_point(_z2["terminal_point"].global_position)
			_player.model.reach("r", _z2["terminal_point"], 0.4)
			await _wait(0.6)
			(_z2["terminal_text"] as Label3D).text = "KAYIT SİLİNDİ"
			(_z2["terminal_text"] as Label3D).modulate.a = 1.0
			_player.model.release("r", 0.4)
		"erzak_ac":
			_player.face_point(_z2["ration_door"].global_position)
			_player.model.reach("r", _z2["ration_door"], 0.4)
			await _wait(0.45)
			var door: Node3D = _z2["ration_door"]
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(door, "position:y", 0.56, 0.6).set_trans(Tween.TRANS_SINE)
			(_z2["ration_pkg"] as Node3D).visible = true
			_player.model.release("r", 0.4)
		"erzak_al":
			var pkg: Node3D = _z2["ration_pkg"]
			_player.model.reach("r", pkg, 0.45)
			await _wait(0.5)
			var held: Node3D = pkg.duplicate()
			pkg.visible = false
			_player.model.attach(held, "hand_r", Vector3(0, 0.1, 0.05))
			_player.model.release("r", 0.3)
			_player.model.play_once("PickUp_Table", "Idle", 0.2)
			await _wait(1.0)
			_player.model.detach(held)
			held.queue_free()
			_hot["erzak"].set_interactable(false)
			_inspected["erzak"] = true
		# Anons ve kalkış
		"anons_isik":
			for l: OmniLight3D in _z2["cabin_lights"]:
				var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops(3)
				tw.tween_property(l, "light_color", Color(1.0, 0.55, 0.2), 0.35)
				tw.tween_property(l, "light_color", Color(1.0, 0.86, 0.7), 0.35)
		"koltuk_ac":
			await _raise_seat()
		"koltuga_otur":
			await _sit()
		"kemer_bagla":
			for b: Node3D in _z2["belts"]:
				var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(b, "rotation:z", -1.05, 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			await _wait(0.9)
			shake(0.05, 0.2)
		"geri_sayim":
			for l: OmniLight3D in _z2["cabin_lights"]:
				var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(l, "light_energy", l.light_energy * 0.35, 2.0)
		"atesleme_kamara":
			# Köprüden kamaraya: gürleme, sarsıntı, titreyen ışıklar; pencerede bulutlar aşağı kaymaya başlar
			_set_zone(3, false)
			_set_zone(2, true)
			shake(0.2, 5.0)
			for l: OmniLight3D in _z2["cabin_lights"]:
				var twl := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops(6)
				twl.tween_property(l, "light_color", Color(1.0, 0.5, 0.25), 0.15)
				twl.tween_property(l, "light_color", Color(1.0, 0.86, 0.7), 0.25)
			var out: Node3D = _z2["outside"]
			var tw0 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw0.tween_property(out, "position:y", -160.0, 8.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"tutun_basla":
			# Eller kolçaklara kenetlenir; QTE'de her dokunuş sıkar, güç arttıkça gövde koltuğa gömülür
			var g: Array = _z2["seat_grips"]
			_player.model.reach("l", g[0], 0.2)
			_player.model.reach("r", g[1], 0.2)
			_grip_base = [(g[0] as Node3D).position, (g[1] as Node3D).position]
			_gripping = true
			camera_shots["tutun"] = [Z2 + Vector3(6.25, 1.25, 7.75), Z2 + Vector3(5.05, 0.85, 7.0), true]
			_set_camera("tutun")
			shake(0.15, 5.0)
		"tutun":
			_gripping = false
			shake(0.25, 3.0)
		"bayil":
			_gripping = false
			_player.model.release_all(1.2)  # eller kolçaklardan kayar
			_lean(-0.12)  # baş öne düşer
			shake(0.3, 1.5)
			await _dialog.fade_to(1.0, 1.6)
		"yukselis_pencere":
			_window_ascent()
		"kopru":
			_set_zone(2, false)
			_set_zone(3, true)
		"gokyuzu_karar":
			_sky_to_space(6.0)
			var out2: Node3D = _z2["outside"]
			var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw2.tween_property(out2, "position:y", -4000.0, 5.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		"gokyuzu_hemen":
			_sky_to_space(0.0)
			(_z2["outside"] as Node3D).visible = false
		"dunya_gorun":
			(_z2["outside"] as Node3D).visible = false
			var e: Node3D = _z2["earth"]
			e.visible = true
			var to := e.position
			e.position = to + Vector3(0, -260, 0)
			var tw3 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw3.tween_property(e, "position", to, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		"kemer_coz":
			_player.model.release_all(0.5)
			_player.model.pose_locked = false
			for b: Node3D in _z2["belts"]:
				var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(b, "rotation:z", 1.2, 1.0).set_trans(Tween.TRANS_SINE)
			await _wait(1.0)
			_phase = "son"
			_finish()


var _hand_point: Node3D
var _memorial_label: Label3D


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _point(at: Vector3) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.global_position = at
	return n


func _player_fwd() -> Vector3:
	return -_player.get_node("Visual").global_basis.z


## Oyuncuyu bir noktanın önüne (aradaki mesafe kadar) yerleştirip ona baktırır.
func _beside(point: Vector3, distance: float) -> void:
	var dir := _player.global_position - point
	dir.y = 0
	if dir.length() < 0.05:
		dir = Vector3(0, 0, -1)
	var to := point + dir.normalized() * distance
	to.y = _player.global_position.y
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_player, "global_position", to, 0.4)
	_player.face_point(point)


## Kartı cebe koyar: el kalçaya gider, kart kaybolur.
func _pocket(item: Node3D) -> void:
	if item == null:
		return
	var hip := Node3D.new()
	_player.get_node("Visual").add_child(hip)
	hip.position = Vector3(0.2, 0.95, 0.02)
	_player.model.reach("r", hip, 0.4)
	await _wait(0.5)
	_player.model.detach(item)
	item.queue_free()
	_player.model.release("r", 0.4)
	hip.queue_free()


func _beep(light: OmniLight3D, color: Color) -> void:
	light.light_color = color
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(light, "light_energy", 2.0, 0.1)
	tw.tween_property(light, "light_energy", 0.6, 0.3)


func _reader_state(color: Color, mat_key: String, text: String) -> void:
	(_z1["reader_screen"] as MeshInstance3D).material_override = GemiSet.mat(mat_key)
	_beep(_z1["reader_light"], color)
	var l: Label3D = _z1["reader_text"]
	l.text = text
	l.modulate = color


func _open_gate() -> void:
	(_z1["gate_light"] as MeshInstance3D).material_override = GemiSet.mat("isik_yesil")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(_z1["gate_l"], "position:x", 8.0 - 2.1, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_z1["gate_r"], "position:x", 8.0 + 2.1, 1.4).set_trans(Tween.TRANS_SINE)
	_npcs["gorevli"].set_interactable(false)
	var g: Npc = _npcs["gorevli"]
	g.model.release_all(0.3)
	g.model.play("Idle", 0.3)
	_phase = "meydan"


func _on_atrium() -> void:
	if _phase != "meydan" or Story.get_var("meydan_goruldu", false):
		return
	Story.set_var("meydan_goruldu", true)
	await get_tree().process_frame
	if not _dialog.active:
		play_dialog(DLG, "meydan_giris")


# --- Asansör --------------------------------------------------------------------

var _cab_offset_player: Vector3
var _cab_offset_selim: Vector3


func _board_elevator() -> void:
	_phase = "asansor"
	var cab: Node3D = _z1["cab"]
	(_z1["tube_collision"] as CollisionShape3D).disabled = true
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	var selim: Npc = _npcs["selim"]
	selim.get_node("CollisionShape3D").disabled = true
	# İkisi de kabine yürür
	var p_to := cab.global_position + Vector3(-0.45, 0.06, 0.15)
	var s_to := cab.global_position + Vector3(0.5, 0.06, 0.35)
	_player.face_point(p_to)
	_player.model.play("Walk", 0.2)
	selim.face_point(s_to)
	selim.model.play("Walk", 0.2)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(_player, "global_position", p_to, 1.6)
	tw.tween_property(selim, "global_position", s_to, 1.8)
	await tw.finished
	_player.model.play("Idle", 0.3)
	selim.model.play("Idle", 0.3)
	_player.face_point(cab.global_position + Vector3(0.5, 0, -1.5))
	selim.face_point(_player.global_position)
	# Kapı kapanır, kabin yükselir
	var door: Node3D = _z1["cab_door"]
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(door, "position:x", 0.0, 0.8)
	await tw2.finished
	_cab_offset_player = _player.global_position - cab.global_position
	_cab_offset_selim = selim.global_position - cab.global_position
	_riding = true
	var ride := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ride.tween_property(cab, "position:y", 7.2, 40.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ride_tween = ride
	camera_shots["asansor"] = [Vector3.ZERO, Vector3.ZERO]


var _ride_tween: Tween


func _follow_cab() -> void:
	var cab: Node3D = _z1["cab"]
	if _riding:
		_player.global_position = cab.global_position + _cab_offset_player
		_npcs["selim"].global_position = cab.global_position + _cab_offset_selim
	var floor_n := 1 + int(cab.position.y / 0.9)
	(_z1["cab_display"] as Label3D).text = "G%d" % mini(floor_n, 8)
	if _camera_locked and _dialog_cam.current and _cab_cam:
		# Kabinin içinden, cam arkasında küçülen meydan
		var eye := cab.global_position + Vector3(0.85, 1.75, -0.75)
		_dialog_cam.global_position = eye
		_dialog_cam.look_at(cab.global_position + Vector3(-0.1, 1.35, 0.25), Vector3.UP)


var _cab_cam: bool = false


func _set_camera(shot: String) -> void:
	_cab_cam = shot == "asansor"
	if _cab_cam:
		_camera_locked = true
		if _cam_tween:
			_cam_tween.kill()
		_dialog_cam.make_current()
		_follow_cab()
		return
	super(shot)


func _riding_stop() -> void:
	if _ride_tween:
		_ride_tween.kill()
	shake(0.05, 0.25)
	(_z1["cab_display"] as Label3D).text = "G8"


func _arrive_deck8() -> void:
	await _dialog.fade_to(1.0, 0.8)
	_riding = false
	_cab_cam = false
	_set_zone(1, false)
	_set_zone(2, true)
	_npcs["selim"].visible = false
	_player.global_position = Z2 + Vector3(0, 0.05, 0.4)
	_player.face_point(Z2 + Vector3(0, 0, 10))
	_player.get_node("CameraPivot").rotation.y = deg_to_rad(180.0)
	_player.set_physics_process(true)
	_player.model.play("Idle", 0.0)
	_hot["kapi412"].set_interactable(true)
	_phase = "guverte8"
	_player_cam.make_current()
	await _wait(0.3)
	_dialog.fade_to(0.0, 1.0)


# --- Kamara -----------------------------------------------------------------------

func _on_cabin() -> void:
	if _phase != "guverte8":
		return
	_phase = "kamara"
	_cabin_time = 0.0
	# İçeri girince kapı arkasından kapanır
	var door: Node3D = _z2["cabin_door"]
	var twd := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	twd.tween_interval(0.8)
	twd.tween_property(door, "position:z", 7.0, 0.9).set_trans(Tween.TRANS_SINE)
	twd.tween_callback(func() -> void:
		for b in door.find_children("*", "StaticBody3D", true, false):
			(b as StaticBody3D).collision_layer = 1)
	for id in ["pencere", "yatak", "kutu", "kayit", "alet", "erzak"]:
		_hot[id].interactable = true
	# Işıklar teker teker yanar
	var lights: Array = _z2["cabin_lights"]
	for i in lights.size():
		var l: OmniLight3D = lights[i]
		var target := l.light_energy
		l.light_energy = 0.0
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(0.25 * i)
		tw.tween_property(l, "light_energy", target, 0.5)
	await _wait(0.6)
	if not _dialog.active:
		await play_dialog(DLG, "kamara_giris")
	refresh_interactions()


func _on_dialog_finished() -> void:
	super()
	if _talking_to == null:
		pass
	# İncelenen noktalar bir daha açılmaz (kayıt hariç: bekleyebilir)
	var node: String = _dialog.runner.last_node
	for pair in [["kutu", "cerceve_"], ["alet", "esya_alet"], ["alet", "alet_"], ["kayit", "kayit_oynat"], ["kayit", "kayit_sil"]]:
		if node.begins_with(pair[1]):
			_hot[pair[0]].set_interactable(false)
			_inspected[pair[0]] = true
	if node.begins_with("ipucu_yatak") or node.begins_with("ipucu_pencere") or node == "pencere_ada":
		_inspected[node] = true
	if _phase == "kamara" and _inspected.has("erzak") and _inspected.size() >= 3:
		_announce()


func _announce() -> void:
	if _phase != "kamara":
		return
	_phase = "anons"
	await _wait(1.2)
	if _dialog.active:
		await _dialog.dialog_finished
	await play_dialog(DLG, "anons")


func _raise_seat() -> void:
	var seat: Node3D = _z2["seat"]
	var hatch: Node3D = _z2["hatch"]
	# Oyuncu kapağın üstündeyse kenara al
	var c := Z2 + Vector3(5.0, 0, 7.0)
	var p := _player.global_position
	if Vector2(p.x - c.x, p.z - c.z).length() < 0.9:
		var tw0 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw0.tween_property(_player, "global_position", Vector3(c.x - 1.3, p.y, c.z), 0.5)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(hatch, "position:x", hatch.position.x + 1.15, 0.7)
	tw.tween_property(seat, "position:y", 0.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_shots["koltuk_acilis"] = [Z2 + Vector3(3.0, 2.0, 5.6), Z2 + Vector3(5.0, 0.6, 7.0), true]
	_set_camera("koltuk_acilis")
	await tw.finished
	(_z2["seat_collision"] as CollisionShape3D).disabled = false
	_hot["koltuk"].set_interactable(true)


func _sit() -> void:
	_hot["koltuk"].set_interactable(false)
	(_z2["seat_collision"] as CollisionShape3D).disabled = true
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	var seat_p: Vector3 = Z2 + Vector3(4.98, 0.0, 7.0)
	if (_z2["seat"] as Node3D).position.y < -0.1:
		await _raise_seat()
	var front := seat_p + Vector3(0.55, 0, 0)
	_player.model.play("Walk", 0.2)
	_player.face_point(front)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_player, "global_position", Vector3(front.x, _player.global_position.y, front.z), 0.9)
	await tw.finished
	# Koltuğa sırtını dönüp oturur (pencereye bakar)
	_player.face_point(front + Vector3(2, 0, 0))
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_player, "global_position", Vector3(seat_p.x + 0.12, seat_p.y + 0.02, seat_p.z), 0.6)
	_player.model.play("Sitting_Enter", 0.2)
	await _wait(1.5)
	_player.model.play("Sitting_Idle", 0.3)
	_player.model.pose_locked = true  # konuşma satırları duruşu bozmasın
	await _wait(0.3)
	# Pencere çekimi oturan oyuncunun gerçek baş konumundan: omzun arkası-yanı, sırtlığın dışı
	# Oturan başın konumu koltuktan sabit (kemik okumaya bağlı kalmasın: telefonda farklı okunabiliyor)
	var head: Vector3 = Z2 + Vector3(4.93, 1.17, 7.0)
	var win := Z2 + Vector3(7.7, 1.45, 7.0)
	var f := (win - head)
	f.y = 0
	f = f.normalized()
	var side := f.cross(Vector3.UP).normalized()
	# Sırtlık oturan başı kapatmasın: kamera sırtlığın üstünden, omzun arkasından aşağı pencereye bakar
	# Yandan, sırtlığın önünden: oyuncunun yüzü (profil) ve pencere birlikte
	# Pencere kadrajın çoğunu kaplar; oyuncunun omzu/başı altta, yanda (TWD: karakter + manzara)
	camera_shots["pencere"] = [head + f * 0.25 + side * 0.55 + Vector3(0, 0.33, 0), Z2 + Vector3(7.7, 1.42, 7.0) - side * 0.15, true]
	_seat_cam_target = _player.head_position()


## Pencereye (+X) bakan oturan oyuncunun sol eli -Z tarafındaki kolçağa (grips[0]) gider.
func _left_is_pos_z() -> bool:
	return false


func _finish() -> void:
	cinematic_hold = true
	if _dialog.active:
		await _dialog.dialog_finished
	_hud.set_gameplay_visible(false)
	await _wait(4.0)
	# Kayıt noktası bölümün başında alındı (DEVAM ET bölümü baştan oynatır)
	get_tree().change_scene_to_file(MENU_SCENE)


## Deniz'in annesiyle holografik fotoğrafı (küçük ayaklı çerçeve).
func _make_frame() -> Node3D:
	var root := Node3D.new()
	root.name = "Cerceve"
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.12, 0.012)
	back.mesh = bm
	back.material_override = GemiSet.mat("koyu")
	root.add_child(back)
	var pic := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.1)
	pic.mesh = q
	pic.position = Vector3(0, 0, 0.007)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = _photo_texture()
	pic.material_override = m
	pic.name = "Foto"
	root.add_child(pic)
	return root


static var _photo: ImageTexture


## Gülümseyen iki siluet: Deniz ve annesi (küçük, kodla çizilmiş).
static func _photo_texture() -> ImageTexture:
	if _photo:
		return _photo
	var w := 70
	var h := 50
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var t := float(y) / h
			img.set_pixel(x, y, Color(0.95, 0.72, 0.42).lerp(Color(0.55, 0.32, 0.25), t))
	var people := [[22, 22, 8, Color(0.85, 0.8, 0.75), Color(0.6, 0.6, 0.62)], [46, 19, 9, Color(0.35, 0.22, 0.15), Color(0.85, 0.48, 0.18)]]
	for p in people:
		var cx: int = p[0]
		var cy: int = p[1]
		var r: int = p[2]
		for y in range(cy - r, h):
			for x in range(cx - r * 2, cx + r * 2):
				if x < 0 or x >= w or y < 0:
					continue
				var dx := float(x - cx)
				var dy := float(y - cy)
				if dx * dx + dy * dy < r * r:
					img.set_pixel(x, y, Color(0.92, 0.75, 0.6))
					if dy < -r * 0.3:
						img.set_pixel(x, y, p[3])
				elif y > cy + r and absf(dx) < r * 1.6 + (y - cy - r) * 0.5:
					img.set_pixel(x, y, p[4])
	_photo = ImageTexture.create_from_image(img)
	return _photo


func _place_frame(at: Vector3, face_down: bool, into_crate: bool = false) -> void:
	if _frame == null:
		return
	_player.model.release("r", 0.2)
	var flat := Vector3(at.x, _player.global_position.y, at.z)
	if _player.global_position.distance_to(flat) > 0.75:
		var stand := flat + (_player.global_position - flat).normalized() * 0.6
		_player.model.play("Walk", 0.2)
		_player.face_point(stand)
		var tw0 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw0.tween_property(_player, "global_position", stand, _player.global_position.distance_to(stand) / 1.4)
		await tw0.finished
		_player.model.play("Idle", 0.2)
	var target := _point(at + Vector3(0, 0.05, 0))
	_player.face_point(at)
	if into_crate:
		_player.model.play("Crouch_Idle", 0.25)  # kutuya eğilir
	_player.model.reach("r", target, 0.5)
	await _wait(0.6)
	_player.model.detach(_frame)
	add_child(_frame)
	_frame.global_position = at + Vector3(0, 0.06 if not face_down else 0.008, 0)
	if face_down:
		_frame.rotation = Vector3(-PI / 2, 0, 0)
		var pic: MeshInstance3D = _frame.get_node("Foto")
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(pic, "transparency", 1.0, 1.0)
	elif into_crate:
		# Tulumların arasına, kutunun İÇİNE bırakılır; kapak kapanınca görünmez
		_frame.rotation = Vector3(-PI / 2, 0, 0)
		var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(_frame, "global_position", at - Vector3(0, 0.2, 0), 0.35)
		tw2.tween_interval(0.8)
		tw2.tween_callback(_frame.hide)
	else:
		_frame.rotation = Vector3(-0.25, PI / 2 + 0.4, 0)  # masada odaya dönük durur
	_player.model.release("r", 0.4)
	target.queue_free()
	_player.model.play("Idle", 0.3)


# --- Kalkış ------------------------------------------------------------------------

## Dış çekim: iticiler ateşlenir, gemi beşiğinden yükselir.
func _ignite() -> void:
	var flames: Array = _z4["flames"]
	for f: MeshInstance3D in flames:
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(f, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	var light: OmniLight3D = _z4["flame_light"]
	var twl := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	twl.tween_property(light, "light_energy", 6.0, 1.0)
	shake(0.25, 4.0)
	var ship: Node3D = _z4["ship"]
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_interval(1.0)
	tw2.tween_property(ship, "position:y", 420.0, 5.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Gökyüzü şafaktan uzaya döner (space 0 -> 1).
func _sky_to_space(time: float) -> void:
	var env: Environment = $WorldEnvironment.environment
	var m: ShaderMaterial = env.sky.sky_material
	if time <= 0.0:
		m.set_shader_parameter("space", 1.0)
		return
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("space", v), 0.0, 1.0, time)



## Bölüm yüklenirken siyah ekranda ortada küçük bir yazı.
func _loading_screen() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 120
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var l := Label.new()
	l.text = "Yükleniyor..."
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(l)
	add_child(layer)
	return layer



## Yörüngeye tırmanış: ~20 sn. Gemi kadrajda kalır; bulutlar aşağı akar, yer düşer, gök kararır,
## sonra Dünya'nın kıvrımı belirir ve gemi uzaklaştıkça Dünya aşağıda küçük bir topa dönüşür.
func _ascent() -> void:
	cinematic_hold = true  # 20 sn yazısız bekleme; gözetçi "takıldı" sanmasın
	_set_zone(2, false)
	var m: ShaderMaterial = ($WorldEnvironment.environment as Environment).sky.sky_material
	m.set_shader_parameter("space", 0.0)
	var Z5 := GemiSet.ZONE5
	var cam := _dialog_cam
	_camera_locked = true
	if _cam_tween:
		_cam_tween.kill()
	cam.make_current()
	cam.far = 120000.0
	cam.near = 0.5
	cam.fov = 55.0
	var ground: Node3D = _z5["ground"]
	var earth: Node3D = _z5["earth"]
	earth.visible = false
	ground.visible = true
	ground.position.y = -900.0
	shake(0.12, 8.0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	var layers: Array = _z5["clouds"]
	for i in layers.size():
		var c: Node3D = layers[i]
		c.position.y = 400.0 + i * 450.0
		c.visible = true
		tw.tween_property(c, "position:y", -9000.0, 7.5 + i * 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(c.hide).set_delay(7.6 + i * 1.0)  # geçen bulut katmanı uzayda asılı kalmasın
	tw.tween_property(ground, "position:y", -80000.0, 9.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("space", v), 0.0, 1.0, 9.0).set_delay(2.0)
	tw.tween_callback(func() -> void:
		ground.visible = false
		earth.visible = true
		earth.position = Vector3(0, -6250, 0)).set_delay(8.0)
	tw.tween_property(earth, "position", Vector3(0, -62000, -12000), 11.5).set_delay(8.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(p: float) -> void:
		var a := Vector3(420, -170, 560)
		var b := Vector3(760, 160, 980)
		var c2 := Vector3(260, 900, 720)
		var pos: Vector3
		var look: Vector3
		if p < 0.45:
			pos = a.lerp(b, p / 0.45)
			look = Vector3.ZERO
		else:
			var k := smoothstep(0.45, 1.0, p)
			pos = b.lerp(c2, k)
			look = Vector3.ZERO.lerp(Vector3(0, -2000, -600), k)
		cam.global_position = Z5 + pos
		cam.look_at(Z5 + look, Vector3.UP), 0.0, 1.0, 20.0)



# --- Kalkış: TUTUN ve pencereden yükseliş -------------------------------------------

var _gripping: bool = false
var _grip_base: Array = []


## Oturan oyuncunun gövdesini koltuğa doğru yatırır (+) ya da öne düşürür (-).
func _lean(amount: float) -> void:
	var vis: Node3D = _player.get_node("Visual")
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(vis, "rotation:x", amount, 0.5).set_trans(Tween.TRANS_SINE)


func _on_qte_fill(fill: float) -> void:
	if _gripping:
		# Güç arttıkça kamera sıkışır (ağırlık hissi); eller kolçakta
		_dialog_cam.fov = 45.0 - fill * 7.0


func _on_qte_tap() -> void:
	if not _gripping:
		return
	shake(0.08, 0.12)
	# Kolçakları sık: eller bir an aşağı bastırır
	var g: Array = _z2["seat_grips"]
	for i in 2:
		var mk: Node3D = g[i]
		var base: Vector3 = _grip_base[i]
		mk.position = base + Vector3(-0.02, -0.035, 0)
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(mk, "position", base, 0.12)


## ~20 sn: kamara içinden pencereye. Bulutlar camdan aşağı akar, gök maviden siyaha döner,
## Dünya'nın kıvrımı belirir ve gemi uzaklaştıkça küçük bir topa dönüşür.
func _window_ascent() -> void:
	cinematic_hold = true  # yazısız uzun sahne; gözetçi "takıldı" sanmasın
	var fainted: bool = Story.get_var("kalkis_bayildi", false)
	var m: ShaderMaterial = ($WorldEnvironment.environment as Environment).sky.sky_material
	var cam := _dialog_cam
	cam.far = 12000.0
	_set_camera("pencere")
	shake(0.22, 8.0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	var layers: Array = _z2["ascent_clouds"]
	for i in layers.size():
		var c: Node3D = layers[i]
		c.visible = true
		c.position.y = 120.0 + i * 420.0
		tw.tween_property(c, "position:y", -2600.0, 6.5 + i * 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(c.hide).set_delay(6.6 + i * 1.3)
	tw.tween_callback((_z2["outside"] as Node3D).hide).set_delay(5.0)
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("space", v), 0.0, 1.0, 9.0).set_delay(3.0)
	tw.tween_callback(func() -> void: _set_camera("yuz")).set_delay(6.0)
	tw.tween_callback(func() -> void: _set_camera("pencere")).set_delay(9.0)
	var e: Node3D = _z2["earth"]
	var final_pos := e.position
	tw.tween_callback(func() -> void:
		e.visible = true
		e.position = Vector3(1700, -2440, 7)
		e.scale = Vector3.ONE * 6.0).set_delay(9.0)
	tw.tween_property(e, "position", final_pos, 11.0).set_delay(9.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(e, "scale", Vector3.ONE, 11.0).set_delay(9.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if fainted:
		tw.tween_callback(func() -> void: _dialog.fade_to(0.0, 2.0)).set_delay(10.0)
	tw.tween_callback(func() -> void:
		cinematic_hold = false
		cam.far = 4000.0
		cam.fov = 45.0).set_delay(20.6)
