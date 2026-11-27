extends Control
## Açılış ekranı: YENİ OYUN -> isim girişi -> yükleme.
## Ayrıca cihaz bilgisi, önceki çökme bilgisi ve grafik kalitesi seçimi.

const GAME_SCENE := "res://scenes/onsoz.tscn"
const DEFAULT_NAME := "Evren"

var _loading: String = ""
var _bar: ProgressBar
var _status: Label
var _menu: VBoxContainer
var _name_box: VBoxContainer
var _name_edit: LineEdit
var _gender: String = "e"
var _gender_buttons: Dictionary = {}


func _ready() -> void:
	_clear_shader_cache()
	var crash := Game.previous_boot_failure()
	Game.boot_log("açılış ekranı", true)
	var info := "%s | %s | %s" % [OS.get_model_name(), RenderingServer.get_video_adapter_name(), OS.get_name()]
	Game.boot_log("cihaz: " + info)
	Game.boot_log(ToonStyle.quality_label())

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	box.add_child(_label("EMANET", 96, Color(0.92, 0.55, 0.22)))
	box.add_child(_label("Bir hikâye. Beş yüz isim. Tek bir soru.", 26, Color(0.75, 0.78, 0.85)))

	if not crash.is_empty():
		var warn := _label("Önceki açılış yarıda kaldı. Son adımlar:\n" + crash, 20, Color(1.0, 0.55, 0.45))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.custom_minimum_size = Vector2(900, 0)
		box.add_child(_centered(warn))

	# Ana menü
	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", 16)
	box.add_child(_menu)
	if Game.has_checkpoint():
		var cont := _button("DEVAM ET", 32, Vector2(420, 96))
		cont.pressed.connect(_continue)
		_menu.add_child(_centered(cont))
	var start := _button("YENİ OYUN", 32, Vector2(420, 96))
	start.pressed.connect(_show_name_entry)
	_menu.add_child(_centered(start))
	var q := _button(ToonStyle.quality_label(), 20, Vector2(320, 56))
	q.pressed.connect(func() -> void:
		var order := ["otomatik", "dusuk", "yuksek"]
		ToonStyle.set_quality(order[(order.find(ToonStyle.quality_setting) + 1) % order.size()])
		q.text = ToonStyle.quality_label())
	_menu.add_child(_centered(q))

	# İsim girişi
	_name_box = VBoxContainer.new()
	_name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_name_box.add_theme_constant_override("separation", 16)
	_name_box.visible = false
	box.add_child(_name_box)
	_name_box.add_child(_label("Adın ne?", 34, Color(0.95, 0.92, 0.85)))
	_name_edit = LineEdit.new()
	_name_edit.text = DEFAULT_NAME
	_name_edit.max_length = 16
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.custom_minimum_size = Vector2(420, 70)
	_name_edit.add_theme_font_size_override("font_size", 32)
	_name_edit.text_submitted.connect(func(_t: String) -> void: _start())
	_name_box.add_child(_centered(_name_edit))
	_name_box.add_child(_label("Kimsin?", 24, Color(0.95, 0.92, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var group := ButtonGroup.new()
	for g in [["e", "ERKEK"], ["k", "KADIN"]]:
		var b := _button(g[1], 26, Vector2(200, 76))
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = g[0] == _gender
		var code: String = g[0]
		b.pressed.connect(func() -> void: _gender = code)
		_gender_buttons[code] = b
		row.add_child(b)
	_name_box.add_child(_centered(row))
	_name_box.add_child(_label("Bu gece bu isimle başlayacaksın. Sonra başka bir isim taşıyacaksın.", 20, Color(0.6, 0.65, 0.75)))
	var go := _button("BAŞLA", 30, Vector2(320, 86))
	go.pressed.connect(_start)
	_name_box.add_child(_centered(go))

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(600, 14)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.visible = false
	box.add_child(_centered(_bar))
	_status = _label("", 20, Color(0.6, 0.65, 0.75))
	box.add_child(_status)

	var foot := _label("v" + str(ProjectSettings.get_setting("application/config/version", "")) + "   " + info, 16, Color(0.4, 0.42, 0.5))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.position.y -= 34
	add_child(foot)


func _show_name_entry() -> void:
	_menu.visible = false
	_name_box.visible = true
	_name_edit.grab_focus()
	_name_edit.select_all()


func _start() -> void:
	if not _loading.is_empty():
		return
	var name := _name_edit.text.strip_edges()
	if name.is_empty():
		name = DEFAULT_NAME
	Story.vars.clear()
	Story.set_var("oyuncu_adi", name.substr(0, 1).to_upper() + name.substr(1))
	Story.set_var("cinsiyet", _gender)
	_name_box.visible = false
	_loading = GAME_SCENE
	Game.boot_log("yükleniyor: oyun")
	_bar.visible = true
	_status.text = "Yükleniyor..."
	ResourceLoader.load_threaded_request(_loading)


## Son bölümün başından devam eder.
func _continue() -> void:
	if not _loading.is_empty():
		return
	var scene := Game.load_checkpoint()
	if scene.is_empty():
		return
	_menu.visible = false
	_loading = scene
	Game.boot_log("yükleniyor: kayıt " + scene)
	_bar.visible = true
	_status.text = "Yükleniyor..."
	ResourceLoader.load_threaded_request(_loading)


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


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, font_size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


## Eski sürümlerin diske yazdığı gölgelendirici önbelleğini siler. PowerVR sürücüsü bu kayıtlı
## ikili gölgelendiricileri sonraki açılışlarda okurken çökebiliyor (önbellek artık kapalı).
func _clear_shader_cache() -> void:
	var root := "user://shader_cache"
	if not DirAccess.dir_exists_absolute(root):
		return
	_remove_dir(root)
	Game.boot_log("eski gölgelendirici önbelleği silindi")


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	for d in dir.get_directories():
		_remove_dir(path.path_join(d))
	DirAccess.remove_absolute(path)
