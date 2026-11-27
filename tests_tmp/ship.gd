extends Node
## Bölüm 2 görsel geçiş testi: her aşamada fotoğraf.
var level
var out := OS.get_environment("OUT")
var d
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif"); Story.set_var("cinsiyet", "k")
	Story.set_var("arman_olum", "kesici"); Story.add_item("kimlik_karti"); Story.add_item("kesici")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(n):
	get_viewport().get_texture().get_image().save_png(out + "/sh_" + n + ".png"); print("foto ", n, " düğüm=", d.runner.current_node, " faz=", level._phase)
func play_through(shots: Dictionary, picks: Dictionary = {}):
	var taken := {}
	for i in 5000:
		await get_tree().process_frame
		if not d.active: return
		var txt: String = d._text_label.text if d._panel.visible else ""
		for k in shots:
			if not taken.has(k) and txt.begins_with(k) and not d._typing:
				taken[k] = true
				await t(shots[k][1])
				snap(shots[k][0])
		if d._in_qte and d._qte.active:
			if Engine.get_process_frames() % 3 == 0: d._qte._hit()
			continue
		if d._typing:
			d._finish_typing()
			continue
		if not d._waiting and Engine.get_process_frames() % 10 == 0:
			d._block_input = 0
			if d._choosing:
				var pick := 0
				for k in picks:
					if d.runner.current_node == k: pick = picks[k]
				d._pick(pick)
			else: d._finish_typing(); d._advance()
func talk(id: String):
	var n = level._hot.get(id, level._npcs.get(id))
	level._player.global_position = n.global_position + Vector3(0.2, 0.1, 0.2)
	await t(0.4)
	level._start_dialog(n)
	await get_tree().process_frame
func _run():
	d = level._dialog
	while not d.active: await get_tree().process_frame
	await play_through({"Anadolu": ["01_giris", 1.0], "Gece boyunca": ["02_iskele", 1.0]})
	await t(0.5); snap("03_oyuncu")
	await talk("dunya"); await play_through({"Camın": ["04_liman", 0.6]})
	await talk("gorevli")
	await play_through({"Kartı cebinden": ["05_kart", 0.3], "Görevli karta": ["07_bakis", 0.3], "Yeşil": ["08_yesil", 0.3]})
	await t(1.5)
	level._player.global_position = Vector3(8, 0.1, 12.0)
	await t(1.5)
	await play_through({"Halka": ["10_meydan", 0.6]})
	level._player.global_position = Vector3(2.0, 0.1, 18.0); level._player.face_point(Vector3(-5, 0, 18))
	await t(0.6); snap("11_meydan_pencere")
	await talk("asansor"); await play_through({"SELIM: Sekiz": ["16_selim", 0.0], "Senin katın": ["17_asansor", 0.2]})
	await t(2.0); snap("18_guverte8")
	await talk("kapi412"); await play_through({"Kapı yana": ["20_kapi", 0.6]})
	level._player.global_position = level.Z2 + Vector3(3.0, 0.1, 7.0)
	await t(1.2)
	await play_through({"Dört metreye": ["21_kamara", 1.0]})
	await talk("pencere"); await play_through({"Pencereden": ["22_pencere", 0.5]})
	await talk("kutu"); await play_through({"Çerçeveyi eline": ["23_cerceve", 0.3]})
	await talk("kayit"); await play_through({"KAYIT": ["26_kayit", 0.6]})
	await talk("erzak"); await play_through({"Paketi alıp": ["28_paket", 0.3]})
	for i in 900:
		await get_tree().process_frame
		if d.active: break
	await play_through({"Zemindeki kapak": ["29_koltuk_acildi", 0.5]})
	await talk("koltuk"); await play_through({"Kemerler omuzlarından": ["31_kemer", 0.3], "Pencerede son": ["32_pencere", 0.3], "Tüm güvertelere": ["33_kopru", 0.6], "Füzyon çekirdeği": ["34_pilot", 0.6], "Ateşle.": ["35_reyes", 0.4], "Limanın ortasında": ["36_atesleme", 0.2], "Kamara titriyor": ["37_titreme", 0.3], "Koltuğun kollarına": ["38_tutun", 0.3], "Pencerede liman küçülüyor": ["39_gokyuzu", 0.5], "Ve aşağıda": ["40_dunya", 1.5], "Kemerler çözülüyor": ["41_son", 0.3]})
	await t(2.0)
	print("BİTTİ")
	get_tree().quit()
