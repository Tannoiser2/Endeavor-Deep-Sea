class_name OceanView
extends Control
## L'oceano: le tessere Oceano originali nella griglia della missione (colonne A-E, profondità 1-5),
## con sopra i dischi dei giocatori sui siti, le Navi nel riquadro di Viaggio, le pile di token
## Immersione e, a destra, le pile delle tessere coperte per profondità. Durante una Scoperta le
## due tessere pescate compaiono in grande sopra l'oceano.
##
## Chiavi cliccabili: zone:<zid>, vsl:<zid>, site:<zid>:<sid>, slot:<c>:<d>, stack:<d>, board:<zid>.

signal target_clicked(key: String)
signal enlarge_requested(tex: Texture2D, title: String)

const TILE := Vector2(1.444, 1.0)        # proporzioni della tessera (1535×1063)
const GAP := 0.05
const LEFT := 0.32                        # margine per le etichette di profondità
const TOP := 0.30                         # margine per le lettere delle colonne
const STACK_W := 0.95                     # colonna delle pile coperte
const DISC_D := 0.085                     # diametro dei dischi (in larghezze di tessera)
const ANIM_TIME := 0.45

var state: Dictionary = {}
var tex_fn: Callable
var highlights: Dictionary = {}
var drawn: Array = []                     # tessere pescate (Scoperta in corso)
var zoom := 1.0
var pan := Vector2.ZERO
var _drag := false
var _hits: Array = []                     # [Rect2 schermo, chiave, tooltip, texture]
var _font: Font
var anims: Array = []
var _snap: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_font = get_theme_default_font()


func _tex(path: String) -> Texture2D:
	if path == "":
		return null
	if tex_fn.is_valid():
		return tex_fn.call(path)
	return load(path) if ResourceLoader.exists(path) else null


func set_state(s: Dictionary, draw_list: Array = []) -> void:
	var first: bool = state.is_empty() or state.get("seed", -1) != s.get("seed", -2)
	state = s
	drawn = draw_list
	var snap := _occupancy()
	if not first:
		for k in snap:
			if not _snap.has(k):
				anims.append({"key": k, "to": snap[k][1], "col": snap[k][0], "t": 0.0})
	_snap = snap
	set_process(not anims.is_empty())
	queue_redraw()


func set_highlights(keys: Array) -> void:
	highlights.clear()
	for k in keys:
		highlights[k] = true
	queue_redraw()


func _occupancy() -> Dictionary:
	var out := {}
	for zid in state.get("zs", {}):
		for sid in state.zs[zid].sites:
			var o := int(state.zs[zid].sites[sid])
			if o >= 0:
				out["%s:%s" % [zid, sid]] = [o, [zid, sid]]
	return out


func _process(delta: float) -> void:
	for a in anims:
		a.t += delta / ANIM_TIME
	anims = anims.filter(func(a): return a.t < 1.0)
	if anims.is_empty():
		set_process(false)
	queue_redraw()


# ───────── geometria (unità: altezza di una tessera = 1) ─────────

func _cols() -> int:
	return Rules.columns(state) if not state.is_empty() else 5


func _rows() -> int:
	return Rules.max_depth(state) if not state.is_empty() else 5


func _world() -> Vector2:
	return Vector2(LEFT + _cols() * (TILE.x + GAP) + STACK_W, TOP + _rows() * (TILE.y + GAP))


func _scale() -> float:
	var w := _world()
	return minf(size.x / w.x, size.y / w.y) * zoom


func _origin() -> Vector2:
	return (size - _world() * _scale()) / 2.0 + pan


func W(v: Vector2) -> Vector2:
	return _origin() + v * _scale()


func cell_rect(c: int, d: int) -> Rect2:
	var p := Vector2(LEFT + c * (TILE.x + GAP), TOP + (d - 1) * (TILE.y + GAP))
	return Rect2(W(p), TILE * _scale())


