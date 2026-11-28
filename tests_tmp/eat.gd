extends Node
## Enerji barı: arabadan alma ve yeme anı.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	var p = level._player
	p.global_position = Vector3(2.2, 0.1, 8.0)
	await t(0.5)
	level._start_dialog(level.get_node("Hotspots/Araba"))
	var n := 0
	for i in 900:
		await get_tree().process_frame
		if not d.active and i > 30: break
		if (d.runner.current_node == "ipucu_araba") and i % 15 == 0 and n < 16:
			get_viewport().get_texture().get_image().save_png(out + "/eat_a%02d.png" % n); n += 1
		if not d._waiting and i % 30 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	p.global_position = Vector3(0.0, 0.1, 14.0)
	p.face_point(Vector3(0, 0, 30))
	await t(0.3)
	var cam := Camera3D.new(); level.add_child(cam); cam.make_current()
	level.use_item("enerji_bari")
	for k in 6:
		var pp: Vector3 = p.global_position
		var fw: Vector3 = -p.get_node("Visual").global_basis.z
		cam.global_position = pp + fw * 1.3 + Vector3(0.4, 1.5, 0); cam.look_at(pp + Vector3(0, 1.3, 0))
		await t(0.4)
		get_viewport().get_texture().get_image().save_png(out + "/eat_b%d.png" % k)
	get_tree().quit()
