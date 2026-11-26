extends CanvasLayer
## Telltale tarzı diyalog arayüzü: sinema bantları, harf harf yazı, zamanlı seçimler, bildirimler.

signal dialog_started
signal dialog_finished
## Konuşan karakter değişti ("" = anlatım). Kamera açıları için kullanılır.
signal speaker_changed(speaker_id: String)
signal event_fired(event_name: String, args: PackedStringArray)
## Boğuşma QTE'lerinde güç değişimi (0..1) ve her dokunuş.
signal qte_progress(fill: float)
signal qte_tapped
## Ölümcül bir QTE kaybedildi (karakter ölür) / yeniden deneniyor.
signal qte_death
signal qte_retry

const TYPE_SPEED := 45.0
const BAR_HEIGHT := 86.0
const SIDE_MARGIN := 60.0

var active: bool = false
var runner := DialogRunner.new()

var _typing := false
var _chars := 0.0
var _choosing := false
var _choice_time := 0.0
var _choice_total := 0.0
var _block_input := 0.0
var _toast_tween: Tween

var _root: Control
var _tap: Control
var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _timer_bar: ProgressBar
var _grid: GridContainer
var _toast: PanelContainer
var _toast_label: Label
var _fade: ColorRect
var _title: Label
var _subtitle: Label
var _fade_tween: Tween
var _qte: Control
var _in_qte: bool = false
var _qte_step: Dictionary = {}
var _waiting: bool = false
var _title_tween: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	runner.line_shown.connect(_on_line)
	runner.narration_shown.connect(_on_narration)
	runner.choices_shown.connect(_on_choices)
	runner.notification_shown.connect(show_notification)
	runner.event_fired.connect(_on_runner_event)
	runner.finished.connect(_on_finished)
	runner.qte_started.connect(_on_qte)
	runner.wait_requested.connect(_on_wait)


## Bir .dlg dosyasını verilen düğümden başlatır.
func start(path: String, node_name: String = "baslangic") -> void:
	var nodes := DialogParser.load_file(path)
	if not nodes.has(node_name):
		push_error("Diyalog başlatılamadı: %s / %s" % [path, node_name])
		return
	active = true
	_block_input = 0.3
	_root.visible = true
	_panel.visible = false
	_choice_box.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_top_bar, "offset_bottom", BAR_HEIGHT, 0.35)
	tw.tween_property(_bottom_bar, "offset_top", -BAR_HEIGHT, 0.35)
	dialog_started.emit()
	runner.start(nodes, node_name)


## Ekranı karartır (1) veya açar (0). Diyalog dışında da kullanılabilir.
func fade_to(alpha: float, time: float = 1.0) -> void:
	if _fade_tween:
		_fade_tween.kill()
	if time <= 0.0:
		_fade.color.a = alpha
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "color:a", alpha, time)
	await _fade_tween.finished


## Ekranın ortasında sinematik başlık kartı.
func show_title(text: String, subtitle: String = "", hold: float = 2.5) -> void:
	_title.text = text
	_subtitle.text = subtitle
	if _title_tween:
		_title_tween.kill()
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, 0.8)
	_title_tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, 1.2).set_delay(0.4)
	_title_tween.tween_interval(hold)
	_title_tween.tween_property(_title, "modulate:a", 0.0, 0.8)
	_title_tween.parallel().tween_property(_subtitle, "modulate:a", 0.0, 0.8)
	await _title_tween.finished


## Arayüzle ilgili olaylar burada işlenir, hepsi seviyeye de iletilir.
##   @olay siyah | @olay kararti [sn] | @olay aydinlat [sn] | @olay baslik Metin | Alt yazı
func _on_wait(seconds: float) -> void:
	_finish_typing()
	_waiting = true
	_panel.visible = false
	await get_tree().create_timer(seconds, true, false, true).timeout
	_waiting = false
	if active:
		runner.advance()


## Diyalog dışında da sinema bantları (ara sahneler için).
func set_letterbox(on: bool, time: float = 0.4) -> void:
	_root.visible = on or active
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_top_bar, "offset_bottom", BAR_HEIGHT if on else 0.0, time)
	tw.tween_property(_bottom_bar, "offset_top", -BAR_HEIGHT if on else 0.0, time)


