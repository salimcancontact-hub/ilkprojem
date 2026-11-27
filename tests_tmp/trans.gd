extends Node
var f := 0
var level
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T"); Story.add_item("kimlik_karti")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
func _process(_d):
	f += 1
	var cs = get_tree().current_scene
	if f % 30 == 0: print("f=", f, " sahne=", cs.name if cs else "YOK", " faz=", level._phase if is_instance_valid(level) else "-")
	if f == 200:
		level._phase = "kart"; level._final()
	if is_instance_valid(level) and level._dialog.active and not level._dialog._waiting and f % 6 == 0:
		level._dialog._block_input = 0; level._dialog._finish_typing(); level._dialog._advance()
	if cs and cs.name == "Binis" and f % 30 == 0: print("Binis faz=", cs._phase)
	if f > 2500: get_tree().quit()
