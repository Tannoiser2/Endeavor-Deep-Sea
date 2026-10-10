class_name PlayerBoardView
extends Control
## Plancia originale del giocatore (immagine del mod) con sopra lo stato vero e, sotto, la sua
## squadra: Specialisti (con il disco sul cerchio di attivazione) e Giornali pubblicati.
## - cubetti sui quattro tracciati e sulla Ricerca; dischi nell'area di preparazione;
## - token Immersione conservato nel cerchio dello stemma; Navi non ancora in mare.
## Chiavi cliccabili: spec:<i>, jslot:<ji>, tok:<k>, track:<attr>, res.
## Coordinate in pixel della plancia (2657×1713), la squadra occupa una fascia sotto.

signal clicked(key: String)
signal enlarge_requested(tex: Texture2D, title: String)

const MAT := Vector2(2657, 1713)
const TEAM_H := 520.0
const CIRCLE := {"j": 0.49, "s": 0.56, "leader": 0.62}
const ANIM_TIME := 0.4

var state: Dictionary = {}
var p := 0
var tex_fn: Callable
var highlights: Dictionary = {}
var pending := ""                  # chiave "presa" (disco in mano sopra lo Specialista)
var interactive := false
var show_team := true
var _hits: Array = []
var _font: Font
var anims: Array = []
var _snap: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = get_theme_default_font()


func set_data(s: Dictionary, player: int, loader: Callable) -> void:
	var same: bool = not state.is_empty() and player == p and state.get("seed", -1) == s.get("seed", -2)
	state = s
	p = player
	tex_fn = loader
	var snap := {}
	for i in s.players[p].specs.size():
		snap[i] = s.players[p].specs[i].disc
	if same:
		for i in snap:
			if snap[i] and not _snap.get(i, false):
				anims.append({"from": _staging_slot(0), "to": _circle(i), "t": 0.0})
			elif not snap[i] and _snap.get(i, false):
				anims.append({"from": _circle(i), "to": _staging_slot(0), "t": 0.0})
	_snap = snap
	set_process(not anims.is_empty())
	queue_redraw()


func set_interaction(keys: Array, pend: String, active: bool) -> void:
	highlights.clear()
	for k in keys:
		highlights[k] = true
	pending = pend
	interactive = active
	queue_redraw()


func _process(delta: float) -> void:
	for a in anims:
		a.t += delta / ANIM_TIME
	anims = anims.filter(func(a): return a.t < 1.0)
	if anims.is_empty():
		set_process(false)
	queue_redraw()


# ───────── geometria ─────────

func _canvas() -> Vector2:
	return Vector2(MAT.x, MAT.y + (TEAM_H if show_team else 0.0))


func _k() -> float:
	var c := _canvas()
	return minf(size.x / c.x, size.y / c.y)


func _o() -> Vector2:
	return Vector2((size.x - _canvas().x * _k()) / 2.0, 0)


func P(v: Vector2) -> Vector2:
	return _o() + v * _k()


func R(r: Rect2) -> Rect2:
	return Rect2(P(r.position), r.size * _k())


func _item_w() -> float:
	if state.is_empty():
		return 330.0
	var pl: Dictionary = state.players[p]
	var n: int = pl.specs.size() + pl.journals.size()
	var tw := 330.0
	if n * (tw + 10) > MAT.x:
		tw = MAT.x / n - 10
	return tw


func _spec_rect(i: int) -> Rect2:
	var w := _item_w()
	return Rect2(Vector2(10 + i * (w + 10), MAT.y + 30), Vector2(w, w * 709.0 / 531.0))


func _journal_rect(ji: int) -> Rect2:
	var pl: Dictionary = state.players[p]
	var w := _item_w()
	var base := _spec_rect(pl.specs.size() - 1).end.x + 30
	var jw := w * 0.92
	return Rect2(Vector2(base + ji * (jw + 10), MAT.y + 30), Vector2(jw, jw * 1039.0 / 744.0))


func _circle(i: int) -> Vector2:
	var r := _spec_rect(i)
	var e: Dictionary = state.players[p].specs[i]
	var fy: float = CIRCLE["leader"] if e.id == "leader" else (CIRCLE["s"] if e.senior else CIRCLE["j"])
	return r.position + Vector2(r.size.x * 0.75, r.size.y * fy)


func _staging_slot(i: int) -> Vector2:
	var st: Array = GameData.mat["staging"]
	return Vector2(float(st[0]) + 90 + (i % 10) * 92, float(st[1]) + 85 + (i / 10) * 95)


func _tex(path: String) -> Texture2D:
	return tex_fn.call(path) if path != "" and tex_fn.is_valid() else null


# ───────── disegno ─────────

