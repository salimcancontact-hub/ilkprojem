extends Node
## Biniş kapısı: oyuncu uzaktan görevliye tıklar -> işarete yürür (kaymadan), kartı çıkarır, okutur.
## Kare başı en büyük sıçrama ölçülür (ışınlanma yok), kareler çekilir.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	await t(1.0)
	level._player.global_position = Vector3(7.0, level._player.global_position.y, 3.5)
	await t(0.5)
	level._start_dialog(level._npcs["gorevli"])
	var last: Vector3 = level._player.global_position
	var maxjump := 0.0
	var n := 0
	var anims := {}
	for i in 900:
		await get_tree().process_frame
		var p: Vector3 = level._player.global_position
		var j := Vector2(p.x - last.x, p.z - last.z).length()
		if j > maxjump: maxjump = j
		last = p
		anims[level._player.model._current] = true
		var node: String = d.runner.current_node if d.active else "-"
		if i % 8 == 0 and n < 24:
			get_viewport().get_texture().get_image().save_png(out + "/rd_%02d.png" % n); print("foto %d %s p=%s anim=%s" % [n, node, p, level._player.model._current]); n += 1
		if d.active and not d._waiting and not d._typing and i % 30 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._advance()
		if not d.active and i > 100: break
	print("EN BÜYÜK KARE SIÇRAMASI=%.3f m  animler=%s" % [maxjump, anims.keys()])
	get_tree().quit()
