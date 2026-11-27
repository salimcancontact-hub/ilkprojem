extends Node
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Kerem")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	var k := 0
	for i in 2000:
		await get_tree().process_frame
		if d.active and not d._waiting and i % 6 == 0:
			d._block_input = 0
			if d._name_label.visible and d._name_label.text == "Ada" and k < 2:
				d._finish_typing(); await t(0.4)
				get_viewport().get_texture().get_image().save_png(out + "/call_%d.png" % k); print("foto"); k += 1
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
		if k >= 2: break
	get_tree().quit()
