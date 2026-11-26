extends GameLevel
## "Seçim Gecesi" — oyunun başlangıcı. Dünya, 2526.
## Akış: açılış -> Ada'nın araması -> sokak (ipuçları, Deniz Arman, muhafız)
##       -> isyan (QTE) -> ara sokak: Deniz Arman'la yüzleşme -> kart -> kalkış -> "Devam edecek"

const DLG := "res://dialogs/onsoz.dlg"
const MENU_SCENE := "res://scenes/boot.tscn"

@onready var _arman: Npc = $Npcs/Arman
@onready var _guard: Npc = $Npcs/Muhafiz
@onready var _card: Npc = $Card
@onready var _crowd: Node3D = $Crowd
@onready var _alley: Area3D = $AlleyTrigger
@onready var _alarm: Node3D = $AlarmLights
@onready var _blast: OmniLight3D = $BlastLight

## Deniz Arman'ın ara sokakta beklediği yer
const ALLEY_SPOT := Vector3(16.2, -0.15, 10.6)

var _phase: String = "giris"
var _arman_card: Node3D
var _water: Node3D
var _cutter: Node3D
var _offer: Node3D
var _show_point: Node3D
var _radio: Node3D
var _radio_reach: bool = false
var _trembling: bool = false
var _alarm_tweens: Array[Tween] = []
## Konteynerin arkası (ceset buraya sürüklenir)
const HIDE_SPOT := Vector3(22.4, -0.15, 13.6)


func _ready() -> void:
	super()
	Story.reset()
	# İki gündür doğru dürüst yemek ve su yok
	Story.change_need("aclik", 68.0)
	Story.change_need("susuzluk", 74.0)
	Story.change_need("yorgunluk", 42.0)
	camera_shots = {
		"kalabalik": [Vector3(2.6, 2.1, 59.2), Vector3(-0.8, 1.2, 50.0)],
		"muhafiz": [Vector3(-0.9, 1.75, 55.6), Vector3(0.2, 1.55, 58.6)],
		"arman": [Vector3(-0.6, 3.0, 52.4), Vector3(1.8, 0.3, 55.0)],
		"evren_yakin": [Vector3(0.7, 1.62, -4.7), Vector3(-0.05, 1.38, -6.0)],
		"arama": [Vector3(0.9, 1.1, -4.7), Vector3(-0.05, 1.14, -5.75)],
		"sokak_genis": [Vector3(13.2, 2.4, 6.4), Vector3(15.6, 1.1, 10.6)],
		"arman_yerde": [Vector3(13.6, 2.6, 12.2), Vector3(16.0, 0.2, 10.4)],
		"surukle": [Vector3(19.0, 2.8, 17.0), Vector3(19.5, 0.4, 11.8)],
	}
	# Muhafızın elinde şok copu
	_guard.model.attach(Props.baton(), "hand_r", Vector3(0, 0.02, 0.03), Vector3(0, 0, 0))
	# Deniz Arman kartını elinde tutuyor
	_arman_card = Props.card()
	_arman.model.attach(_arman_card, "hand_r", Vector3(0, 0.08, 0.03), Vector3(0.3, 0, 0))
	_card.visible = false
	_card.interactable = false
	_alley.monitoring = false
	_alley.body_entered.connect(_on_alley_entered)
	for l: Light3D in _alarm.get_children():
		l.light_energy = 0.0
	_blast.light_energy = 0.0
	_dialog.fade_to(1.0, 0.0)
	await get_tree().process_frame
	_prewarm()
	ResourceLoader.load_threaded_request("res://scenes/levels/emanet_hangar.tscn")
	await play_dialog(DLG, "giris")
	# Başlık kartı ve kararmanın açılması bitmeden aramaya geçme
	if _dialog._title_tween and _dialog._title_tween.is_running():
		await _dialog._title_tween.finished
	await _dialog.fade_to(0.0, 1.2)
	_player.face_point(Vector3(0, 0, 60))
	await play_dialog(DLG, "ada_arama")
	_phase = "sokak"


