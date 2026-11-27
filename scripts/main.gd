class_name GameLevel
extends Node3D
## Bir oyun seviyesi: oyuncu, karakterler, diyaloglar, arayüz ve (isteğe bağlı) dövüş.
## Hikâye sahneleri bu sınıftan türeyip _on_story_event() ile kendi olaylarını işler.

## false ise can barı, SALDIR düğmesi ve sayaçlar gizlenir.
@export var combat_enabled: bool = true
## Oyuncunun diyaloglardaki konuşmacı kimliği (DENIZ, önsözde EVREN).
@export var player_speaker_id: String = "DENIZ"

@onready var _player: Player = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _dialog: CanvasLayer = $DialogUI

var _nearby_npc: Npc = null
var _talking_to: Npc = null
var _dialog_cam: Camera3D
var _player_cam: Camera3D
## Ara sahne kamera açıları: ad -> [konum, bakılan nokta]. "@olay kamera ad" ile seçilir.
var camera_shots: Dictionary = {}
var _camera_locked: bool = false
var _cutscene_live: bool = false
## true iken diyaloglar dünyayı (fizik, ragdoll) durdurmaz; oyuncu hareket edemez.
var live_world: bool = false
## Boğuşma: oyuncu ile karşısındaki karakter itişir (QTE gücüne göre öne/geri).
var _struggle_npc: Npc = null
var _struggle_mid: Vector3
var _struggle_dir: Vector3
var _cam_tween: Tween
var _shake_time: float = 0.0
var _shake_strength: float = 0.0


func _ready() -> void:
	add_to_group("level")
	get_tree().paused = false
	Game.mark_level_started()

	_hud.joystick.changed.connect(func(v: Vector2) -> void: _player.move_input = v)
	_hud.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	_hud.set_combat_enabled(combat_enabled)
	_hud.use_item_requested.connect(use_item)
	Story.need_warning.connect(_on_need_warning)

	_player.health_changed.connect(_hud.set_health)
	_player.died.connect(_on_player_died)
	_hud.set_health(_player.health, _player.max_health)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)
	_hud.set_enemies(get_tree().get_nodes_in_group("enemies").size())

	Game.gems_changed.connect(_on_gems_changed)
	Game.reset(get_tree().get_nodes_in_group("gems").size())

	# Diyalog
	_player_cam = _player.get_node("CameraPivot/SpringArm3D/Camera3D")
	_dialog_cam = Camera3D.new()
	_dialog_cam.fov = 45.0
	add_child(_dialog_cam)
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		npc.player_nearby.connect(_on_npc_nearby)
	_dialog.speaker_changed.connect(_on_speaker_changed)
	_dialog.event_fired.connect(_on_dialog_event)
	_dialog.dialog_finished.connect(_on_dialog_finished)
	_dialog.qte_progress.connect(_on_struggle_progress)
	_dialog.qte_tapped.connect(func() -> void:
		if _struggle_npc:
			shake(0.06, 0.12))
	_dialog.qte_death.connect(_on_qte_death)
	_dialog.qte_retry.connect(_on_qte_retry)


func _on_need_warning(text: String) -> void:
	_dialog.show_notification(text)


func _exit_tree() -> void:
	if Story.need_warning.is_connected(_on_need_warning):
		Story.need_warning.disconnect(_on_need_warning)
	if Game.gems_changed.is_connected(_on_gems_changed):
		Game.gems_changed.disconnect(_on_gems_changed)


# --- Gözetçi: akış takılırsa kendini kurtarır ve kaydeder ---------------------

## Final gibi bilinçli uzun beklemelerde true yapılır.
var cinematic_hold: bool = false
var _stall := {"siyah": 0.0, "kilit": 0.0, "bekle": 0.0, "panelsiz": 0.0}


