extends Node
## Aynı sahneleri farklı yön/mesafeden başlatır (ANG=derece, DIST=m) ve her karede kamerayı denetler:
## duvar içi, ekranı kaplayan yakın yüzey, oyuncu/konuşulan örtülü. Sorunlu ilk kareyi kaydeder.
var level
var out := OS.get_environment("OUT")
var ang := float(OS.get_environment("ANG"))
var dist := float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else 2.2
var bad := {}
var checks := 0
var starts := {}
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(int(ang) + 7)
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func off() -> Vector3: return Vector3(sin(deg_to_rad(ang)), 0, cos(deg_to_rad(ang))) * dist
func _play(d, pick_fn: Callable) -> void:
	var i := 0
	# İşarete yürüyüş bitip diyalog başlayana kadar bekle
	for k in 600:
		if d.active: break
		await get_tree().process_frame
	var last_node := ""
	while d.active:
		await get_tree().process_frame
		i += 1
		var node: String = d.runner.current_node
		if node != last_node:
			last_node = node
			# Sahne başında oyuncunun durduğu yer (her yaklaşımda aynı olmalı)
			starts[node] = level._player.global_position
			set_meta("node_i", i)
		if i - int(get_meta("node_i", 0)) == 45 and node in ["muhafiz", "isyan_arman", "arman_yardim", "ara_sokak", "karar_ani", "kart_al", "ceset"]:
			get_viewport().get_texture().get_image().save_png("%s/shot_%d_%s.png" % [out, int(ang), node])
		if i % 6 == 0 and not d._in_qte:
			var p: String = level.camera_problems()
			checks += 1
			if p != "":
				var key: String = node + ": " + p.split(" (")[0]
				if not bad.has(key):
					bad[key] = true
					var fn := "%s/ca_%d_%s.png" % [out, int(ang), node]
					get_viewport().get_texture().get_image().save_png(fn)
					print("SORUN açı=%d %s -> %s" % [int(ang), node, p])
		if d._in_qte and d._qte.active:
			if d._qte._kind == "vur":
				if i % 3 == 0: d._qte._hit()
			elif d._qte._left < d._qte._time * 0.6: d._qte._end(true)
			continue
		if not d._waiting and i % 20 == 0:
			d._block_input = 0
			if d._choosing: d._pick(pick_fn.call(node))
			else: d._finish_typing(); d._advance()
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	Story.set_var("gorev_muhafiz", true)
	# Muhafıza farklı yönden yaklaş
	level._player.global_position = level._guard.global_position + off() + Vector3(0, 0.1, 0)
	await t(0.4)
	level._start_dialog(level._guard)
	await t(0.2)
	await _play(d, func(n): return 0)
	print("muhafız/isyan bitti faz=", level._phase)
	# Ara sokak: Arman'a farklı yönden
	level._phase = "isyan"
	level._on_alley_entered(level._player)
	await t(1.0)
	level._player.global_position = level._arman.global_position + off() * 0.8 + Vector3(0, 0.1, 0)
	await t(0.4)
	level._start_dialog(level._arman)
	await t(0.2)
	await _play(d, func(n): return 1 if n == "karar_ani" else 0)
	await t(0.5)
	if level._phase == "kart":
		level._player.global_position = level._card.global_position + off() * 0.7 + Vector3(0, 0.1, 0)
		await t(0.3)
		level._start_dialog(level._card)
		await t(0.2)
		await _play(d, func(n): return 0)
	for k in ["muhafiz", "isyan_arman", "ara_sokak", "kart"]:
		if starts.has(k): print("BAŞLANGIÇ açı=%d %s %s" % [int(ang), k, starts[k]])
	print("DENETİM açı=%d mesafe=%.1f kontrol=%d sorunlu=%d" % [int(ang), dist, checks, bad.size()])
	get_tree().quit()