func _on_story_event(event_name: String, _args: PackedStringArray) -> void:
	match event_name:
		"isyan":
			keep_world_running()
			_start_riot()
		"arman_dustu":
			_arman.visible = true
			_arman.position = Vector3(1.8, -0.15, 55.0)
			_arman.rotation = Vector3(0, 2.4, 0)
			_arman.get_node("Visual").rotation = Vector3.ZERO
			_arman.model.hold_last_frame("Death01")
			_arman.model.reach("r", _arman.model.bone_marker("spine_03"), 0.4)
		"arman_kalkti":
			_player.model.release_all(0.3)
			_player.model.play("Idle", 0.2)
			_arman_escape()
		"kaldir_hazirlik":
			_beside(_arman.global_position, 0.75)
			_player.model.play("Crouch_Idle", 0.2)
			_player.model.reach("r", _arman.model.bone_marker("hand_r"), 0.5)
		# --- Su şişesi
		"su_cikar":
			_water = Props.water_bottle()
			_arman.model.attach(_water, "hand_l", Vector3(0, 0.07, 0.04))
			_offer = _point((_arman.global_position + _player.global_position) / 2.0 + Vector3(0, 1.15, 0))
			_arman.model.reach("l", _offer, 0.6)
		"su_al":
			_player.model.reach("r", _offer, 0.45)
			await get_tree().create_timer(0.5, true, false, true).timeout
			if _water:
				_arman.model.detach(_water)
				_player.model.attach(_water, "hand_r", Vector3(0, 0.07, 0.04))
			_arman.model.release("l", 0.5)
			_player.model.release("r", 0.6)
		"su_ic":
			if _water:
				await drink_sequence(_water)
			Story.change_need("susuzluk", -40.0)
		"cantaya_koy":
			# Şişeyi sırttaki çantaya koyar: el omuzun arkasına gider, şişe kaybolur
			if _water:
				var bag := Node3D.new()
				_player.get_node("Visual").add_child(bag)
				bag.position = Vector3(0.22, 1.15, 0.22)
				_player.model.reach("r", bag, 0.45)
				await get_tree().create_timer(0.55, true, false, true).timeout
				_player.model.detach(_water)
				_water.queue_free()
				_water = null
				_player.model.release("r", 0.4)
				bag.queue_free()
		"su_geri":
			_arman.model.release("l", 0.5)
			await get_tree().create_timer(0.6, true, false, true).timeout
			if _water:
				_arman.model.detach(_water)
				_water.queue_free()
				_water = null
		# --- Kaynak kesicisi ve ölüm
		"cop_kaldir":
			# Muhafız copu kaldırıp sana savurur, sonra yakana yapışır
			_guard.model.play_once("Melee_Hook", "Idle_Shield", 0.1)
		"el_kaydi":
			# Tuttuğun bilek elinden kayar, kalabalık onu çeker
			_player.model.release("r", 0.25)
			_player.model.play("Idle", 0.2)
			var away := (_arman.global_position - _player.global_position)
			away.y = 0
			create_tween().tween_property(_arman, "global_position", _arman.global_position + away.normalized() * 1.4, 0.6)
		"kac":
			# Arkasını dönüp kalabalığın içine koşar
			_player.model.release_all(0.2)
			var dir := (_player.global_position - _arman.global_position)
			dir.y = 0
			dir = dir.normalized()
			_player.face_point(_player.global_position + dir)
			_player.model.play("Sprint", 0.15)
			var tw2 := create_tween()
			tw2.tween_property(_player, "global_position", _player.global_position + dir * 2.5, 0.9)
			tw2.tween_callback(func() -> void: _player.model.play("Idle", 0.2))
		"koridor":
			_setup_corridor()
		"el_tut":
			_hold_hands()
		"kart_goster":
			_show_point = _point((_arman.global_position + _player.global_position) / 2.0 + Vector3(0, 1.25, 0))
			_arman.model.reach("r", _show_point, 0.5)
		"kart_geri":
			_arman.model.release("r", 0.6)
		"kart_gogus":
			_arman.model.reach("r", _arman.model.bone_marker("spine_03"), 0.5)
		"geri_cekil":
			var back := (_arman.global_position - _player.global_position)
			back.y = 0
			back = back.normalized() * 0.7
			_arman.model.play("Walk", 0.15, -0.9)
			var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(_arman, "global_position", _arman.global_position + back, 0.7)
			tw.tween_callback(func() -> void: _arman.model.play("Idle", 0.2))
			_player.model.release("r", 0.4)
		"karta_uzan":
			if _arman_card:
				_player.model.reach("r", _arman_card, 0.45)
		"bilek_tut":
			_arman.model.release("r", 0.2)
			_player.model.reach("r", _arman.model.bone_marker("hand_l"), 0.3)
			_player.model.reach("l", _arman.model.bone_marker("lowerarm_l"), 0.3)
		"bilek_birak":
			_player.model.release_all(0.2)
		"telsize_uzan":
			_radio_reach = true
		"cirpinma":
			_struggle_twitch()
		"eller_titrer":
			_trembling_hands()
		"eller_birak":
			_trembling = false
			_player.model.release_all(0.6)
		"kesici_cek":
			if _radio == null:
				_radio = Props.radio()
				_arman.model.attach(_radio, "spine_03", Vector3(0.12, 0.05, -0.13), Vector3(0, 0, 0))
			_cutter = Props.cutter()
			_arman.model.attach(_cutter, "hand_l", Vector3(0, 0.05, 0.06), Vector3(-1.2, 0, 0))
			_arman.model.play_once("Interact", "Idle")
		"kesici_dus":
			if _cutter:
				_arman.model.detach(_cutter, self)
				var land := _arman.global_position + Vector3(-0.9, 0.0, 1.1)
				land.y = -0.12
				var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
				tw.tween_property(_cutter, "global_position", land, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				tw.tween_property(_cutter, "rotation", Vector3(PI / 2, 1.2, 0), 0.45)
		"kesici_al":
			if _cutter:
				_beside(_cutter.global_position, 0.6)
				_player.model.play("Crouch_Idle", 0.25)
				_player.model.reach("r", _cutter, 0.5)
				await get_tree().create_timer(0.7, true, false, true).timeout
				_player.model.attach(_cutter, "hand_r", Vector3(0, 0.05, 0.06), Vector3(-1.2, 0, 0))
				_player.model.release("r", 0.5)
				var light: OmniLight3D = _cutter.get_node("Uc/Isik")
				light.light_energy = 4.0
		"oldur_cok":
			var nk := _arman.model.bone_position("neck_01")
			var away := (_player.global_position - nk)
			away.y = 0
			away = away.normalized()
			# Kamera cesedin karşı tarafında: oyuncunun yüzü ve elleri kadrajda
			camera_shots["oldurme_yakin"] = [nk - away * 1.15 + away.cross(Vector3.UP) * 0.7 + Vector3(0, 1.35, 0), nk + away * 0.2 + Vector3(0, 0.15, 0)]
			var neck := _arman.model.bone_marker("neck_01")
			var head := _arman.model.bone_marker("Head")
			_beside(neck.global_position, 0.55)
			_player.model.play("Crouch_Idle", 0.3)
			if _cutter and _cutter.get_parent() is BoneAttachment3D:
				# Kesici sağ elde boynuna, sol el göğsüne bastırır
				_player.model.reach("r", neck, 0.6)
				_player.model.reach("l", _arman.model.bone_marker("spine_03"), 0.6)
			else:
				# Avuçlar ağzına
				_player.model.reach("r", head, 0.6)
				_player.model.reach("l", head, 0.6)
		"arman_oldu":
			_player.model.release_all(0.3)
			if _arman.model.ragdoll == null:
				_arman.get_node("CollisionShape3D").disabled = true
				_arman.model.go_ragdoll()
			_radio_reach = false
			# Kart onun elinde kalır; inceleme noktası kartın olduğu yere taşınır
			_card.get_node("CardMesh").visible = false
			_card.get_node("CardLight").visible = false
			_card.visible = true
			_player.model.play("Idle", 0.3)
			if _cutter and _cutter.get_parent() is BoneAttachment3D:
				_player.model.detach(_cutter)
				_cutter.queue_free()  # çantaya girdi
				_cutter = null
			await get_tree().create_timer(1.2, true, false, true).timeout
			if _arman_card:
				var at := _arman_card.global_position
				_card.global_position = Vector3(at.x, -0.15, at.z)
		"kart_al":
			# Kartı ölü adamın parmaklarının arasından alır
			var target: Node3D = _arman_card if _arman_card else _card
			_beside(target.global_position, 0.6)
			_player.model.play("Crouch_Idle", 0.25)
			_player.model.reach("r", target, 0.6)
			await get_tree().create_timer(0.8, true, false, true).timeout
			_card.interactable = false
			if _arman_card:
				_arman.model.detach(_arman_card)
				_player.model.attach(_arman_card, "hand_r", Vector3(0, 0.08, 0.03), Vector3(0.3, 0, 0))
			_player.model.release("r", 0.5)
			await get_tree().create_timer(0.7, true, false, true).timeout
			_player.model.play("Idle", 0.4)
			await get_tree().create_timer(1.0, true, false, true).timeout
			if _arman_card:
				_player.model.detach(_arman_card)
				_arman_card.queue_free()  # cebine
				_arman_card = null
		"ceset_surukle":
			_drag_body()
		"uzaklas":
			var away := _player.global_position + Vector3(-3.5, 0, -1.0)
			_player.face_point(away)
			_player.model.play("Walk", 0.2)
			var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw2.tween_property(_player, "global_position", away, 2.4)
			tw2.tween_callback(func() -> void: _player.model.play("Idle", 0.3))
		"arman_yerde":
			# Başını betona vurarak düşer: fizik iskeleti
			_arman.get_node("CollisionShape3D").disabled = true
			var fall := (_arman.global_position - _player.global_position)
			fall.y = 0
			_arman.model.play("Hit_Knockback", 0.05)
			await get_tree().create_timer(0.2, true, false, true).timeout
			_arman.model.go_ragdoll("spine_03", fall.normalized() * 16.0 + Vector3(0, 3, 0))
		"telefon":
			_start_call()
		"telefon_kapat":
			_end_call()
		"final":
			_final()
		"sise_at":
			_throw_bottle()
		"sise_kacti":
			_bottle_miss()
		"sise_carpti":
			_bottle_hit()
		"muhafiz_dustu":
			_guard.model.play("Hit_Knockback", 0.05)
			var push := (_guard.global_position - _player.global_position)
			push.y = 0
			_guard.get_node("CollisionShape3D").disabled = true
			await get_tree().create_timer(0.25).timeout
			# Yumruğun etkisiyle fizik iskeletine bırak: savrulur ve yerde kalır
			_guard.model.go_ragdoll("spine_03", push.normalized() * 55.0 + Vector3(0, 8, 0))


## Oyuncuyu bir noktanın yanına (aradaki mesafe kadar) yerleştirip ona baktırır.
func _beside(point: Vector3, distance: float) -> void:
	var from := _player.global_position - point
	from.y = 0
	if from.length() < 0.01:
		from = Vector3(-1, 0, 0)
	var pos := point + from.normalized() * distance
	pos.y = _player.global_position.y
	_player.global_position = pos
	_player.face_point(point)


## Cesedi konteynerin arkasına sürükleme ara sahnesi (gerçek fizik):
## oyuncu çömelip bileklerinden tutar ve geri geri yürür; ceset ragdoll olarak sürüklenir.
var _drag_grips: Array = []
var _drag_cam_offset := Vector3.ZERO


func _drag_body() -> void:
	var rd := _arman.model.ragdoll
	if rd == null:
		_arman.model.go_ragdoll()
		rd = _arman.model.ragdoll
	var hands := (rd.bone("hand_l").global_position + rd.bone("hand_r").global_position) / 2.0
	var dir := (HIDE_SPOT - hands)
	dir.y = 0
	dir = dir.normalized()
	# Kamera yandan
	var mid := (hands + HIDE_SPOT) / 2.0
	var side := dir.cross(Vector3.UP).normalized()
	if (mid + side).distance_to(Vector3(19.0, 0, 18.0)) > (mid - side).distance_to(Vector3(19.0, 0, 18.0)):
		side = -side
	camera_shots["surukle"] = [mid + side * 3.8 + Vector3(0, 1.7, 0), mid + Vector3(0, 0.35, 0)]
	_set_camera("surukle")
	if _cam_tween:
		_cam_tween.kill()
	_drag_cam_offset = side * 3.4 + Vector3(0, 1.5, 0)
	# Oyuncu ellerin önünde, cesede dönük
	var start := hands + dir * 0.55
	start.y = _player.global_position.y
	_player.global_position = start
	_player.face_point(hands)
	var grip_l := Node3D.new()
	var grip_r := Node3D.new()
	_player.get_node("Visual").add_child(grip_l)
	_player.get_node("Visual").add_child(grip_r)
	grip_l.position = Vector3(-0.13, 0.38, -0.42)
	grip_r.position = Vector3(0.13, 0.38, -0.42)
	_drag_grips = [grip_l, grip_r]
	_player.model.play("Crouch_Idle", 0.2)
	# Eller cesedin bileklerine kilitlenir (sağ el onun sol bileğine, sol el sağ bileğine)
	_player.model.reach("l", _arman.model.bone_marker("hand_r"), 0.4)
	_player.model.reach("r", _arman.model.bone_marker("hand_l"), 0.4)
	await get_tree().create_timer(0.6, true, false, true).timeout
	_player.model.play("Crouch_Fwd", 0.2, -0.7)
	var travel := HIDE_SPOT - hands
	travel.y = 0
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_player, "global_position", _player.global_position + travel, 4.2)
	await tw.finished
	_drag_grips = []
	_drag_cam_offset = Vector3.ZERO
	_player.model.release_all(0.4)
	_player.model.play("Idle", 0.4)
	await get_tree().create_timer(0.6, true, false, true).timeout
	_arman.visible = false
	for b in rd.bones.values():
		(b as PhysicalBone3D).collision_layer = 0
	grip_l.queue_free()
	grip_r.queue_free()
	Story.set_var("ceset_yeri", "konteyner")