## Punto della tessera (coordinate normalizzate 0..1) sullo schermo.
func tile_point(r: Rect2, n) -> Vector2:
	return r.position + Vector2(float(n[0]) * r.size.x, float(n[1]) * r.size.y)


func zone_rect(zid: String) -> Rect2:
	var zs: Dictionary = state.zs[zid]
	return cell_rect(int(zs.c), int(zs.d))


func _stack_rect(d: int) -> Rect2:
	var x := LEFT + _cols() * (TILE.x + GAP) + 0.06
	var w := STACK_W - 0.1
	var h := w / TILE.x
	var y := TOP + (d - 1) * (TILE.y + GAP) + (TILE.y - h) / 2.0
	return Rect2(W(Vector2(x, y)), Vector2(w, h) * _scale())


# ───────── disegno ─────────

func _draw() -> void:
	_hits.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color("#071722"))
	if state.is_empty():
		return
	var k := _scale()
	var cols := _cols()
	var maxd := Rules.max_depth(state)
	# fasce di profondità ed etichette
	for d in range(1, maxd + 1):
		var r0 := cell_rect(0, d)
		var band := Rect2(Vector2(W(Vector2(0.02, 0)).x, r0.position.y - GAP * k * 0.5),
			Vector2(cell_rect(cols - 1, d).end.x - W(Vector2(0.02, 0)).x + GAP * k * 0.5, (TILE.y + GAP) * k))
		draw_rect(band, Color(0.05 + 0.02 * (5 - d), 0.18 + 0.05 * (5 - d), 0.28 + 0.06 * (5 - d), 0.55))
		_text(W(Vector2(LEFT * 0.5, TOP + (d - 1) * (TILE.y + GAP) + 0.55)), str(d), 0.32 * k, Color(1, 1, 1, 0.85))
	for c in cols:
		var r := cell_rect(c, 1)
		_text(Vector2(r.get_center().x, W(Vector2(0, TOP * 0.72)).y), GameData.COL_LETTERS[c], 0.24 * k, Color(1, 1, 1, 0.85))
	# celle
	for c in cols:
		for d in range(1, maxd + 1):
			var r := cell_rect(c, d)
			var zid := Rules.zone_at(state, c, d)
			if zid == "":
				var key := "slot:%d:%d" % [c, d]
				if highlights.has(key):
					draw_rect(r.grow(-2), Color(1, 0.85, 0.2, 0.18))
					_dashed(r.grow(-2), Color(1, 0.85, 0.2), maxf(2.0, 0.025 * k))
					_hits.append([r, key, "Metti qui la tessera (colonna %s, profondità %d)" % [GameData.COL_LETTERS[c], d], null])
				else:
					_dashed(r.grow(-4), Color(1, 1, 1, 0.12), 1.0)
				continue
			_draw_zone(zid, r)
	# pile coperte
	for d in range(1, maxd + 1):
		var sr := _stack_rect(d)
		var n: int = state.stacks.get(str(d), []).size()
		var bt := _tex("res://assets/zones/back_%d.jpg" % d)
		if n > 0 and bt:
			for j in mini(n, 3):
				draw_texture_rect(bt, Rect2(sr.position + Vector2(j, -j) * 2.0, sr.size), false)
		else:
			_dashed(sr, Color(1, 1, 1, 0.2), 1.0)
		_text(sr.get_center() + Vector2(0, sr.size.y * 0.5 + 0.13 * k), "%d" % n, 0.12 * k, Color.WHITE)
		var key := "stack:%d" % d
		if highlights.has(key):
			draw_rect(sr.grow(3), Color(1, 0.9, 0.2), false, maxf(2.0, 0.03 * k))
		_hits.append([sr, key, "Tessere di profondità %d coperte: %d" % [d, n], null])
	# tessere pescate durante una Scoperta
	if not drawn.is_empty():
		var ow := minf(size.x * 0.36, size.y * 0.42 * TILE.x)
		var oh := ow / TILE.x
		var total := drawn.size() * ow + (drawn.size() - 1) * 16.0
		var x0 := (size.x - total) / 2.0
		var y0 := size.y - oh - 14.0
		# se gli spazi liberi sono in profondità, le tessere pescate vanno in alto
		var deep := false
		for d in range(1, 6):
			for c in _cols():
				var r := cell_rect(c, d)
				if d >= 3 and _legal_spot_for_drawn(c, d):
					deep = true
		if deep:
			y0 = 44.0
		draw_rect(Rect2(x0 - 12, y0 - 34, total + 24, oh + 46), Color(0, 0, 0, 0.72))
		_text(Vector2(size.x / 2.0, y0 - 10), "Tessere pescate: scegline una e il suo spazio", 15, Color("#f3d27a"))
		for i in drawn.size():
			var zid: String = drawn[i]
			var r := Rect2(x0 + i * (ow + 16.0), y0, ow, oh)
			var t := _tex(GameData.zones[zid]["image"])
			if t:
				draw_texture_rect(t, r, false)
			var key := "board:" + zid
			if highlights.has(key):
				draw_rect(r.grow(2), Color(1, 0.9, 0.2), false, 4.0)
			_hits.append([r, key, _zone_tip(zid), t])
	# animazioni dei dischi
	for a in anims:
		var e := 1.0 - pow(1.0 - clampf(a.t, 0.0, 1.0), 3.0)
		var zid: String = a.to[0]
		if not state.zs.has(zid):
			continue
		var to := tile_point(zone_rect(zid), Rules.site(zid, a.to[1])["pos"])
		var from := Vector2(size.x * 0.5, size.y + 30)
		var pos := from.lerp(to, e) + Vector2(0, -sin(e * PI) * 120.0)
		_disc(pos, DISC_D * TILE.y * k * 0.62, int(a.col))