func _watchdog(delta: float) -> void:
	if cinematic_hold:
		for k in _stall:
			_stall[k] = 0.0
		return
	var d = _dialog
	var no_dialog: bool = not d.active
	_stall["siyah"] = _stall["siyah"] + delta if no_dialog and d._fade.color.a > 0.95 else 0.0
	_stall["kilit"] = _stall["kilit"] + delta if no_dialog and not _player.input_enabled and not _using_item and not _player.is_dead else 0.0
	_stall["bekle"] = _stall["bekle"] + delta if d.active and d._waiting else 0.0
	var nothing_to_tap: bool = d.active and not d._waiting and not d._in_qte and not d._choosing and not d._panel.visible
	_stall["panelsiz"] = _stall["panelsiz"] + delta if nothing_to_tap else 0.0
	if _stall["siyah"] > 6.0:
		_report_stall("siyah ekran")
		d.fade_to(0.0, 0.8)
	if _stall["kilit"] > 6.0:
		_report_stall("oyuncu kilitli")
		_player.input_enabled = true
		_hud.set_gameplay_visible(true)
		_player_cam.make_current()
	if _stall["bekle"] > 12.0:
		_report_stall("bekleme bitmedi")
		d._waiting = false
		d.runner.advance()
	if _stall["panelsiz"] > 6.0:
		_report_stall("metinsiz diyalog")
		d.runner.advance()


func _report_stall(kind: String) -> void:
	for k in _stall:
		_stall[k] = 0.0
	var msg := "TAKILMA: %s (düğüm: %s)" % [kind, _dialog.runner.current_node]
	push_warning(msg)
	Game.boot_log(msg)


func _process(delta: float) -> void:
	_watchdog(delta)
	if _nearby_npc and _nearby_npc.interactable and not _dialog.active and not _player.is_dead \
			and Input.is_action_just_pressed("interact"):
		_start_dialog(_nearby_npc)
	_update_shake(delta)


# --- Diyalog ---------------------------------------------------------------

func _start_dialog(npc: Npc) -> void:
	if _dialog.active:
		# Bir konuşma sürerken yenisi üstüne binmez: sıraya girer, öncekinin yazıları yarıda silinmez.
		Game.boot_log("sıra: '%s' önceki konuşma (%s) bitince başlayacak" % [npc.start_node, _dialog.runner.current_node])
		await _dialog.dialog_finished
		await get_tree().process_frame
		if _dialog.active:
			return
	_talking_to = npc
	_enter_dialog_mode()
	if npc.model:
		npc.model.process_mode = Node.PROCESS_MODE_ALWAYS
		npc.face_point(_player.global_position)
	_player.face_point(npc.global_position)
	if npc.model == null and not npc.inspect_anim.is_empty():
		_player.model.play_once(npc.inspect_anim, "Idle")
	_dialog_cam.make_current()
	_dialog.start(npc.dialog_path, npc.start_node)


## Bir karaktere bağlı olmayan diyalog (anlatım, ara sahne). Bitene kadar bekler.
func play_dialog(path: String, node_name: String) -> void:
	while _dialog.active:
		Game.boot_log("sıra: '%s' önceki konuşma (%s) bitince başlayacak" % [node_name, _dialog.runner.current_node])
		await _dialog.dialog_finished
		await get_tree().process_frame
	_talking_to = null
	_enter_dialog_mode()
	_dialog.start(path, node_name)
	await _dialog.dialog_finished


func _enter_dialog_mode() -> void:
	get_tree().paused = true
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc._marker:
			npc._marker.visible = false
	_hud.set_gameplay_visible(false)
	_player.stand_idle()
	# Oyun duraklasa da karakterler diyalogda hareket etmeye devam etsin.
	_player.model.process_mode = Node.PROCESS_MODE_ALWAYS
	if live_world:
		keep_world_running()


## Diyalog sürerken dünyanın donmamasını sağlar (ara sahnede kalabalık koşsun, ışıklar yansın).
## Oyuncu bu sırada hareket edemez.
func keep_world_running() -> void:
	_cutscene_live = true
	_player.input_enabled = false
	get_tree().paused = false


func _on_dialog_finished() -> void:
	_camera_locked = false
	_struggle_npc = null
	if _cutscene_live:
		_cutscene_live = false
		_player.input_enabled = true
	_player.model.process_mode = Node.PROCESS_MODE_INHERIT
	if not _player.is_dead:
		_player.model.play("Idle")
	if _talking_to and _talking_to.model:
		_talking_to.model.process_mode = Node.PROCESS_MODE_INHERIT
		_talking_to.model.play(_talking_to.idle_animation)
	_talking_to = null
	_player_cam.make_current()
	_hud.set_gameplay_visible(true)
	get_tree().paused = false