## Boğulurken/susturulurken bedenin son çırpınışları (fizik darbeleri, giderek azalır).
func _struggle_twitch() -> void:
	await get_tree().create_timer(0.4, true, false, true).timeout
	var rd := _arman.model.ragdoll
	if rd == null:
		return
	for k in 10:
		var power := (1.0 - k / 10.0) * 3.5
		for b in ["calf_l", "calf_r", "foot_l", "hand_l", "lowerarm_l"]:
			if randf() < 0.6 and rd.bone(b):
				rd.bone(b).apply_central_impulse(Vector3(randf_range(-1, 1), randf_range(0.3, 1.0), randf_range(-1, 1)) * power)
		await get_tree().create_timer(0.14, true, false, true).timeout


## Öldürdükten sonra: eller göz hizasında, titreyerek.
func _trembling_hands() -> void:
	var vis: Node3D = _player.get_node("Visual")
	var hl := Node3D.new()
	var hr := Node3D.new()
	vis.add_child(hl)
	vis.add_child(hr)
	var base_l := Vector3(-0.12, 1.32, -0.32)
	var base_r := Vector3(0.12, 1.32, -0.32)
	hl.position = base_l
	hr.position = base_r
	_player.model.play("Idle", 0.3)
	_player.model.reach("l", hl, 0.6)
	_player.model.reach("r", hr, 0.6)
	var head := _player.head_position()
	var fwd := -vis.global_basis.z
	var side := vis.global_basis.x
	camera_shots["eller"] = [head + fwd * 1.15 + side * 0.4 + Vector3(0, -0.05, 0), head + fwd * 0.2 + Vector3(0, -0.12, 0)]
	_set_camera("eller")
	_trembling = true
	while _trembling:
		var j := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.012
		hl.position = base_l + j
		hr.position = base_r - j * 0.8
		await get_tree().create_timer(0.05, true, false, true).timeout
	hl.queue_free()
	hr.queue_free()