func _legal_spot_for_drawn(c: int, d: int) -> bool:
	if Rules.zone_at(state, c, d) != "":
		return false
	for zid in drawn:
		if int(GameData.zones[zid]["depth"]) != d:
			continue
		for v in Rules.legal_spots(state, d, true):
			if v.x == c:
				return true
	return false


func _draw_zone(zid: String, r: Rect2) -> void:
	var k := _scale()
	var z: Dictionary = GameData.zones[zid]
	var zs: Dictionary = state.zs[zid]
	var t := _tex(z["image"])
	if t:
		draw_texture_rect(t, r, false)
	else:
		draw_rect(r, Color("#2a5d78"))
	var zkey := "zone:" + zid
	if highlights.has(zkey):
		draw_rect(r.grow(-1), Color(1, 0.9, 0.2, 0.16))
		draw_rect(r.grow(-1), Color(1, 0.9, 0.2), false, maxf(2.5, 0.03 * k))
	_hits.append([r, zkey, _zone_tip(zid), t])
	var dd := DISC_D * r.size.x
	# siti: dischi, pile di token Immersione, evidenziazioni
	for sid in z["sites"]:
		var st: Dictionary = z["sites"][sid]
		var c := tile_point(r, st["pos"])
		var key := "site:%s:%s" % [zid, sid]
		var o := int(zs.sites[sid])
		if st["t"] == "dive":
			var stack: Array = zs.dives.get(sid, [])
			var back := _tex("res://assets/dive/back.jpg")
			var sz := dd * 1.25
			for j in mini(stack.size(), 4):
				var rr := Rect2(c - Vector2(sz, sz) / 2 + Vector2(j, -j) * 1.6, Vector2(sz, sz))
				if back:
					draw_texture_rect(back, rr, false)
			if not stack.is_empty():
				_text(c + Vector2(sz * 0.55, sz * 0.62), str(stack.size()), maxf(10.0, sz * 0.5), Color.WHITE)
		elif o >= 0 and zs.imp.has(sid):
			var it := _tex(GameData.players[state.players[o].color]["impact"])
			if it:
				draw_texture_rect(it, Rect2(c - Vector2(dd * 0.5, dd * 0.58), Vector2(dd, dd * 1.157)), false)
		elif o >= 0 and not _animating(zid, sid):
			_disc(c, dd * 0.5, o)
		if highlights.has(key):
			draw_arc(c, dd * 0.78, 0, TAU, 32, Color(1, 0.9, 0.2), maxf(2.5, dd * 0.12), true)
		_hits.append([Rect2(c - Vector2(dd, dd) * 0.75, Vector2(dd, dd) * 1.5), key, _site_tip(zid, sid), null])
	# Missione 6: segnalino Impatto di chi l'ha scoperta, sul bonus di Scoperta
	if GameData.mission(state.mission).get("mark_discovered", false) and int(zs.by) >= 0:
		var it := _tex(GameData.players[state.players[int(zs.by)].color]["impact"])
		if it:
			draw_texture_rect(it, Rect2(tile_point(r, [0.03, 0.03]), Vector2(dd, dd * 1.157)), false)
	# Navi nel riquadro di Viaggio (in alto a destra della tessera)
	var vi := 0
	for p in state.n:
		var cnt := 0
		for v in state.players[p].vessels:
			if v == zid:
				cnt += 1
		for j in cnt:
			var vt := _tex(GameData.players[state.players[p].color]["vessel"])
			var vw := r.size.x * 0.13
			var vh := vw * 198.0 / 284.0
			var vc := tile_point(r, [0.47 + (vi % 4) * 0.135, 0.17 + (vi / 4) * 0.1])
			var vr := Rect2(vc - Vector2(vw, vh) / 2, Vector2(vw, vh))
			if vt:
				draw_texture_rect(vt, vr, false)
			var vkey := "vsl:" + zid
			if highlights.has(vkey) and p == _active_p():
				draw_rect(vr.grow(2), Color(1, 0.9, 0.2), false, 2.5)
			_hits.append([vr, vkey, "Nave di %s" % state.players[p].name, null])
			vi += 1