func _draw() -> void:
	_hits.clear()
	if state.is_empty():
		return
	var k := _k()
	var pl: Dictionary = state.players[p]
	var col: Color = Color(pl.hex)
	var mt := _tex(GameData.players[pl.color]["mat"])
	if mt:
		draw_texture_rect(mt, R(Rect2(Vector2.ZERO, MAT)), false)
	var M: Dictionary = GameData.mat
	# cubetti sugli attributi
	for a in GameData.ATTRS:
		var v := int(pl.attrs[a])
		var c := P(Vector2(float(M["track_x"][v]), float(M["track_y"][a])))
		var half := 44.0 * k
		draw_rect(Rect2(c - Vector2(half, half) + Vector2(5, 7) * k, Vector2(half, half) * 2), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2), col)
		draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2), col.darkened(0.6), false, maxf(1.0, 6 * k))
		var key: String = "track:" + a
		var tr := Rect2(Vector2(420, float(M["track_y"][a]) - 80), Vector2(2120, 160))
		if highlights.has(key):
			draw_rect(R(tr), Color(1, 0.9, 0.2), false, maxf(2.0, 9 * k))
		_hits.append([tr, key, "%s %d — livello %s %d, %d punti" % [GameData.ATTR_NAMES[a], v, GameData.LEVEL_NAMES[a],
			GameData.level(v), GameData.bracket(v)], null])
	# Ricerca
	var res := clampi(int(pl.res), 0, 12)
	var rc := P(Vector2(float(M["research"][res][0]), float(M["research"][res][1])))
	draw_rect(Rect2(rc - Vector2(40, 40) * k, Vector2(80, 80) * k), col)
	draw_rect(Rect2(rc - Vector2(40, 40) * k, Vector2(80, 80) * k), col.darkened(0.6), false, maxf(1.0, 6 * k))
	var rrect := Rect2(Vector2(1560, 1330), Vector2(1080, 360))
	if highlights.has("res"):
		draw_rect(R(rrect), Color(1, 0.9, 0.2), false, maxf(2.0, 9 * k))
	_hits.append([rrect, "res", "Ricerca: %d (massimo 12)" % int(pl.res), null])
	# area di preparazione: dischi
	var st: Array = M["staging"]
	var srect := Rect2(Vector2(st[0], st[1]), Vector2(float(st[2]) - float(st[0]), float(st[3]) - float(st[1])))
	var n := maxi(0, int(pl.staging)) - (1 if pending.begins_with("spec:") or pending.begins_with("jslot:") else 0)
	for i in clampi(n, 0, 30):
		_disc(P(_staging_slot(i)), 40.0 * k, pl.color)
	_text(P(Vector2(srect.end.x - 120, srect.end.y - 40)), "%d" % maxi(0, int(pl.staging)), 70 * k, Color.WHITE)
	_hits.append([srect, "", "Area di raccolta: %d gettoni (riserva %d)" % [int(pl.staging), maxi(0, int(pl.supply))], null])
	# Navi non ancora in mare
	for j in int(pl.vessels_left):
		var vt := _tex(GameData.players[pl.color]["vessel"])
		if vt:
			draw_texture_rect(vt, R(Rect2(Vector2(780 + j * 150, 1560), Vector2(130, 91))), false)
	# token Immersione conservati (nel cerchio dello stemma)
	var ds: Array = M["dive_slot"]
	for j in pl.tokens.size():
		var tid: String = pl.tokens[j]
		var tt := _tex(GameData.dive[tid]["image"])
		var tc := Vector2(float(ds[0]) + j * 70, float(ds[1]) - j * 40)
		var tr := Rect2(tc - Vector2(150, 150), Vector2(300, 300))
		if tt:
			draw_texture_rect(tt, R(tr), false)
		var key := "tok:%d" % j
		if highlights.has(key) or pending == key:
			draw_rect(R(tr).grow(2), Color.WHITE if pending == key else Color(1, 0.9, 0.2), false, maxf(2.0, 9 * k))
		_hits.append([tr, key, "Segnalino Immersione: %d Ricerca, %s" % [int(GameData.dive[tid]["res"]),
			GameData.REWARD_NAMES.get(GameData.dive[tid]["fx"], "nessun effetto")], tt])
	# Punti attuali
	var sc: int = Rules.score(state, p)["total"]
	_text(P(Vector2(1290, 1690)), "Punti %d" % sc, 64 * k, Color("#f3d27a"))
	if not show_team:
		return
	# squadra: Specialisti
	for i in pl.specs.size():
		var e: Dictionary = pl.specs[i]
		var r := _spec_rect(i)
		var path: String = GameData.players[pl.color]["leader"] if e.id == "leader" else String(GameData.side(e.id, e.senior)["image"])
		var t := _tex(path)
		if t:
			draw_texture_rect(t, R(r), false)
		var key := "spec:%d" % i
		var ckey := "copy:%d" % i
		if highlights.has(key) or highlights.has(ckey) or pending == key:
			draw_rect(R(r).grow(-2), Color.WHITE if pending == key else Color(1, 0.9, 0.2), false, maxf(2.0, 10 * k))
		if e.disc and not _animating_to(_circle(i)):
			_disc(P(_circle(i)), 52.0 * k, pl.color)
		if pending == key:
			_disc(P(_circle(i)) + Vector2(0, -14 * k), 56.0 * k, pl.color, true)
		var sd: Dictionary = GameData.side(e.id, e.senior) if e.id != "leader" else GameData.leader
		var tip := "%s%s\nAzioni: %s" % [sd["name"], "" if e.id == "leader" else (" (Senior)" if e.senior else " (Junior)"),
			GameData.acts_text(sd.get("acts", {}))]
		if sd.has("score_text"):
			tip += "\nFine partita: " + String(sd["score_text"])
		if e.disc:
			tip += "\nAttivato"
		_hits.append([r, ckey if highlights.has(ckey) else key, tip, t])
	# Giornali pubblicati, con i dischi sugli spazi azione
	for ji in pl.journals.size():
		var je: Dictionary = pl.journals[ji]
		var jd: Dictionary = GameData.journals[je.id]
		var r := _journal_rect(ji)
		var t := _tex(jd["image"])
		if t:
			draw_texture_rect(t, R(r), false)
		var slots: Array = jd["slots"]
		for s_i in slots.size():
			var fx := 0.61 if slots.size() == 1 or s_i == 1 else 0.29
			var c := r.position + Vector2(r.size.x * fx, r.size.y * 0.87)
			if je.used[s_i]:
				_disc(P(c), 48.0 * k, pl.color)
		var key := "jslot:%d" % ji
		if highlights.has(key) or pending == key:
			draw_rect(R(r).grow(-2), Color.WHITE if pending == key else Color(1, 0.9, 0.2), false, maxf(2.0, 10 * k))
		var tip := "«%s» — campi: %s" % [jd["en"], ", ".join(jd["fields"].map(func(f): return GameData.FIELD_NAMES[f]))]
		if int(jd["points"]) > 0:
			tip += "\n%d punti a fine partita" % int(jd["points"])
		if not slots.is_empty():
			tip += "\nAzione: " + " / ".join(slots.map(func(a): return GameData.ACTION_NAMES.get(a, a)))
		_hits.append([r, key, tip, t])
	for a in anims:
		var e := 1.0 - pow(1.0 - clampf(a.t, 0.0, 1.0), 3.0)
		var pos: Vector2 = a.from.lerp(a.to, e) + Vector2(0, -sin(e * PI) * 160.0)
		_disc(P(pos), 56.0 * k, pl.color, true)