func _physics_process(_delta: float) -> void:
	# Yerdeki adamın eli telsize uzanır (fizik iskeleti)
	if _radio_reach and _radio and _arman.model.ragdoll:
		_arman.model.ragdoll.pull("hand_l", _radio.global_position + Vector3(0, 0.03, 0), 6.0, 1.2)
	if _drag_grips.size() == 2 and _arman.model.ragdoll:
		var rd := _arman.model.ragdoll
		var gl: Vector3 = (_drag_grips[0] as Node3D).global_position
		var gr: Vector3 = (_drag_grips[1] as Node3D).global_position
		# Oyuncunun bileği IK ile tam tutma noktasında; avucu ~8 cm ileride (cesede doğru).
		# Arman'ın bilek eklemi oraya çekilir: el ele kavrama.
		var fwd := -(_player.get_node("Visual") as Node3D).global_basis.z
		rd.pull("hand_l", gr + fwd * 0.04, 14.0, 4.0, true)
		rd.pull("hand_r", gl + fwd * 0.04, 14.0, 4.0, true)
		# Göğüs kolların arkasından gelir (kollar gergin, sırt yerde)
		var back := -(_player.get_node("Visual") as Node3D).global_basis.z
		var chest := (gl + gr) / 2.0 + back * 0.5
		chest.y = 0.15
		rd.pull("spine_03", chest, 8.0, 3.0)
		# Kamera yandan izler
		if _drag_cam_offset != Vector3.ZERO:
			var focus := (rd.bone("pelvis").global_position + _player.global_position) / 2.0
			_dialog_cam.global_position = _dialog_cam.global_position.lerp(focus + _drag_cam_offset, 0.08)
			_dialog_cam.look_at(focus + Vector3(0, 0.3, 0), Vector3.UP)


