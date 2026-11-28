extends Node
## Kargaşada kalabalık: koşu bitince kimse yerinde koşmamalı.
var level
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	level._start_riot()
	await get_tree().create_timer(9.0).timeout
	var bad := 0
	for p: CharacterModel in level._crowd.get_children():
		if p.visible and p.current_animation() in ["Sprint", "Jog_Fwd"]:
			bad += 1
	print("YERİNDE KOŞAN: ", bad, " / görünür ", level._crowd.get_children().filter(func(x): return x.visible).size())
	get_tree().quit()