func _active_p() -> int:
	return int(state.get("_ui_p", -1))


func _animating(zid: String, sid: String) -> bool:
	for a in anims:
		if a.to[0] == zid and a.to[1] == sid:
			return true
	return false


func _zone_tip(zid: String) -> String:
	var z: Dictionary = GameData.zones[zid]
	var lines := ["%s (profondità %d)" % [GameData.zone_name(zid), int(z["depth"])]]
	lines.append("Arrivo: " + GameData.rewards_text(z.get("arrive", [])))
	lines.append("Scoperta: " + GameData.rewards_text(z.get("discover", [])))
	var sp: String = SPECIAL_TEXT.get(z.get("special", ""), "")
	if sp != "":
		lines.append("⚠ " + sp)
	lines.append("(tasto destro per ingrandire)")
	return "\n".join(lines)


func _site_tip(zid: String, sid: String) -> String:
	var st: Dictionary = Rules.site(zid, sid)
	var o := int(state.zs[zid].sites.get(sid, -1))
	var who := "" if o < 0 else "\nOccupato da " + String(state.players[o].name)
	match String(st["t"]):
		"sonar":
			return "Sonar: %s%s" % [("Scoperta " + String(st["disc"])) if st.has("disc") else GameData.rewards_text(st.get("r", [])), who]
		"cons":
			return "Conservazione (costo %d): %s%s" % [int(st["cost"]), GameData.rewards_text(st.get("r", [])), who]
		"journal":
			return "Diario (campo %s)%s" % [GameData.FIELD_NAMES.get(st["field"], st["field"]), who]
		"dive":
			return "Immersione: %d segnalini" % state.zs[zid].dives.get(sid, []).size()
	return ""