func _on_qte(step: Dictionary) -> void:
	_finish_typing()
	_in_qte = true
	_qte_step = step.duplicate()
	_choice_box.visible = false
	_panel.visible = false  # TWD'deki gibi QTE sırasında yazı yok, sadece sahne
	_qte.start(_qte_step)


func _on_qte_finished(success: bool) -> void:
	if not success and _qte_step.get("lethal", false):
		await _death_and_retry()
		return
	_in_qte = false
	_panel.visible = false
	_set_panel_raised(false)
	runner.finish_qte(success)


## TWD tarzı: ekran kırmızıya keser, karakter ölür, aynı an biraz kolaylaşarak tekrarlanır.
func _death_and_retry() -> void:
	qte_death.emit()
	_panel.visible = false
	var old := _fade.color
	_fade.color = Color(0.45, 0.0, 0.0, 0.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.85, 0.5)
	await tw.finished
	show_title("ÖLDÜN", "Tekrar dene", 1.2)
	await get_tree().create_timer(2.6, true, false, true).timeout
	qte_retry.emit()
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.6)
	await tw2.finished
	_fade.color = Color(0, 0, 0, 0)
	# Her denemede biraz daha kolay
	_qte_step["time"] = _qte_step["time"] * 1.15
	_qte_step["count"] = maxi(int(_qte_step["count"]) - 2, 4)
	_qte.start(_qte_step)


func _on_runner_event(event_name: String, args: PackedStringArray) -> void:
	var t := float(args[0]) if args.size() > 0 and args[0].is_valid_float() else 1.0
	match event_name:
		"siyah":
			fade_to(1.0, 0.0)
		"kararti":
			fade_to(1.0, t)
		"aydinlat":
			fade_to(0.0, t)
		"baslik":
			var parts := " ".join(args).split("|")
			show_title(parts[0].strip_edges(), parts[1].strip_edges() if parts.size() > 1 else "")
	event_fired.emit(event_name, args)


func show_notification(text: String) -> void:
	_toast_label.text = Story.format_text(text)
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 0.0
	_toast.position.x = -20.0
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.3)
	_toast_tween.tween_property(_toast, "position:x", 24.0, 0.3)
	_toast_tween.chain().tween_interval(2.5)
	_toast_tween.chain().tween_property(_toast, "modulate:a", 0.0, 0.6)


func _process(delta: float) -> void:
	if not active:
		return
	_block_input = maxf(_block_input - delta, 0.0)
	if _typing:
		_chars += TYPE_SPEED * delta
		_text_label.visible_characters = int(_chars)
		if _chars >= _text_label.get_total_character_count():
			_finish_typing()
	if _choosing and _choice_total > 0.0:
		_choice_time -= delta
		_timer_bar.value = maxf(_choice_time / _choice_total, 0.0)
		if _choice_time <= 0.0:
			_hide_choices()
			runner.choose_timeout()


func _input(event: InputEvent) -> void:
	if not active or _in_qte or _waiting:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if _choosing and key >= KEY_1 and key <= KEY_4:
			_pick(key - KEY_1)
			get_viewport().set_input_as_handled()
		elif not _choosing and (key == KEY_SPACE or key == KEY_ENTER or key == KEY_KP_ENTER):
			_advance()
			get_viewport().set_input_as_handled()


func _on_tap(event: InputEvent) -> void:
	if _in_qte or _waiting:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _choosing:
			_advance()


func _advance() -> void:
	if _block_input > 0.0:
		return
	if _typing:
		_finish_typing()
	else:
		runner.advance()


func _on_line(speaker: String, text: String) -> void:
	var info := Story.speaker_info(speaker)
	_name_label.text = info["name"]
	_name_label.add_theme_color_override("font_color", info["color"])
	_name_label.visible = true
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	_show_text(text)
	speaker_changed.emit(speaker)


func _on_narration(text: String) -> void:
	_name_label.visible = false
	_text_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	_show_text(text)
	speaker_changed.emit("")


func _show_text(text: String) -> void:
	_panel.visible = true
	_set_panel_raised(false)
	_text_label.text = Story.format_text(text)
	_text_label.visible_characters = 0
	_chars = 0.0
	_typing = true


func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1


