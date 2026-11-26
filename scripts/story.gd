extends Node
## Hikâye durumu (autoload "Story"): seçimlerin hatırlandığı değişkenler ve karakter bilgileri.

signal variable_changed(var_name: String, value: Variant)

const SAVE_PATH := "user://hikaye_kayit.json"
const KEYWORDS := ["and", "or", "not", "true", "false", "null"]

## Konuşmacı kimlikleri -> ekranda görünen ad ve renk.
const CHARACTERS := {
	"DENIZ": {"name": "Deniz", "color": Color(0.5, 0.75, 1.0)},
	"ADA": {"name": "Ada", "color": Color(0.55, 1.0, 0.75)},
	"MARA": {"name": "Mara", "color": Color(1.0, 0.7, 0.4)},
	"KOFI": {"name": "Kofi", "color": Color(1.0, 0.85, 0.35)},
	"LEO": {"name": "Leo", "color": Color(0.85, 0.6, 1.0)},
	"RAFAEL": {"name": "Rafael", "color": Color(0.75, 0.75, 0.75)},
	"BARAN": {"name": "Baran", "color": Color(1.0, 0.5, 0.45)},
	"REYES": {"name": "Kaptan Reyes", "color": Color(0.8, 0.85, 1.0)},
	"OKAFOR": {"name": "Dr. Okafor", "color": Color(0.95, 0.6, 0.8)},
	"HAKEM": {"name": "HAKEM", "color": Color(0.6, 0.95, 1.0)},
	# Önsöz
	"EVREN": {"name": "???", "color": Color(0.75, 0.72, 0.65)},
	"ARMAN": {"name": "Deniz Arman", "color": Color(1.0, 0.65, 0.3)},
	"MUHAFIZ": {"name": "Komite Muhafızı", "color": Color(0.95, 0.8, 0.3)},
	"YASLI": {"name": "Yaşlı Adam", "color": Color(0.8, 0.75, 0.7)},
	"KADIN": {"name": "Kadın", "color": Color(0.85, 0.7, 0.8)},
}

var vars: Dictionary = {}


func reset() -> void:
	var name := player_name()
	vars.clear()
	vars["oyuncu_adi"] = name


func get_var(var_name: String, default: Variant = 0) -> Variant:
	return vars.get(var_name, default)


func set_var(var_name: String, value: Variant) -> void:
	vars[var_name] = value
	variable_changed.emit(var_name, value)


func player_name() -> String:
	return str(vars.get("oyuncu_adi", "Evren"))


## Metindeki {ad} gibi yer tutucuları değişken değerleriyle değiştirir.
func format_text(text: String) -> String:
	if not text.contains("{"):
		return text
	var regex := RegEx.new()
	regex.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
	var out := text
	for m in regex.search_all(text):
		var key := m.get_string(1)
		var value := player_name() if key == "ad" else str(vars.get(key, ""))
		out = out.replace(m.get_string(0), value)
	return out


func speaker_info(speaker_id: String) -> Dictionary:
	if speaker_id == "EVREN":
		return {"name": player_name(), "color": CHARACTERS["EVREN"]["color"]}
	if CHARACTERS.has(speaker_id):
		return CHARACTERS[speaker_id]
	return {"name": speaker_id.capitalize(), "color": Color.WHITE}


## "ada_guven >= 2 and not sir_biliniyor" gibi bir ifadeyi değerlendirir.
## Tanımlanmamış değişkenler 0 kabul edilir.
func evaluate(expr_text: String) -> Variant:
	var regex := RegEx.new()
	regex.compile("[A-Za-z_][A-Za-z0-9_]*")
	var names := PackedStringArray()
	var values: Array = []
	for m in regex.search_all(expr_text):
		var id: String = m.get_string()
		if id in KEYWORDS or names.has(id):
			continue
		names.append(id)
		values.append(vars.get(id, 0))
	var expr := Expression.new()
	if expr.parse(expr_text, names) != OK:
		push_error("Hikâye ifadesi okunamadı: '%s' (%s)" % [expr_text, expr.get_error_text()])
		return null
	var result: Variant = expr.execute(values, null, false)
	if expr.has_execute_failed():
		push_error("Hikâye ifadesi çalıştırılamadı: '%s'" % expr_text)
		return null
	return result


func is_true(expr_text: String) -> bool:
	var result: Variant = evaluate(expr_text)
	return result != null and bool(result)


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(vars))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		vars = data
		return true
	return false