## Dünyada sabit bir hedef noktası (IK için).
func _point(at: Vector3) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.global_position = at
	return n


# --- Gölgelendirici ön ısıtma --------------------------------------------------

## Mobil ekran kartları bir nesneyi ilk çizdiklerinde gölgelendiricisini derler ve oyun
## bir anlığına donar. Ekran siyahken sahnede sonradan çıkacak her şey kameranın önünde
## birkaç kare çizdirilir, böylece derleme oyun sırasında değil şimdi yapılır.
func _prewarm() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var holder := Node3D.new()
	add_child(holder)
	holder.global_transform = cam.global_transform.translated_local(Vector3(0, 0, -2.0))
	var items: Array[Node3D] = [Props.card(), Props.water_bottle(), Props.cutter(), Props.baton(),
		Props.radio(), Props.energy_bar(), Props.phone()]
	var x := -0.6
	for it in items:
		holder.add_child(it)
		it.position = Vector3(x, 0, 0)
		x += 0.2
	var holo := HoloCall.new()
	holo.caller_scene = load("res://scenes/characters/ada_model.tscn")
	holder.add_child(holo)
	holo.position = Vector3(0.6, 0, 0)
	var fire: Node3D = load("res://scenes/props/fire_barrel.tscn").instantiate()
	holder.add_child(fire)
	fire.position = Vector3(0, -1.2, -1.0)
	_shatter(holder.global_position + holder.global_basis * Vector3(0.3, 0.2, 0))
	for k in 6:
		await get_tree().process_frame
	holder.queue_free()