func _on_choices(options: PackedStringArray, timeout: float) -> void:
	_finish_typing()
	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = 2 if options.size() > 1 else 1
	for i in options.size():
		var btn := Button.new()
		btn.text = Story.format_text(options[i])
		btn.custom_minimum_size = Vector2(0, 78)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_stylebox_override("normal", _button_style(Color(0.05, 0.07, 0.1, 0.85)))
		btn.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.25, 0.35, 0.95)))
		btn.add_theme_stylebox_override("pressed", _button_style(Color(0.25, 0.45, 0.6, 1.0)))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(_pick.bind(i))
		_grid.add_child(btn)
	_choice_total = timeout
	_choice_time = timeout
	_timer_bar.visible = timeout > 0.0
	_timer_bar.value = 1.0
	_choosing = true
	_choice_box.visible = true
	_set_panel_raised(true)


func _pick(index: int) -> void:
	if not _choosing or index >= _grid.get_child_count():
		return
	_hide_choices()
	runner.choose(index)


func _hide_choices() -> void:
	_choosing = false
	_choice_box.visible = false
	_set_panel_raised(false)
	_panel.visible = false


func _on_finished() -> void:
	active = false
	_typing = false
	_choosing = false
	_panel.visible = false
	_choice_box.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_top_bar, "offset_bottom", 0.0, 0.35)
	tw.tween_property(_bottom_bar, "offset_top", 0.0, 0.35)
	tw.chain().tween_callback(func() -> void: _root.visible = active)
	dialog_finished.emit()


## Seçenekler görünürken replik kutusu yukarı kayar.
func _set_panel_raised(raised: bool) -> void:
	var bottom := BAR_HEIGHT + (230.0 if raised else 16.0)
	_panel.offset_bottom = -bottom
	_panel.offset_top = -bottom - 150.0


func _build_ui() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	var title_box := VBoxContainer.new()
	title_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_title.modulate.a = 0.0
	title_box.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 28)
	_subtitle.add_theme_color_override("font_color", Color(0.85, 0.6, 0.35))
	_subtitle.modulate.a = 0.0
	title_box.add_child(_subtitle)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_tap = Control.new()
	_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tap.gui_input.connect(_on_tap)
	_root.add_child(_tap)

	_top_bar = ColorRect.new()
	_top_bar.color = Color.BLACK
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 0.0
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_top_bar)

	_bottom_bar = ColorRect.new()
	_bottom_bar.color = Color.BLACK
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = 0.0
	_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bottom_bar)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = SIDE_MARGIN
	_panel.offset_right = -SIDE_MARGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.6)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(18)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	_panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_name_label)
	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 28)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_label)
	_set_panel_raised(false)

	_choice_box = VBoxContainer.new()
	_choice_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_choice_box.offset_left = SIDE_MARGIN
	_choice_box.offset_right = -SIDE_MARGIN
	_choice_box.offset_top = -BAR_HEIGHT - 215.0
	_choice_box.offset_bottom = -BAR_HEIGHT - 12.0
	_choice_box.add_theme_constant_override("separation", 12)
	_choice_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_box.visible = false
	_root.add_child(_choice_box)
	_timer_bar = ProgressBar.new()
	_timer_bar.max_value = 1.0
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(0, 8)
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1, 1, 1, 0.9)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.15)
	_timer_bar.add_theme_stylebox_override("fill", fill)
	_timer_bar.add_theme_stylebox_override("background", bg)
	_choice_box.add_child(_timer_bar)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_box.add_child(_grid)

	_qte = preload("res://scripts/dialog/qte_widget.gd").new()
	_qte.visible = false
	_qte.finished.connect(_on_qte_finished)
	_qte.progress_changed.connect(func(v: float) -> void: qte_progress.emit(v))
	_qte.tapped.connect(func() -> void: qte_tapped.emit())
	_root.add_child(_qte)

	_toast = PanelContainer.new()
	_toast.position = Vector2(24, BAR_HEIGHT + 16)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(0, 0, 0, 0.7)
	toast_style.border_width_left = 5
	toast_style.border_color = Color(0.55, 1.0, 0.75)
	toast_style.set_content_margin_all(12)
	toast_style.content_margin_left = 18
	toast_style.content_margin_right = 18
	_toast.add_theme_stylebox_override("panel", toast_style)
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 22)
	_toast.add_child(_toast_label)
	add_child(_toast)


func _button_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color(1, 1, 1, 0.35)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(10)
	return s
