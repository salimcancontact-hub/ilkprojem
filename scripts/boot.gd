extends Control
## Açılış ekranı: cihaz bilgisi, önceki çökme bilgisi, bölüm seçimi ve yükleme çubuğu.

const SCENES := {
	"onsoz": "res://scenes/onsoz.tscn",
	"bolum1": "res://scenes/main.tscn",
}

var _loading: String = ""
var _bar: ProgressBar
var _status: Label
var _buttons: HBoxContainer


func _ready() -> void:
	var crash := Game.previous_boot_failure()
	Game.boot_log("açılış ekranı", true)
	var info := "%s | %s | %s" % [OS.get_model_name(), RenderingServer.get_video_adapter_name(), OS.get_name()]
	Game.boot_log("cihaz: " + info)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	var title := _label("EMANET", 96, Color(0.92, 0.55, 0.22))
	box.add_child(title)
	box.add_child(_label("Bir hikâye. Beş yüz isim. Tek bir soru.", 26, Color(0.75, 0.78, 0.85)))

	if not crash.is_empty():
		var warn := _label("Önceki açılış yarıda kaldı. Son adımlar:\n" + crash, 20, Color(1.0, 0.55, 0.45))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.custom_minimum_size = Vector2(900, 0)
		box.add_child(_centered(warn))

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 30)
	box.add_child(_buttons)
	_buttons.add_child(_button("ÖNSÖZ: Seçim Gecesi", "onsoz"))
	_buttons.add_child(_button("BÖLÜM 1: İlk İniş", "bolum1"))

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(600, 14)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.visible = false
	box.add_child(_centered(_bar))
	_status = _label("", 20, Color(0.6, 0.65, 0.75))
	box.add_child(_status)

	var foot := _label("v" + str(ProjectSettings.get_setting("application/config/version", "0.2.0")) + "   " + info, 16, Color(0.4, 0.42, 0.5))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.position.y -= 34
	add_child(foot)


func _process(_delta: float) -> void:
	if _loading.is_empty():
		return
	var progress := []
	var state := ResourceLoader.load_threaded_get_status(_loading, progress)
	match state:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_bar.value = progress[0] if progress.size() > 0 else 0.0
		ResourceLoader.THREAD_LOAD_LOADED:
			Game.boot_log("sahne dosyası yüklendi, kuruluyor")
			_status.text = "Sahne kuruluyor..."
			var scene: PackedScene = ResourceLoader.load_threaded_get(_loading)
			_loading = ""
			await get_tree().process_frame
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			Game.boot_log("HATA: sahne yüklenemedi")
			_status.text = "Sahne yüklenemedi."
			_loading = ""


func _start(key: String) -> void:
	if not _loading.is_empty():
		return
	_loading = SCENES[key]
	Game.boot_log("yükleniyor: " + key)
	_buttons.visible = false
	_bar.visible = true
	_status.text = "Yükleniyor..."
	ResourceLoader.load_threaded_request(_loading)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, key: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 90)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(_start.bind(key))
	return b


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