# --- Kapanış: gemide kargo koridoru ------------------------------------------

const CORRIDOR := Vector3(600, 0, 600)  # hangar sahnesi şehirden çok uzağa kurulur (aşağı değil: düşme ölümü sayılır)
var _ada_ship: CharacterModel


func _setup_corridor() -> void:
	var hangar: Node3D = (ResourceLoader.load_threaded_get("res://scenes/levels/emanet_hangar.tscn") as PackedScene).instantiate()
	hangar.position = CORRIDOR
	add_child(hangar)
	_player.velocity = Vector3.ZERO
	_player.global_position = CORRIDOR + Vector3(12.0, 0.05, 5.0)
	_player.model.release_all(0.0)
	_player.model.play("Idle", 0.0)
	_ada_ship = load("res://scenes/characters/ada_model.tscn").instantiate()
	_ada_ship.process_mode = Node.PROCESS_MODE_ALWAYS  # ara sahne duraklatılmış olsa da canlı
	add_child(_ada_ship)
	_ada_ship.global_position = CORRIDOR + Vector3(12.0, 0.0, 5.8)
	_ada_ship.start_animation = "Idle"
	_player.face_point(_ada_ship.global_position)
	# Ada modeli -Z'ye bakar; oyuncuya dönük (+Z'den -Z'ye) zaten doğru
	camera_shots["koridor"] = [CORRIDOR + Vector3(13.8, 1.6, 5.3), CORRIDOR + Vector3(12.0, 1.35, 5.4)]
	_set_camera("koridor")


## Ada ile oyuncunun elleri aralarındaki noktada buluşur.
func _hold_hands() -> void:
	if _ada_ship == null:
		return
	var meet := Node3D.new()
	add_child(meet)
	meet.global_position = CORRIDOR + Vector3(12.17, 1.02, 5.4)
	_ada_ship.reach("r", meet, 0.8)
	_player.model.reach("l", meet, 0.8)
	camera_shots["el_ele"] = [CORRIDOR + Vector3(13.55, 1.45, 5.15), CORRIDOR + Vector3(12.05, 1.15, 5.4)]
	_set_camera("el_ele")


# --- Görüntülü arama ---------------------------------------------------------

var _phone: Node3D
var _holo: HoloCall
var _phone_hand: Node3D


