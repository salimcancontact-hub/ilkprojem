extends Node
var level
var out := OS.get_environment("OUT")
var n := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(tag):
	get_viewport().get_texture().get_image().save_png(out + "/bt_%02d.png" % n); print("foto %02d %s düğüm=%s metin='%s' qte=%s" % [n, tag, level._dialog.runner.current_node, level._dialog._text_label.text.substr(0, 40) if level._dialog._panel.visible else "-", level._dialog._in_qte]); n += 1
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
	for i in 2400:
		await get_tree().process_frame
		if d.runner.current_node == "isyan_cop" and d._in_qte: break
		var txt: String = d._text_label.text
		if txt.begins_with("Kalabalık bir dalga"): shooting = true
		if shooting and i - last >= 6:
			last = i; snap("")
		if d._in_qte and d._qte.active:
			if d._qte._left < d._qte._time * 0.5: d._qte._end(true)
			continue
		if d.active and not d._waiting and i % 20 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
		if n > 40: break
	get_tree().quit()
