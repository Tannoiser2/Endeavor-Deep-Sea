class_name SupplyView
extends Control
## Plancia degli Specialisti (livelli 1-5, tre tasche per livello, la tessera in cima a faccia in su
## col numero rimasto) e, a destra, i Giornali in vetrina con il mazzo coperto.
## Chiavi cliccabili: rec:<id>:<tasca liv.5 o -1>, jdisp:<id>.

signal target_clicked(key: String)
signal enlarge_requested(tex: Texture2D, title: String)

const TILE := Vector2(531, 709)
const CARD := Vector2(744, 1039)

var state: Dictionary = {}
var tex_fn: Callable
var highlights: Dictionary = {}
var _hits: Array = []
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = get_theme_default_font()


func set_state(s: Dictionary) -> void:
	state = s
	queue_redraw()


func set_highlights(keys: Array) -> void:
	highlights.clear()
	for k in keys:
		highlights[k] = true
	queue_redraw()


func _tex(path: String) -> Texture2D:
	return tex_fn.call(path) if tex_fn.is_valid() else null


func _draw() -> void:
	_hits.clear()
	if state.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0d1c27"))
	# proporzioni: 5 colonne di tessere (3 tasche impilate in orizzontale per riga) + 5 Giornali
	var h := size.y - 26.0
	var th := h / 3.0 - 4.0
	var tw := th * TILE.x / TILE.y
	var tier_w := tw + 8.0
	var x := 6.0
	for tier in range(1, 6):
		_text(Vector2(x + tw / 2, 14), "Livello %d" % tier, 13, Color(1, 1, 1, 0.75))
		var ids := []
		if tier < 5:
			for sid in GameData.spec_order:
				if int(GameData.specs[sid]["tier"]) == tier:
					ids.append([sid, -1, int(state.tray.get(sid, 0))])
		else:
			for kp in state.t5.size():
				var pocket: Array = state.t5[kp]
				ids.append(["" if pocket.is_empty() else pocket.back(), kp, pocket.size()])
		for row in ids.size():
			var e: Array = ids[row]
			var r := Rect2(Vector2(x, 24 + row * (th + 4)), Vector2(tw, th))
			if e[0] == "" or int(e[2]) <= 0:
				draw_rect(r, Color(1, 1, 1, 0.05))
				continue
			var t := _tex(GameData.specs[e[0]]["j"]["image"])
			if t:
				draw_texture_rect(t, r, false)
			var key := "rec:%s:%d" % [e[0], int(e[1])]
			if highlights.has(key):
				draw_rect(r.grow(1), Color(1, 0.9, 0.2), false, 3.0)
			elif not highlights.is_empty():
				draw_rect(r, Color(0, 0, 0, 0.45))
			_badge(r.position + Vector2(r.size.x - 12, r.size.y - 12), "×%d" % int(e[2]))
			var sd: Dictionary = GameData.specs[e[0]]
			var tip := "%s (livello %d) → Senior: %s\nSubito: %s\nAzioni: %s" % [sd["j"]["name"], tier, sd["s"]["name"],
				GameData.rewards_text(sd["j"]["gain"]) if not sd["j"]["gain"].is_empty() else "niente",
				GameData.acts_text(sd["j"]["acts"])]
			_hits.append([r, key, tip, t])
		x += tier_w
	# Giornali
	x += 14.0
	var cw := minf((size.x - x - 8) / 5.0 - 6.0, h * CARD.x / CARD.y)
	var ch := cw * CARD.y / CARD.x
	_text(Vector2(x + (cw + 6) * 2.5, 14), "Diari", 13, Color(1, 1, 1, 0.75))
	for i in state.display.size():
		var jid: String = state.display[i]
		var jd: Dictionary = GameData.journals[jid]
		var r := Rect2(Vector2(x + i * (cw + 6), 24), Vector2(cw, ch))
		var t := _tex(jd["image"])
		if t:
			draw_texture_rect(t, r, false)
		var key := "jdisp:" + jid
		if highlights.has(key):
			draw_rect(r.grow(1), Color(1, 0.9, 0.2), false, 3.0)
		var tip := "«%s» — costo %d, campi: %s" % [jd["en"], int(jd["cost"]), ", ".join(jd["fields"].map(func(f): return GameData.FIELD_NAMES[f]))]
		if not jd["you"].is_empty():
			tip += "\nTu: " + GameData.rewards_text(jd["you"])
		if not jd["others"].is_empty():
			tip += "\nGli altri: " + GameData.rewards_text(jd["others"])
		if int(jd["points"]) > 0:
			tip += "\n%d punti a fine partita" % int(jd["points"])
		if not jd["slots"].is_empty():
			tip += "\nAzione: " + " / ".join(jd["slots"].map(func(a): return GameData.ACTION_NAMES.get(a, a)))
		_hits.append([r, key, tip, t])
	var dr := Rect2(Vector2(x + 4 * (cw + 6), 24), Vector2(cw, ch))
	var bt := _tex("res://assets/journals/back.jpg")
	if bt and not state.jdeck.is_empty():
		draw_texture_rect(bt, dr, false)
	_badge(dr.position + Vector2(dr.size.x - 14, dr.size.y - 14), "%d" % state.jdeck.size())
	_hits.append([dr, "", "Mazzo dei Diari: %d" % state.jdeck.size(), null])


func _badge(c: Vector2, t: String) -> void:
	draw_circle(c, 11, Color(0, 0, 0, 0.75))
	_text(c + Vector2(0, 5), t, 12, Color.WHITE)


func _text(center: Vector2, text: String, fs: float, col: Color) -> void:
	var f := maxi(8, int(fs))
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
	draw_string_outline(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, 3, Color.BLACK)
	draw_string(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, col)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var tip := ""
		var hand := false
		for h in _hits:
			if h[0].has_point(event.position):
				tip = h[2]
				hand = highlights.has(h[1])
		tooltip_text = tip
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hand else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed:
		for h in _hits:
			if not h[0].has_point(event.position):
				continue
			if event.button_index == MOUSE_BUTTON_LEFT and highlights.has(h[1]):
				target_clicked.emit(h[1])
			elif h[3] != null:
				enlarge_requested.emit(h[3], String(h[2]).split("\n")[0])
			return