## Telefonu göğüs hizasında tutar (el IK ile telefona gider), üstünde Ada'nın hologramı.
func _start_call() -> void:
	_player.face_point(Vector3(0, 0, 60))
	_player.model.play("Idle", 0.3)
	var vis: Node3D = _player.get_node("Visual")
	_phone = Props.phone()
	vis.add_child(_phone)
	_phone.position = Vector3(0.14, 1.3, -0.36)
	_phone.rotation = Vector3(deg_to_rad(-55), 0, 0)  # ekran yüzüne dönük
	_phone_hand = Node3D.new()
	_phone.add_child(_phone_hand)
	_phone_hand.position = Vector3(0.0, -0.04, 0.02)
	var elbow := Node3D.new()
	elbow.name = "Dirsek"
	vis.add_child(elbow)
	elbow.position = Vector3(0.38, 1.0, 0.0)
	_player.model.reach("r", _phone_hand, 0.5, elbow)
	_holo = HoloCall.new()
	_holo.caller_scene = load("res://scenes/characters/ada_model.tscn")
	_holo.caller_name = "ADA"
	_phone.add_child(_holo)
	_holo.position = Vector3(0, 0.08, 0.02)
	_holo.rotation = Vector3(deg_to_rad(55), 0, 0)
	var glow := OmniLight3D.new()
	glow.name = "PhoneGlow"
	glow.light_color = Color(0.55, 0.8, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 1.2
	glow.position = Vector3(0.0, 0.05, -0.1)
	_phone.add_child(glow)
	_dialog.speaker_changed.connect(_on_call_speaker)


func _on_call_speaker(id: String) -> void:
	if _holo:
		_holo.set_talking(id == "ADA")


func _end_call() -> void:
	if _dialog.speaker_changed.is_connected(_on_call_speaker):
		_dialog.speaker_changed.disconnect(_on_call_speaker)
	_player.model.release("r", 0.5)
	await get_tree().create_timer(0.5, true, false, true).timeout
	if _phone:
		_phone.queue_free()
		_phone = null
		_holo = null
	var e := _player.get_node_or_null("Visual/Dirsek")
	if e:
		e.queue_free()
	_player.model.play("Idle", 0.4)


# --- Şişe ------------------------------------------------------------------

var _bottle: MeshInstance3D
var _bottle_tween: Tween


func _throw_bottle() -> void:
	_bottle = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.045
	mesh.height = 0.28
	_bottle.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.35, 0.15)
	mat.emission = Color(0.4, 0.9, 0.45)
	mat.emission_energy_multiplier = 2.5
	_bottle.material_override = mat
	_bottle.scale = Vector3.ONE * 1.8
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.6, 1.0, 0.6)
	glow.light_energy = 1.5
	glow.omni_range = 2.0
	_bottle.add_child(glow)
	var trail := CPUParticles3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.03
	dot.height = 0.06
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_color = Color(0.7, 1.0, 0.7, 0.8)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot.material = tm
	trail.mesh = dot
	trail.amount = 24
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.1
	trail.scale_amount_min = 0.6
	_bottle.add_child(trail)
	add_child(_bottle)
	var head := _player.head_position()
	var from := head + Vector3(-3.0, 2.6, -9.0)
	_bottle.global_position = from
	_bottle_tween = create_tween().set_parallel(true)
	_bottle_tween.tween_property(_bottle, "global_position", head + Vector3(0, 0.05, 0), 1.35)
	_bottle_tween.tween_property(_bottle, "rotation", Vector3(TAU * 3.0, 0, TAU), 1.35)


func _bottle_miss() -> void:
	if _bottle == null:
		return
	if _bottle_tween:
		_bottle_tween.kill()
	var target := _guard.head_position()
	var tw := create_tween()
	tw.tween_property(_bottle, "global_position", target, 0.25)
	tw.tween_callback(func() -> void:
		_shatter(_bottle.global_position)
		_guard.model.play_once("Hit_Head", "Idle_Shield"))


func _bottle_hit() -> void:
	if _bottle == null:
		return
	if _bottle_tween:
		_bottle_tween.kill()
	_shatter(_player.head_position())


## Cam kırıkları
func _shatter(at: Vector3) -> void:
	if _bottle:
		_bottle.queue_free()
		_bottle = null
	var p := CPUParticles3D.new()
	var shard := BoxMesh.new()
	shard.size = Vector3(0.03, 0.005, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.85, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 0.35)
	shard.material = mat
	p.mesh = shard
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -9.8, 0)
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


# --- İsyan -----------------------------------------------------------------

