extends Node
var out := OS.get_environment("OUT")
func _ready():
	LoadingOverlay.show_on(self)
	for i in 3:
		await get_tree().create_timer(0.7).timeout
		get_viewport().get_texture().get_image().save_png(out + "/lo_%d.png" % i)
	get_tree().quit()
