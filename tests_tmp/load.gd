extends SceneTree
func _initialize():
	for p in ["res://scripts/levels/binis.gd","res://scripts/levels/gemi_set.gd","res://scripts/levels/onsoz.gd","res://scripts/main.gd","res://scripts/dialog/dialog_ui.gd","res://scripts/boot.gd"]:
		var s = load(p)
		print(p, " ", s != null and s.can_instantiate())
	quit()