func _start_riot() -> void:
	if _phase != "sokak":
		return
	_phase = "isyan"
	shake(0.12, 3.0)
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc != _card:
			npc.interactable = false
	refresh_interactions()
	_guard.model.play("Idle_Shield", 0.2)

	# Alarm ışıkları yanıp söner
	for l: OmniLight3D in _alarm.get_children():
		var tw := create_tween().set_loops()
		_alarm_tweens.append(tw)
		tw.tween_property(l, "light_energy", 4.0, 0.35)
		tw.tween_property(l, "light_energy", 0.3, 0.35)

	# Kalabalık dağılır
	var i := 0
	for person: Node3D in _crowd.get_children():
		var away := Vector3(randf_range(-7.0, 7.0), -0.15, person.position.z - randf_range(18.0, 30.0))
		if i % 3 == 0:
			away = Vector3(randf_range(-7.0, 7.0), -0.15, person.position.z + randf_range(4.0, 8.0))
		_run_to(person as CharacterModel, person, [away], randf_range(5.0, 7.0), "Sprint" if i % 2 == 0 else "Jog_Fwd", i % 3 != 0)
		i += 1
	for npc: Npc in [$Npcs/Yasli, $Npcs/Kadin]:
		_run_to(npc.model, npc, [npc.position + Vector3(randf_range(-3, 3), 0, -25)], 6.0, "Jog_Fwd", true)
	_alley.monitoring = true
	for k in 3:
		await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
		if _phase != "isyan":
			return
		shake(0.35, 0.5)


## Deniz Arman yerden kalkıp ara sokağa koşar ve orada nefeslenir.
func _arman_escape() -> void:
	_arman.model.release("r", 0.3)
	_arman.model.unlock_pose()
	_arman.model.play("LayToIdle", 0.1)
	await get_tree().create_timer(1.6).timeout
	_run_to(_arman.model, _arman, [Vector3(5.0, -0.15, 40.0), Vector3(6.5, -0.15, 13.0), Vector3(12.5, -0.15, 10.6), ALLEY_SPOT], 9.0, "Sprint", false)
	await get_tree().create_timer(9.1).timeout
	_arman.model.play("Idle", 0.3)


func _run_to(model: CharacterModel, mover: Node3D, points: Array, duration: float, anim: String, hide_at_end: bool) -> void:
	if model == null:
		return
	model.play(anim, 0.15)
	var tw := create_tween()
	var prev: Vector3 = mover.position
	var seg := duration / points.size()
	for p: Vector3 in points:
		var dir := p - prev
		var yaw := atan2(-dir.x, -dir.z)
		tw.tween_callback(func() -> void: mover.rotation.y = yaw)
		tw.tween_property(mover, "position", p, seg)
		prev = p
	if hide_at_end:
		tw.tween_callback(func() -> void: mover.visible = false)


# --- Ara sokak: yüzleşme -----------------------------------------------------

func _on_alley_entered(body: Node3D) -> void:
	if not body is Player or _phase != "isyan":
		return
	_phase = "sokak_sonu"
	_alley.set_deferred("monitoring", false)
	_hud.set_objective("")
	# İsyan efektlerini durdur; uzakta bir patlama
	for tw in _alarm_tweens:
		tw.kill()
	_alarm_tweens.clear()
	for l: Light3D in _alarm.get_children():
		l.light_energy = 0.0
	_blast.light_energy = 10.0
	create_tween().tween_property(_blast, "light_energy", 0.0, 1.0)
	shake(0.35, 0.8)
	# Deniz Arman ara sokakta, nefes nefese
	_arman.visible = true
	_arman.rotation = Vector3.ZERO
	_arman.position = ALLEY_SPOT
	_arman.model.play("Idle", 0.2)
	_player.velocity = Vector3.ZERO
	var to_arman := (_arman.global_position - _player.global_position)
	to_arman.y = 0
	if to_arman.length() > 2.6:
		_player.global_position = _arman.global_position - to_arman.normalized() * 2.2
	_arman.start_node = "ara_sokak"
	live_world = true  # boğuşma, ragdoll ve sürükleme diyalog sırasında fizikle oynar
	_start_dialog(_arman)
	await _dialog.dialog_finished
	_arman.model.hold_last_frame("Death01")  # diyalog sonu bekleme duruşunu geri al	_crowd.visible = false
	_guard.visible = false
	_card.set_interactable(true)
	_phase = "kart"


# --- Final -----------------------------------------------------------------

func _final() -> void:
	if _phase == "final":
		return
	_phase = "final"
	cinematic_hold = true
	if _dialog.active:
		await _dialog.dialog_finished
	_card.set_interactable(false)
	_player.input_enabled = false
	_hud.set_gameplay_visible(false)
	await _dialog.fade_to(1.0, 2.0)
	await play_dialog(DLG, "kalkis")
	_hud.set_gameplay_visible(false)
	await get_tree().create_timer(4.5).timeout
	get_tree().change_scene_to_file(MENU_SCENE)
