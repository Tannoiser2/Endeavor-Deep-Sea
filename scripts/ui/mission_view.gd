class_name MissionView
extends Control
## Foglio della Missione (immagine originale): tabellone Impatto con i segnalini dei giocatori,
## obiettivi e premi. Chiavi cliccabili: hex:<i>.

signal target_clicked(key: String)
signal enlarge_requested(tex: Texture2D, title: String)

var state: Dictionary = {}
var tex_fn: Callable
var highlights: Dictionary = {}
var sheet: Texture2D
var _hits: Array = []
var _font: Font
var _mid := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = get_theme_default_font()


func set_state(s: Dictionary) -> void:
	state = s
	if int(s.mission) != _mid:
		_mid = int(s.mission)
		sheet = tex_fn.call(GameData.mission(_mid)["image"]) if tex_fn.is_valid() else null
	queue_redraw()


func set_highlights(keys: Array) -> void:
	highlights.clear()
	for k in keys:
		highlights[k] = true
	queue_redraw()


func _rect() -> Rect2:
	var ar := 3189.0 / 2126.0
	var w := minf(size.x, size.y * ar)
	var h := w / ar
	return Rect2((size - Vector2(w, h)) / 2.0, Vector2(w, h))


func _draw() -> void:
	_hits.clear()
	if state.is_empty():
		return
	var r := _rect()
	if sheet:
		draw_texture_rect(sheet, r, false)
	var M := GameData.mission(state.mission)
	var hr: float = float(M["hex_r"]) * r.size.x
	for i in M["hexes"].size():
		var h: Dictionary = M["hexes"][i]
		var c := r.position + Vector2(float(h["pos"][0]) * r.size.x, float(h["pos"][1]) * r.size.y)
		var occ: Array = state.impact[i]
		for j in occ.size():
			var t: Texture2D = tex_fn.call(GameData.players[state.players[occ[j]].color]["impact"])
			var d := hr * 1.15
			var off := Vector2(j % 4, j / 4) * hr * 0.28 - Vector2(hr * 0.14 * mini(occ.size() - 1, 3), 0)
			if t:
				draw_texture_rect(t, Rect2(c - Vector2(d, d * 442.0 / 382.0) / 2 + off, Vector2(d, d * 442.0 / 382.0)), false)
		if occ.size() > 4:
			_text(c + Vector2(hr * 0.6, hr * 0.6), "×%d" % occ.size(), hr * 0.6)
		var key := "hex:%d" % i
		if highlights.has(key):
			draw_arc(c, hr * 0.78, 0, TAU, 6, Color(1, 0.9, 0.2), maxf(2.5, hr * 0.12), true)
			draw_circle(c, hr * 0.7, Color(1, 0.9, 0.2, 0.18))
		var tip := "%d punt%s a fine partita" % [int(h["pts"]), "o" if int(h["pts"]) == 1 else "i"]
		if String(h["r"]) != "":
			tip = Rules.reward_letters_text(String(h["r"])) + " — " + tip
		if h["inf"]:
			tip += " (spazio infinito)"
		_hits.append([Rect2(c - Vector2(hr, hr) * 0.8, Vector2(hr, hr) * 1.6), key, tip])


	# Missione 9: segnalini sul tracciato della pulizia
	if M.has("cleanup"):
		var cp: Array = M["cleanup"]["px"]
		var by := {}
		for q in state.n:
			var k := int(state.cleanup[q])
			if not by.has(k):
				by[k] = []
			by[k].append(q)
		for k in by:
			var c := r.position + Vector2(float(cp[int(k)][0]) * r.size.x, float(cp[int(k)][1]) * r.size.y)
			for j in by[k].size():
				var t: Texture2D = tex_fn.call(GameData.players[state.players[by[k][j]].color]["impact"])
				var d := hr * 0.9
				if t:
					draw_texture_rect(t, Rect2(c - Vector2(d, d * 1.157) / 2 + Vector2(j * hr * 0.35 - hr * 0.17 * (by[k].size() - 1), 0), Vector2(d, d * 1.157)), false)
	# Missione 8: scelta degli obiettivi; Missione 6: tipo di sito della Stella caduta
	for i in M["hexes"].size():
		var h: Dictionary = M["hexes"][i]
		if h.has("goal") and state.goal_choice.has(str(int(h["goal"]))):
			var gdef: Dictionary = M["goals"][int(h["goal"]) - 1]
			var lab: String = gdef["options"][int(state.goal_choice[str(int(h["goal"]))])]["label"]
			var c := r.position + Vector2(float(h["pos"][0]) * r.size.x, float(h["pos"][1]) * r.size.y)
			_text(c + Vector2(0, hr * 1.25), lab, maxf(11.0, hr * 0.45))
	if not state.star.is_empty():
		_text(r.position + Vector2(r.size.x * 0.86, r.size.y * 0.985), "Obiettivo 3: %s (%s)" % [
			"Conservazione" if state.star.k == "cons" else "Diario", state.players[int(state.star.p)].name], maxf(11.0, hr * 0.5))


func _text(center: Vector2, text: String, fs: float) -> void:
	var f := maxi(8, int(fs))
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
	draw_string_outline(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, maxi(2, f / 6), Color.BLACK)
	draw_string(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, Color.WHITE)


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
		if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and highlights.is_empty()):
			enlarge_requested.emit(sheet, GameData.mission(state.mission)["name"])
			return
		for h in _hits:
			if h[0].has_point(event.position) and highlights.has(h[1]):
				target_clicked.emit(h[1])
				return