## Telltale tarzı karşılıklı omuz üstü çekimler: konuşan kişiyi göster.
func _on_speaker_changed(speaker_id: String) -> void:
	if _talking_to == null:
		return
	# Boğuşma ya da kilitli ara sahne kamerası sırasında duruşlar ve açı değişmez.
	if _camera_locked or _struggle_npc:
		return
	_player.model.play("Idle_Talking" if speaker_id == player_speaker_id else "Idle", 0.3)
	if _talking_to.model:
		_talking_to.model.play("Idle_Talking" if speaker_id == _talking_to.npc_id else _talking_to.idle_animation, 0.3)
	var a: Vector3 = _player.head_position()
	var b: Vector3 = _talking_to.head_position()
	var dir: Vector3 = (b - a).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if not _talking_to.model:
		# Nesne inceleme: oyuncunun omzunun üstünden aşağı bak
		_place_cam(a - dir * 1.2 + right * 0.7 + Vector3.UP * 0.4, b)
	elif speaker_id == _talking_to.npc_id:
		_place_cam(a - dir * 1.9 + right * 1.25 + Vector3.UP * 0.3, b - right * 0.35 - Vector3.UP * 0.1)
	elif speaker_id == "":
		var mid: Vector3 = (a + b) / 2.0
		_place_cam(mid - right * 4.5 + Vector3.UP * 0.8, mid - Vector3.UP * 0.3)
	else:
		_place_cam(b + dir * 1.9 - right * 1.25 + Vector3.UP * 0.3, a + right * 0.35 - Vector3.UP * 0.1)


## Diyalog dosyasındaki @olay satırları.
##   @olay anim KİŞİ Animasyon   -> karakter tek seferlik hareket yapar
##   @olay gorev Metin...        -> ekranın üstündeki görev yazısı
##   @olay sarsinti [güç] [süre] -> kamera sarsıntısı
## Diğer olaylar _on_story_event()'e iletilir.
func _on_dialog_event(event_name: String, args: PackedStringArray) -> void:
	match event_name:
		"anim":
			if args.size() >= 2:
				var model: CharacterModel = null
				if args[0] == player_speaker_id:
					model = _player.model
				elif _talking_to and args[0] == _talking_to.npc_id:
					model = _talking_to.model
				if model:
					model.play_once(args[1], "Idle")
		"gorev":
			_hud.set_objective(" ".join(args))
		"esya_al":
			Story.add_item(args[0])
			var item: Dictionary = Story.ITEMS.get(args[0], {"name": args[0]})
			_dialog.show_notification("Çantaya eklendi: " + item["name"])
		"esya_ver":
			Story.remove_item(args[0])
		"bogusma":
			_start_struggle()
		"bogusma_bitti":
			_struggle_npc = null
		"kamera":
			_set_camera(args[0] if args.size() > 0 else "otomatik")
		"sarsinti":
			shake(float(args[0]) if args.size() > 0 else 0.3, float(args[1]) if args.size() > 1 else 0.6)
		_:
			_on_story_event(event_name, args)


## Oyuncu ile konuşulan karakter karşı karşıya geçip itişir; kamera yandan çeker.
func _start_struggle() -> void:
	if _talking_to == null or _talking_to.model == null:
		return
	_struggle_npc = _talking_to
	var a := _player.global_position
	var b := _struggle_npc.global_position
	_struggle_dir = (b - a)
	_struggle_dir.y = 0.0
	_struggle_dir = _struggle_dir.normalized()
	_struggle_mid = (a + b) / 2.0
	_struggle_mid.y = a.y
	_apply_struggle(0.5)
	_player.model.play("Push", 0.1)
	_struggle_npc.model.play("Push", 0.1)
	var right := _struggle_dir.cross(Vector3.UP).normalized()
	var target := _struggle_mid + Vector3.UP * 1.1
	# Önü en açık yandaki açıyı seç (barikat/duvar arkasına düşmesin)
	var best := target + right * 2.4 + Vector3.UP * 0.4
	var best_free := -1.0
	for side in [1.0, -1.0]:
		for height in [0.4, 1.2]:
			for back in [-0.4, 0.8]:
				var cand: Vector3 = target + right * side * 2.4 + Vector3.UP * height + _struggle_dir * back
				var free := _unblocked(target, cand).distance_to(target)
				if free > best_free + 0.05:
					best_free = free
					best = cand
	camera_shots["_bogusma"] = [best, target]
	_set_camera("_bogusma")


## fill: 0 = oyuncu ezildi, 1 = oyuncu üstün geldi.
func _apply_struggle(fill: float) -> void:
	if _struggle_npc == null:
		return
	var shift := (fill - 0.5) * 0.6
	_player.global_position = _struggle_mid - _struggle_dir * (0.42 - shift)
	_struggle_npc.global_position = _struggle_mid + _struggle_dir * (0.42 + shift)
	_player.face_point(_struggle_npc.global_position)
	_struggle_npc.face_point(_player.global_position)