func _animating_to(target: Vector2) -> bool:
	for a in anims:
		if a.to.distance_to(target) < 1.0:
			return true
	return false


func _disc(c: Vector2, r: float, color: String, lifted: bool = false) -> void:
	var t := _tex(GameData.players[color]["disc"])
	draw_circle(c + Vector2(r * 0.15, r * (0.5 if lifted else 0.22)), r, Color(0, 0, 0, 0.4))
	if t:
		draw_texture_rect(t, Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false)
	else:
		draw_circle(c, r, Color(GameData.players[color]["color"]))


func _text(center: Vector2, text: String, fs: float, col: Color) -> void:
	var f := maxi(8, int(fs))
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
	draw_string_outline(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, maxi(2, f / 6), Color.BLACK)
	draw_string(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, f, col)


# ───────── input ─────────

func _hit_at(pos: Vector2) -> Array:
	var bp := (pos - _o()) / _k()
	for i in range(_hits.size() - 1, -1, -1):
		if _hits[i][0].has_point(bp):
			return _hits[i]
	return []


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _hit_at(event.position)
		var key: String = h[1] if not h.is_empty() else ""
		tooltip_text = h[2] if not h.is_empty() else ""
		var playable := interactive and key != "" and (highlights.has(key) or pending == key)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed:
		var h := _hit_at(event.position)
		if h.is_empty():
			return
		var key: String = h[1]
		if event.button_index == MOUSE_BUTTON_LEFT and interactive and key != "" and (highlights.has(key) or pending == key):
			clicked.emit(key)
		elif h[3] != null and (event.button_index == MOUSE_BUTTON_RIGHT or not interactive or not highlights.has(key)):
			if not event.double_click:
				enlarge_requested.emit(h[3], String(h[2]).split("\n")[0])
