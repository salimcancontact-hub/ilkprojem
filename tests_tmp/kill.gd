extends Node
## Karar anı ve öldürme açıları (yolları: bogma, kesici, yalvar), yazı kutusu varken.
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
	var pick := int(OS.get_environment("PICK"))
	var shots := 0
	for i in 6000:
		await get_tree().process_frame
		if not d.active: break
		var node: String = d.runner.current_node
		if d._in_qte and d._qte.active:
			if d._qte._kind == "vur":
				if i % 3 == 0: d._qte._hit()
			elif d._qte._left < d._qte._time * 0.6: d._qte._end(true)
			continue
		if (node.begins_with("karar") or node == "olum" or node.contains("bogma")) and d._panel.visible and not d._typing and i % 20 == 0 and shots < 8:
			await t(0.3)
			get_viewport().get_texture().get_image().save_png(out + "/kl_%d_%02d.png" % [pick, shots]); print("foto ", node); shots += 1
		if not d._waiting and i % 25 == 0:
			d._block_input = 0
			if d._choosing: d._pick(pick if node == "karar_ani" else 0)
			else: d._finish_typing(); d._advance()
		if node.begins_with("karar_") and node != "karar_ani" and i % 12 == 0 and shots < 12:
			get_viewport().get_texture().get_image().save_png(out + "/kl_%d_%02d.png" % [pick, shots]); print("foto ", node); shots += 1
		if node in ["karar_bogma", "karar_zaman", "karar_yalvar", "yalvar_son"] and i % 15 == 0:
			var pm = level._player.model
			var rd = level._arman.model.ragdoll
			if rd:
				var hr: Vector3 = pm.bone_position("hand_r")
				var hl: Vector3 = pm.bone_position("hand_l")
				var hd: Vector3 = rd.bone("Head").global_position
				var foot: Vector3 = level._arman.model.skeleton.global_transform * level._arman.model.skeleton.get_bone_global_pose(level._arman.model.skeleton.find_bone("foot_l")).origin
				print("ÖLÇÜM %s el_sağ-baş=%.2f el_sol-baş=%.2f el_sağ-ayak=%.2f baş=%s" % [node, hr.distance_to(hd), hl.distance_to(hd), hr.distance_to(foot), hd])
		if level._phase == "kart": break
	get_tree().quit()