func _on_struggle_progress(fill: float) -> void:
	_apply_struggle(fill)


func _on_qte_death() -> void:
	shake(0.5, 0.5)
	_player.model.play("Death01", 0.1)


func _on_qte_retry() -> void:
	if _struggle_npc:
		_apply_struggle(0.5)
		_player.model.play("Push", 0.0)
		_struggle_npc.model.play("Push", 0.0)
	else:
		_player.model.play("Idle", 0.0)


# --- Eşya kullanma ve tüketme hareketleri ----------------------------------

var _using_item: bool = false


## Çantadan eşya kullanır: hareketi oynatır, ihtiyaçlara etkisini uygular, eşyayı azaltır.
func use_item(id: String) -> void:
	if _using_item or _dialog.active or _player.is_dead or not Story.has_item(id):
		return
	var item: Dictionary = Story.ITEMS.get(id, {})
	if not item.has("use"):
		return
	_using_item = true
	_player.input_enabled = false
	_player.velocity = Vector3.ZERO
	match item.get("action", ""):
		"icme":
			var bottle := Props.water_bottle()
			_player.model.attach(bottle, "hand_r", Vector3(0, 0.07, 0.04))
			await drink_sequence(bottle)
			_player.model.detach(bottle)
			bottle.queue_free()
		"yeme":
			var bar := Props.energy_bar()
			_player.model.attach(bar, "hand_r", Vector3(0, 0.06, 0.04), Vector3(0, 0, PI / 2))
			_player.model.play_once("Consume", "Idle", 0.2)
			await get_tree().create_timer(2.6, true, false, true).timeout
			_player.model.detach(bar)
			bar.queue_free()
	var effects: Dictionary = item["use"]
	for need_id in effects:
		Story.change_need(need_id, effects[need_id])
	Story.remove_item(id)
	_dialog.show_notification("%s kullanıldı." % item["name"])
	_player.input_enabled = true
	_using_item = false


## Elindeki şişeden (hand_r'ye takılı) içme: el ağza gider, dirsek yana bükülür, şişe yavaşça yatar.
func drink_sequence(bottle: Node3D) -> void:
	var vis: Node3D = _player.get_node("Visual")
	var mouth := Node3D.new()
	vis.add_child(mouth)
	mouth.position = Vector3(0.0, 1.6, -0.1)
	var hand_to := Node3D.new()
	vis.add_child(hand_to)
	hand_to.position = Vector3(0.07, 1.36, -0.2)
	var elbow := Node3D.new()
	vis.add_child(elbow)
	elbow.position = Vector3(0.38, 1.2, -0.1)
	_player.model.play("Idle", 0.2)
	_player.model.reach("r", hand_to, 0.5, elbow)
	var lift := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	lift.tween_property(hand_to, "position", Vector3(0.05, 1.5, -0.16), 0.6).set_delay(0.5)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(func(t: float) -> void:
		if is_instance_valid(bottle):
			var to_mouth := (mouth.global_position - bottle.global_position).normalized()
			var tilt := to_mouth.lerp(Vector3.UP.lerp(to_mouth, 0.6) + Vector3(0, -0.6, 0), clampf((t - 0.45) * 2.0, 0.0, 1.0))
			_aim_up(bottle, Vector3.UP.slerp(tilt.normalized(), clampf(t * 2.2, 0.0, 1.0))), 0.0, 1.0, 2.2)
	await tw.finished
	_player.model.release("r", 0.5)
	await get_tree().create_timer(0.5, true, false, true).timeout
	for n in [mouth, hand_to, elbow]:
		n.queue_free()


## Nesnenin Y eksenini (ör. şişenin ağzını) verilen yöne çevirir.
func _aim_up(node: Node3D, up: Vector3) -> void:
	if up.length() < 0.01:
		return
	up = up.normalized()
	var side := up.cross(Vector3.FORWARD)
	if side.length() < 0.01:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var fwd := side.cross(up).normalized()
	node.global_basis = Basis(side, up, fwd)


## Diyalog dışı ara sahne: oyuncu kontrolü durur, sinema bantları çıkar.
func cinematic(on: bool) -> void:
	_player.input_enabled = not on
	_hud.set_gameplay_visible(not on)
	_dialog.set_letterbox(on)


