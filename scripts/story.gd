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

## Envanter eşyaları: kimlik -> ad ve açıklama
## Eşyalar. "use" olanlar çantadan kullanılabilir (ihtiyaçlara etkisi), "verb" düğme yazısı, "action" oynatılacak hareket.
const ITEMS := {
	"su_sisesi": {"name": "Su şişesi (yarım)", "desc": "Deniz Arman'ın verdiği plastik şişe. Su ılık ve metal tadında.",
		"use": {"susuzluk": -35.0}, "verb": "İÇ", "action": "icme"},
	"enerji_bari": {"name": "Enerji barı", "desc": "Ezilmiş, son kullanma tarihi üç yıl önce geçmiş. Yine de kalori.",
		"use": {"aclik": -30.0, "yorgunluk": -8.0}, "verb": "YE", "action": "yeme"},
	"kimlik_karti": {"name": "Kimlik kartı — Deniz Arman", "desc": "EMANET / 412. Kaynak ustası. Mavi ışığı hâlâ yanıyor. Kapıdaki terminal yalnızca bu kodu okuyor."},
	"kesici": {"name": "Kaynak kesicisi", "desc": "Deniz Arman'ın aleti. Sapında onun parmak izleri var. Ve seninkiler."},
}

## İhtiyaçlar: 0 = iyi, 100 = dayanılmaz.
const NEEDS := {
	"aclik": {"name": "Açlık", "warn": "Midendeki boşluk dayanılmaz hale geliyor."},
	"susuzluk": {"name": "Susuzluk", "warn": "Boğazın kurumuş. Su bulmalısın."},
	"yorgunluk": {"name": "Yorgunluk", "warn": "Bacakların seni zor taşıyor."},
}

signal need_changed(need: String, value: float)
signal need_warning(text: String)

var vars: Dictionary = {}


func reset() -> void:
	var name := player_name()
	var g: String = str(vars.get("cinsiyet", "e"))
	vars.clear()
	vars["oyuncu_adi"] = name
	vars["cinsiyet"] = g


func get_var(var_name: String, default: Variant = 0) -> Variant:
	return vars.get(var_name, default)


func set_var(var_name: String, value: Variant) -> void:
	vars[var_name] = value
	variable_changed.emit(var_name, value)


func player_name() -> String:
	return str(vars.get("oyuncu_adi", "Evren"))


func is_female() -> bool:
	return str(vars.get("cinsiyet", "e")) == "k"


## Metindeki yer tutucuları doldurur:
##   {ad}           -> oyuncunun adı
##   {abi/abla}     -> erkekse ilki, kadınsa ikincisi
##   {degisken}     -> hikâye değişkeninin değeri
func format_text(text: String) -> String:
	if not text.contains("{"):
		return text
	var gender := RegEx.new()
	gender.compile("\\{([^{}/]+)/([^{}/]+)\\}")
	for m in gender.search_all(text):
		text = text.replace(m.get_string(0), m.get_string(2) if is_female() else m.get_string(1))
	var regex := RegEx.new()
	regex.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
	var out := text
	for m in regex.search_all(text):
		var key := m.get_string(1)
		var value := player_name() if key == "ad" else str(vars.get(key, ""))
		out = out.replace(m.get_string(0), value)
	return out


## Çantadaki eşya kimlikleri (sayısı > 0 olanlar).
func inventory() -> Array:
	var inv: Dictionary = vars.get("envanter", {})
	var out := []
	for id in inv:
		if int(inv[id]) > 0:
			out.append(id)
	return out


func item_count(id: String) -> int:
	return int((vars.get("envanter", {}) as Dictionary).get(id, 0))


func has_item(id: String) -> bool:
	return item_count(id) > 0


func add_item(id: String, count: int = 1) -> void:
	var inv: Dictionary = (vars.get("envanter", {}) as Dictionary).duplicate()
	inv[id] = int(inv.get(id, 0)) + count
	set_var("envanter", inv)


func remove_item(id: String, count: int = 1) -> void:
	var inv: Dictionary = (vars.get("envanter", {}) as Dictionary).duplicate()
	inv[id] = maxi(int(inv.get(id, 0)) - count, 0)
	if inv[id] == 0:
		inv.erase(id)
	set_var("envanter", inv)


# --- İhtiyaçlar ---------------------------------------------------------------

func need(id: String) -> float:
	return float(vars.get(id, 0.0))


func change_need(id: String, delta: float) -> void:
	var before := need(id)
	var after := clampf(before + delta, 0.0, 100.0)
	vars[id] = after
	need_changed.emit(id, after)
	if before < 80.0 and after >= 80.0:
		need_warning.emit(NEEDS[id]["warn"])


## Oyuncu hareket ederken her fizik karesinde çağrılır. speed: yatay hız (m/s).
func tick_needs(delta: float, speed: float) -> void:
	change_need("aclik", delta * 0.045)        # ~37 dakikada 0'dan 100'e
	change_need("susuzluk", delta * 0.065)     # ~25 dakika
	var fatigue := 0.02
	if speed > 4.0:
		fatigue = 0.35                          # koşmak yorar
	elif speed < 0.3 and need("aclik") < 80.0 and need("susuzluk") < 80.0:
		fatigue = -0.15                         # tok ve suya doymuşken dinlenince geçer
	if need("aclik") >= 80.0 or need("susuzluk") >= 80.0:
		fatigue += 0.1
	change_need("yorgunluk", delta * fatigue)


## Yorgunluğa göre hız çarpanı (1.0 .. 0.6).
func speed_factor() -> float:
	return 1.0 - maxf(need("yorgunluk") - 60.0, 0.0) / 100.0


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
