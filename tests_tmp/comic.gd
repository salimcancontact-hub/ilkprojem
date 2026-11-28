extends Node
## Giriş çizgi roman panelleri: her anlatım satırında birkaç kare (geçiş + Ken Burns + canlı hareket).
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	var n := 0
	for i in 2400:
		await get_tree().process_frame
		if not d.active and i > 60: break
		var node: String = d.runner.current_node if d.active else ""
		if node != "giris": continue
		if i % 20 == 0:
			get_viewport().get_texture().get_image().save_png(out + "/cm_%02d.png" % n); n += 1
		if not d._waiting and not d._typing and i % 150 == 0 and not d._holding_for_title:
			d._block_input = 0; d._advance()
	print("kare=", n)
	get_tree().quit()