## Alt sınıfların hikâye olaylarını işlediği yer.
func _on_story_event(_event_name: String, _args: PackedStringArray) -> void:
	pass


## "oyuncu": oyuncunun kamerası, "otomatik": konuşana göre, diğerleri camera_shots'tan.
func _set_camera(shot: String) -> void:
	match shot:
		"oyuncu":
			_camera_locked = true
			_player_cam.make_current()
		"otomatik":
			_camera_locked = false
			_dialog_cam.make_current()
		_:
			if camera_shots.has(shot):
				_camera_locked = true
				var sh: Array = camera_shots[shot]
				if sh.size() > 2 and sh[2]:
					_place_cam_exact(sh[0], sh[1])
				else:
					_place_cam(sh[0], sh[1])
				_dialog_cam.make_current()


## Kamerayı yerleştirir: araya duvar/barikat giriyorsa önüne çeker,
## sonra TWD'deki gibi yavaşça kaydırıp hedefe yaklaştırır.
func _place_cam(from: Vector3, target: Vector3) -> void:
	from = _unblocked(target, from)
	if _cam_tween:
		_cam_tween.kill()
	var dir := (target - from).normalized()
	var right := dir.cross(Vector3.UP).normalized()
	var to := from + dir * 0.35 + right * 0.18
	to = _unblocked(target, to)
	_set_cam(from, target)
	_cam_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_cam_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_method(func(t: float) -> void: _set_cam(from.lerp(to, t), target), 0.0, 1.0, 7.0)


## Yakın inceleme çekimi: engel denetimi yok (hedef bir yüzeyin üstündeki yazı), çok hafif kayma.
func _place_cam_exact(from: Vector3, target: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	var to := from.lerp(target, 0.06)
	_set_cam(from, target)
	_cam_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_cam_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_method(func(t: float) -> void: _set_cam(from.lerp(to, t), target), 0.0, 1.0, 6.0)


func _set_cam(pos: Vector3, target: Vector3) -> void:
	_dialog_cam.global_position = pos
	if not pos.is_equal_approx(target):
		_dialog_cam.look_at(target, Vector3.UP)


## Hedef ile kamera arasında çarpışan bir şey varsa kamerayı onun önüne alır.
func _unblocked(target: Vector3, cam_pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(target, cam_pos, 1)
	var exclude: Array[RID] = [_player.get_rid()]
	if _talking_to:
		exclude.append(_talking_to.get_rid())
	if _struggle_npc:
		exclude.append(_struggle_npc.get_rid())
	q.exclude = exclude
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return cam_pos
	return hit["position"] + (target - cam_pos).normalized() * 0.3


func _on_npc_nearby(npc: Npc, is_near: bool) -> void:
	if is_near and npc.interactable:
		_nearby_npc = npc
	elif _nearby_npc == npc:
		_nearby_npc = null
	_hud.set_talk_available(_nearby_npc != null, _nearby_npc.prompt if _nearby_npc else "KONUŞ")


## Bir karakter etkileşime açılıp kapandığında yakınlık durumunu yeniler.
func refresh_interactions() -> void:
	_nearby_npc = null
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc.interactable and npc.is_player_near():
			_nearby_npc = npc
	_hud.set_talk_available(_nearby_npc != null, _nearby_npc.prompt if _nearby_npc else "KONUŞ")


# --- Kamera sarsıntısı -----------------------------------------------------

func shake(strength: float = 0.3, duration: float = 0.6) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)


func _update_shake(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var s := _shake_strength * clampf(_shake_time / 0.4, 0.0, 1.0)
		cam.h_offset = randf_range(-s, s)
		cam.v_offset = randf_range(-s, s)
	elif cam.h_offset != 0.0 or cam.v_offset != 0.0:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		_shake_strength = 0.0


# --- Dövüş ve toplama ------------------------------------------------------

func _on_gems_changed(collected: int, total: int) -> void:
	_hud.set_gems(collected, total)
	if total > 0 and collected >= total:
		_hud.show_message("Hücreler toplandı!")
		get_tree().paused = true


func _on_enemy_died() -> void:
	# Düşman ölüm sinyalinde gruptan çıkarıldı, kalanları say.
	_hud.set_enemies(get_tree().get_nodes_in_group("enemies").size())


func _on_player_died() -> void:
	_hud.show_message("Öldün!")
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
