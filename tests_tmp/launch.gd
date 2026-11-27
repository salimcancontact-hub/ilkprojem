extends Node
## Kalkış: köprü, kamarada gürleme, TUTUN (kolçak sıkma), pencereden yükseliş. 1 sn'de bir fotoğraf.
## FAIL=1 ise TUTUN kaybedilir (bayılma yolu).
var level
var out := OS.get_environment("OUT")
var fail := OS.get_environment("FAIL") == "1"
var n := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif"); Story.set_var("cinsiyet", "k")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(tag := ""):
	var d = level._dialog
	get_viewport().get_texture().get_image().save_png(out + "/ln_%s%02d.png" % ["f" if fail else "", n]); print("foto %02d %s düğüm=%s metin='%s'" % [n, tag, d.runner.current_node, d._text_label.text.substr(0, 40) if d._panel.visible else "-"]); n += 1
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	level._set_zone(1, false); level._set_zone(2, true)
	level._phase = "anons"
	level._player.global_position = level.Z2 + Vector3(4.0, 0.1, 7.0)
	await level._raise_seat()
	await level._sit()
	level._on_story_event("kemer_bagla", PackedStringArray())
	await t(1.5)
	level.play_dialog(level.DLG, "kalkis")
	var next_snap := 0
	for i in 3600:
		await get_tree().process_frame
		if not d.active and i > 30: break
		if i >= next_snap:
			next_snap = i + 30
			snap()
		if d._in_qte and d._qte.active:
			if not fail and i % 7 == 0: d._qte._hit()
			continue
		if not d._waiting and not d._in_qte and i % 45 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	get_tree().quit()