const SPECIAL_TEXT := {
	"oil_rig": "Quando tutti i siti di Conservazione sono pieni, chi ha almeno un gettone qui promuove uno Specialista.",
	"whale_calving": "Se occupi il Diario segnato, quando Conservi qui puoi Conservare una seconda volta.",
	"sunken_ruins": "Quando il sito Immersione si svuota, chi ha una Nave qui può fare un Viaggio via da qui.",
	"shipwreck": "Immersione: peschi due segnalini, ne tieni uno e scarti l'altro.",
	"turtle_migration": "Dopo una Conservazione qui puoi fare un Viaggio via da questa zona.",
	"cave_system": "Le Navi non entrano mai qui: ogni grotta si usa con una Nave nella zona a cui si collega.",
	"jellyfish_bloom": "Se hai un gettone negli spazi segnati, quando viaggi via da qui ottieni un Impatto.",
	"vortex": "Sonar nello spazio segnato: puoi mettere una zona di profondità 3 anche senza la 2 sopra. Viaggiando via da qui: Tecnologia +1.",
	"thermal_vents": "Immersione: +1 Ricerca per ogni tuo gettone negli spazi segnati.",
	"deepwater_shark": "Immersione: +1 Reputazione.",
	"seamount": "Immersione: se hai un gettone in uno spazio segnato, +1 all'attributo più basso.",
	"dive_impact": "Immersione: +1 Impatto.",
	"bioluminescent": "Immersione: +1 Ricerca o +1 gettone, secondo il sito.",
	"abyssal_plain": "Sonar qui: puoi mettere una zona di profondità 5 anche senza la 4 sopra.",
	"black_smoker": "Immersione: poi puoi viaggiare via da qui (non a profondità 5).",
	"abyssal_trench": "Al massimo una Nave per giocatore. Arrivo: Sonar qui.",
	"scaly_snails": "Immersione: poi puoi fare un Diario in questa zona.",
}


func _disc(c: Vector2, r: float, p: int) -> void:
	var t := _tex(GameData.players[state.players[p].color]["disc"])
	draw_circle(c + Vector2(r * 0.12, r * 0.25), r, Color(0, 0, 0, 0.4))
	if t:
		draw_texture_rect(t, Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false)
	else:
		draw_circle(c, r, Color(state.players[p].hex))


func _dashed(r: Rect2, col: Color, w: float) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		draw_dashed_line(pts[i], pts[i + 1], col, w, 8.0)


func _text(center: Vector2, text: String, fs: float, col: Color) -> void:
	var f := maxi(8, int(fs))
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
	draw_string_outline(_font, center - Vector2(w / 2, -f * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, maxi(2, f / 6), Color.BLACK)
	draw_string(_font, center - Vector2(w / 2, -f * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, col)


# ───────── input ─────────

func _hit_at(pos: Vector2) -> Array:
	# prima le chiavi evidenziate (i siti stanno sopra la zona)
	for i in range(_hits.size() - 1, -1, -1):
		if _hits[i][0].has_point(pos) and highlights.has(_hits[i][1]):
			return _hits[i]
	for i in range(_hits.size() - 1, -1, -1):
		if _hits[i][0].has_point(pos):
			return _hits[i]
	return []


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _drag:
			pan += event.relative
			queue_redraw()
			return
		var h := _hit_at(event.position)
		tooltip_text = h[2] if not h.is_empty() else ""
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not h.is_empty() and highlights.has(h[1]) else Control.CURSOR_ARROW
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 1.0 / 1.12)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var h := _hit_at(event.position)
				if not h.is_empty() and h[3] != null and zoom <= 1.01:
					enlarge_requested.emit(h[3], String(h[2]).split("\n")[0])
				else:
					_drag = true
			else:
				_drag = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.double_click and highlights.is_empty():
				zoom = 1.0
				pan = Vector2.ZERO
				queue_redraw()
				return
			var h := _hit_at(event.position)
			if not h.is_empty() and highlights.has(h[1]):
				target_clicked.emit(h[1])


func _zoom_at(pos: Vector2, f: float) -> void:
	var nz := clampf(zoom * f, 1.0, 4.0)
	var before := (pos - _origin()) / _scale()
	zoom = nz
	if zoom <= 1.0:
		pan = Vector2.ZERO
	else:
		pan += pos - (_origin() + before * _scale())
	queue_redraw()
