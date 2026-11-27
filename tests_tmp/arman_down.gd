extends Node
## Şişe sonrası: muhafız düşer, Arman kalabalıkta yere düşer, yardım/kaç, kalkış. Kare kare fotoğraf.
## YOL=yardim|kalkamadi|kac
var level
var out := OS.get_environment("OUT")
var yol := OS.get_environment("YOL")
var n := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap():
	var d = level._dialog
	get_viewport().get_texture().get_image().save_png(out + "/ad_%s_%02d.png" % [yol, n]); print("foto %02d düğüm=%s metin='%s' qte=%s" % [n, d.runner.current_node, d._text_label.text.substr(0, 45) if d._panel.visible else "-", d._in_qte]); n += 1
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	level._player.global_position = Vector3(0.2, 0.1, 56.9)
	await t(0.4)
	Story.set_var("gorev_muhafiz", true)
	level._start_dialog(level._guard)
	var shooting := false
	var last := 0
	for i in 4000:
		await get_tree().process_frame
		var txt: String = d._text_label.text
		if txt.begins_with("Muhafızı itip"): shooting = true
		if shooting and i - last >= 9:
			last = i; snap()
		if shooting and not d.active: break
		if n > 60: break
		if d._in_qte and d._qte.active:
			var win: bool = not (yol == "kalkamadi" and d.runner.current_node == "arman_yardim")
			if d._qte._kind == "vur":
				if win and i % 3 == 0: d._qte._hit()
			elif d._qte._left < d._qte._time * 0.5: d._qte._end(true)
			continue
		if d.active and not d._waiting and i % 24 == 0:
			d._block_input = 0
			if d._choosing:
				d._pick(1 if (yol == "kac" and d.runner.current_node == "isyan_arman") else 0)
			else: d._finish_typing(); d._advance()
	for k in 6:
		await t(0.5); snap()
	get_tree().quit()
