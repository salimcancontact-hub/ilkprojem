extends Node
## Öldürme sonrası: kanlı eller (olum) ve sürüklerken kan izi (ceset_sakla) kare kare.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	level._phase = "isyan"
	level._on_alley_entered(level._player)
	await t(0.5)
	level._player.global_position = level._arman.global_position + Vector3(-1.4, 0.1, 0.2)
	await t(0.3)
	level._start_dialog(level._arman)
	d.event_fired.connect(func(e, _a): printerr("EVENT ", e))
	var pick := int(OS.get_environment("PICK"))
	var shots := 0
	var drag_t := -1.0
	var second := false
	for i in 12000:
		await get_tree().process_frame
		if not d.active:
			if second: break
			if level._phase == "kart":
				second = true
				await t(0.5)
				level._start_dialog(level._card)
				await t(0.2)
			continue
		var node: String = d.runner.current_node
		if node != get_meta("last", ""):
			set_meta("last", node); print("NODE ", node, " faz=", level._phase)
		if d._in_qte and d._qte.active:
			if d._qte._kind == "vur":
				if i % 3 == 0: d._qte._hit()
			elif d._qte._left < d._qte._time * 0.6: d._qte._end(true)
			continue
		if node == "olum" and i % 10 == 0:
			get_viewport().get_texture().get_image().save_png(out + "/dr_el_%02d.png" % shots); shots += 1
		if node == "ceset_sakla":
			if drag_t < 0: drag_t = 0.0
			drag_t += get_process_delta_time()
			if i % 15 == 0:
				get_viewport().get_texture().get_image().save_png(out + "/dr_%02d.png" % shots); print("foto sürükle ", drag_t, " iz=", level._trail.size()); shots += 1
		if not d._waiting and i % 25 == 0:
			d._block_input = 0
			if d._choosing: d._pick(pick if node == "karar_ani" else 0)
			else: d._finish_typing(); d._advance()
	print("bitti iz=", level._trail.size())
	get_tree().quit()
