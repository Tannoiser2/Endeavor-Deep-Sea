class_name Rules
extends RefCounted
## Motore delle regole di Endeavor: Deep Sea (missioni 1-4, gioco competitivo).
## Funzioni statiche e pure sullo stato, un Dictionary serializzabile: lo stesso codice gira nella
## partita, nell'IA (che clona lo stato) e nei test headless.
##
## Flusso: current_decision(s) avanza le parti automatiche e restituisce la prossima decisione
## {p, type, moves}; apply(s, move) applica una mossa scelta fra quelle legali.
## Le decisioni annidate (guadagni, Impatto, Promozioni, azioni successive di uno Specialista,
## Scoperta di una zona, effetti speciali delle zone) vivono nella pila s.stack di "frame".

const LOG_MAX := 600
const PHASE_NAMES := {"recruit": "Reclutamento", "effort": "Impegno", "reassign": "Riassegnazione",
	"action": "Attivazione", "game_over": "Fine partita"}
const ACTIONS_NEED_DISC := ["sonar", "cons", "journal"]


# ═════════════════════════════ SETUP ═════════════════════════════

## player_specs: [{name, ai, ai_level, color ("purple"/"yellow"/"red"/"white")}]
## opts: {"mission": 1..4}
static func new_game(player_specs: Array, seed_value: int = -1, opts: Dictionary = {}) -> Dictionary:
	GameData.ensure_loaded()
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var n := player_specs.size()
	var mid := int(opts.get("mission", 1))
	var M := GameData.mission(mid)
	var s := {
		"n": n, "mission": mid, "round": 1, "phase": "recruit", "wave": 0, "idx": 0, "turn_i": 0,
		"passed": [], "stack": [], "players": [], "grid": {}, "zs": {}, "stacks": {},
		"tray": {}, "t5": [], "display": [], "jdeck": [], "dive_supply": [], "dive_discard": [],
		"impact": [], "log": [], "seed": rng.seed, "rng_n": 0, "last": {}, "turn": {"p": -1},
		"opts": opts.duplicate(), "reassign_left": -1,
	}
	var used_colors := []
	for i in n:
		var spec: Dictionary = player_specs[i]
		var col: String = spec.get("color", GameData.COLORS[i])
		used_colors.append(col)
		var pl := {
			"name": spec.get("name", "Giocatore %d" % (i + 1)), "ai": spec.get("ai", false),
			"ai_level": spec.get("ai_level", 2), "color": col,
			"hex": GameData.players[col]["color"],
			"attrs": {"rep": 0, "insp": 0, "coord": 0, "ing": 0}, "res": 0,
			"staging": 0, "supply": int(GameData.rules["discs"]) - 1,
			"specs": [{"id": "leader", "senior": true, "disc": true}],
			"journals": [], "vessels": [], "vessels_left": int(GameData.rules["vessels"]) - 1,
			"tokens": [], "got_vessel": {}, "fields": {}, "impact_n": 0, "group": "", "markers": [], "launched": 0,
		}
		s.players.append(pl)
		s.passed.append(false)
	s.wave = rng.randi_range(0, n - 1)
	# Specialisti: livelli 1-4 a pile per titolo, livello 5 in tre tasche da tre.
	var t5 := []
	for sid in GameData.spec_order:
		var sp: Dictionary = GameData.specs[sid]
		if int(sp["tier"]) == 5:
			t5.append(sid)
		else:
			s.tray[sid] = int(sp["count"])
	_shuffle(t5, rng)
	for k in int(GameData.rules["tier_pockets"]):
		s.t5.append(t5.slice(k * 3, k * 3 + 3))
	# Giornali: 4 Giornali àncora a caso scoperti, il mazzo dei Giornali mescolato.
	var anchors: Array = GameData.anchor_ids.duplicate()
	_shuffle(anchors, rng)
	s.display = anchors.slice(0, int(GameData.rules["display"]))
	s.jdeck = GameData.journal_ids.duplicate()
	_shuffle(s.jdeck, rng)
	# Token Immersione.
	s.dive_supply = GameData.dive_ids.duplicate()
	_shuffle(s.dive_supply, rng)
	# Pile delle tessere Oceano per profondità (senza le tessere di missione non previste).
	var in_setup := {}
	for e in M["setup"]:
		in_setup[e[0]] = true
	for d in range(1, 6):
		s.stacks[str(d)] = []
	var zids: Array = GameData.zones.keys()
	zids.sort()
	var removed: Array = M.get("remove_depths", [])
	for zid in zids:
		var z: Dictionary = GameData.zones[zid]
		if in_setup.has(zid):
			continue
		if z.get("mission", false):
			continue
		if removed.has(int(z["depth"])):
			continue
		s.stacks[str(int(z["depth"]))].append(zid)
	for d in s.stacks:
		_shuffle(s.stacks[d], rng)
	if M.get("glass_in_stack", false):
		var st2: Array = s.stacks["2"]
		st2.insert(rng.randi_range(0, st2.size()), "looking_glass")
	if String(M.get("fallen_star", "")) == "depth5":
		var st5: Array = s.stacks["5"]
		# la cima della pila è la fine dell'array: 1-2 giocatori fra le prime 4, altrimenti fra le ultime 4
		var k := rng.randi_range(0, mini(3, st5.size()))
		st5.insert(st5.size() - k if n <= 2 else k, "fallen_star")
	var free_cols := []
	for c in int(M["columns"]):
		free_cols.append(c)
	_shuffle(free_cols, rng)
	for e in M["setup"]:
		var zid: String = e[0]
		var d: int = int(e[2])
		var c: int = int(e[1])
		if zid == "random":
			zid = s.stacks[str(d)].pop_back()
		if c < 0:
			c = free_cols.pop_back()
		_place_zone(s, zid, c, d)
	s["cleanup"] = []
	s["firsts"] = {}
	s["goal_choice"] = {}
	s["star"] = {}
	for i in n:
		s.cleanup.append(0)
	# Tabellone Impatto.
	for h in M["hexes"]:
		s.impact.append([])
	s.rng_n = rng.randi()
	log_line(s, "Nuova partita: Missione %d — %s. Comincia %s (l'Onda)." % [mid, M["name"], s.players[s.wave].name])
	# Nave iniziale nella zona di partenza, con il bonus di Arrivo.
	for i in n:
		var p: int = (s.wave + n - 1 - i) % n    # pila: risolve per primo chi ha l'Onda
		push_frame(s, {"f": "launch", "p": p, "start": true})
	return s


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


static func _rng(s: Dictionary) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = int(s.seed) * 7919 + int(s.rng_n)
	s.rng_n = int(s.rng_n) + 1
	return r


static func _place_zone(s: Dictionary, zid: String, col: int, depth: int) -> void:
	var z: Dictionary = GameData.zone(zid)
	s.grid["%d,%d" % [col, depth]] = zid
	var sites := {}
	var dives := {}
	for sid in z["sites"]:
		sites[sid] = -1
		if z["sites"][sid]["t"] == "dive":
			dives[sid] = []
	var zs := {"c": col, "d": depth, "sites": sites, "dives": dives, "links": [], "flags": {}, "by": -1, "imp": {}}
	for l in z["links"]:
		zs.links.append(false)
	s.zs[zid] = zs
	# Token Immersione: quantità per sito ("n") o totale della zona.
	for sid in dives:
		var k := int(z["sites"][sid].get("n", z.get("dive", 0)))
		for i in k:
			var t = _draw_dive(s)
			if t == null:
				break
			dives[sid].append(t)


static func _draw_dive(s: Dictionary):
	if s.dive_supply.is_empty():
		if s.dive_discard.is_empty():
			return null
		s.dive_supply = s.dive_discard.duplicate()
		s.dive_discard = []
		_shuffle(s.dive_supply, _rng(s))
	return s.dive_supply.pop_back()


# ═════════════════════════════ VALORI DERIVATI ═════════════════════════════

static func order(s: Dictionary, i: int) -> int:
	return (int(s.wave) + i) % int(s.n)


static func lvl(s: Dictionary, p: int, a: String) -> int:
	return GameData.level(int(s.players[p].attrs[a]))


static func tech(s: Dictionary, p: int) -> int:
	return lvl(s, p, "ing")


static func zone_at(s: Dictionary, c: int, d: int) -> String:
	return String(s.grid.get("%d,%d" % [c, d], ""))


static func columns(s: Dictionary) -> int:
	return int(GameData.mission(s.mission)["columns"])


static func max_depth(s: Dictionary) -> int:
	return int(GameData.mission(s.mission)["max_depth"])


static func site(zid: String, sid: String) -> Dictionary:
	return GameData.zones[zid]["sites"][sid]


static func has_vessel(s: Dictionary, p: int, zid: String) -> bool:
	return s.players[p].vessels.has(zid)


## Una nave del giocatore permette di usare questo sito? (Grotte sommerse: dalla zona confinante)
static func can_access(s: Dictionary, p: int, zid: String, sid: String) -> bool:
	var st: Dictionary = site(zid, sid)
	if st.has("cave"):
		var zs: Dictionary = s.zs[zid]
		var c := int(zs.c)
		var d := int(zs.d)
		var other := ""
		match String(st["cave"]):
			"up":
				other = zone_at(s, c, d - 1)
			"left":
				other = zone_at(s, c - 1, d)
			"right":
				other = zone_at(s, c + 1, d)
		return other != "" and has_vessel(s, p, other)
	return has_vessel(s, p, zid)


static func research_avail(s: Dictionary, p: int) -> int:
	var pl: Dictionary = s.players[p]
	var r: int = int(pl.res)
	for t in pl.tokens:
		r += int(GameData.dive[t]["res"])
	return r


## Zone raggiungibili da una zona entro la distanza (solo attraverso zone, mai nelle Grotte sommerse).
static func reachable(s: Dictionary, from: String, dist: int, maxd: int) -> Array:
	var zs: Dictionary = s.zs[from]
	var start := Vector2i(int(zs.c), int(zs.d))
	var seen := {start: 0}
	var q := [start]
	var out := []
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		var k: int = seen[cur]
		if k >= dist:
			continue
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = cur + dv
			if seen.has(nx):
				continue
			var zid := zone_at(s, nx.x, nx.y)
			if zid == "" or GameData.zones[zid].get("no_vessels", false):
				continue
			seen[nx] = k + 1
			q.append(nx)
			if nx.y <= maxd:
				out.append(zid)
	return out


## Spazi liberi dove si può piazzare una tessera di quella profondità.
static func legal_spots(s: Dictionary, depth: int, skip: bool = false) -> Array:
	var out := []
	if depth > max_depth(s):
		return out
	var M := GameData.mission(s.mission)
	if M.has("cleanup"):
		var need := int(M["cleanup"]["depth_ok"].get(str(depth), 0))
		var best := 0
		for v in s.cleanup:
			best = maxi(best, int(v))
		if best < need:
			return out
	for c in columns(s):
		if zone_at(s, c, depth) != "":
			continue
		if depth == 1:
			out.append(Vector2i(c, depth))
		elif zone_at(s, c, depth - 1) != "":
			out.append(Vector2i(c, depth))
		elif skip and depth >= 3 and zone_at(s, c, depth - 2) != "":
			out.append(Vector2i(c, depth))
	return out


static func juniors(s: Dictionary, p: int) -> Array:
	var out := []
	var sp: Array = s.players[p].specs
	for i in sp.size():
		if not sp[i].senior:
			out.append(i)
	return out


static func spec_side(s: Dictionary, p: int, si: int) -> Dictionary:
	var e: Dictionary = s.players[p].specs[si]
	return GameData.side(e.id, e.senior)


static func spec_tier(sid: String) -> int:
	return 0 if sid == "leader" else int(GameData.specs[sid]["tier"])


static func fields(s: Dictionary, p: int) -> Dictionary:
	var out := {"blue": 0, "brown": 0, "green": 0, "yellow": 0}
	for e in s.players[p].journals:
		for f in GameData.journals[e.id]["fields"]:
			out[f] += 1
	for f in s.players[p].fields:
		out[f] += int(s.players[p].fields[f])
	return out


# ═════════════════════════════ DECISIONI ═════════════════════════════

static func current_decision(s: Dictionary) -> Dictionary:
	var guard := 0
	while guard < 4000:
		guard += 1
		if not s.stack.is_empty():
			var fr: Dictionary = s.stack.back()
			var depth: int = s.stack.size()
			var moves := frame_moves(s, fr)
			if s.stack.size() != depth or (not s.stack.is_empty() and not is_same(s.stack.back(), fr)):
				continue   # il frame ha impilato o tolto altro: si rivaluta la cima
			if fr.has("_again"):
				fr.erase("_again")
				continue
			if moves.is_empty():
				s.stack.pop_back()
				continue
			return {"p": int(fr.p), "type": "frame", "frame": String(fr.f), "moves": moves}
		match s.phase:
			"recruit":
				if s.idx >= s.n:
					s.phase = "effort"
					s.idx = 0
					continue
				var p := order(s, s.idx)
				var moves := recruit_moves(s, p)
				s.idx += 1
				if moves.is_empty():
					log_line(s, "%s non può reclutare." % s.players[p].name)
					continue
				s.idx -= 1
				return {"p": p, "type": "recruit", "moves": moves}
			"effort":
				for i in s.n:
					var p := order(s, i)
					var k := lvl(s, p, "insp")
					gain_discs(s, p, k)
					log_line(s, "%s: Impegno, +%d gettoni." % [s.players[p].name, k])
				s.phase = "reassign"
				s.idx = 0
				s.reassign_left = -1
				continue
			"reassign":
				if s.idx >= s.n:
					s.phase = "action"
					s.turn_i = 0
					s.turn = {"p": -1}
					for i in s.n:
						s.passed[i] = false
					continue
				var p := order(s, s.idx)
				var pl: Dictionary = s.players[p]
				if int(s.reassign_left) < 0:
					s.reassign_left = lvl(s, p, "coord")
				var occ := []
				for i in pl.specs.size():
					if pl.specs[i].disc:
						occ.append(i)
				if occ.is_empty() or int(s.reassign_left) <= 0:
					s.idx += 1
					s.reassign_left = -1
					continue
				if occ.size() <= int(s.reassign_left):
					for i in occ:
						pl.specs[i].disc = false
						pl.staging += 1
					log_line(s, "%s: Riassegnazione, recupera %d gettoni." % [pl.name, occ.size()])
					s.idx += 1
					s.reassign_left = -1
					continue
				var moves := []
				for i in occ:
					moves.append({"t": "reclaim", "si": i})
				return {"p": p, "type": "reassign", "moves": moves}
			"action":
				if not s.passed.has(false):
					_end_round(s)
					continue
				var p := order(s, s.turn_i)
				if s.passed[p]:
					s.turn_i = (s.turn_i + 1) % s.n
					continue
				if int(s.turn.get("p", -1)) != p:
					s.turn = {"p": p, "acted": false, "tok": false}
				if s.turn.acted:
					if s.players[p].tokens.size() > int(GameData.rules["dive_keep"]):
						push_frame(s, {"f": "excess", "p": p})
						continue
					_next_turn(s)
					continue
				return {"p": p, "type": "action", "moves": action_moves(s, p)}
			"game_over":
				return {"p": -1, "type": "game_over", "moves": []}
	push_error("current_decision: ciclo infinito")
	return {"p": -1, "type": "error", "moves": []}


static func recruit_moves(s: Dictionary, p: int) -> Array:
	var maxt := lvl(s, p, "rep")
	var out := []
	for sid in GameData.spec_order:
		if s.tray.has(sid) and int(s.tray[sid]) > 0 and int(GameData.specs[sid]["tier"]) <= maxt:
			out.append({"t": "recruit", "id": sid, "pk": -1})
	if maxt >= 5:
		for k in s.t5.size():
			if not s.t5[k].is_empty():
				out.append({"t": "recruit", "id": s.t5[k].back(), "pk": k})
	return out


## Azioni dello Specialista (il Robotico copia quelle di un altro).
static func spec_acts(s: Dictionary, p: int, si: int) -> Dictionary:
	return spec_side(s, p, si).get("acts", {"mode": "one", "list": []})


static func action_moves(s: Dictionary, p: int) -> Array:
	var pl: Dictionary = s.players[p]
	var out := []
	if pl.staging >= 1:
		var ctx := {"staging": pl.staging - 1}
		for si in pl.specs.size():
			var e: Dictionary = pl.specs[si]
			if e.disc:
				continue
			var acts := spec_acts(s, p, si)
			for m in _first_options(s, p, acts, ctx, si):
				var mm: Dictionary = m.duplicate()
				mm["t"] = "activate"
				mm["si"] = si
				out.append(mm)
		# Azioni dei Giornali pubblicati (un disco per spazio, resta per sempre).
		for ji in pl.journals.size():
			var je: Dictionary = pl.journals[ji]
			var slots: Array = GameData.journals[je.id]["slots"]
			for k in slots.size():
				if je.used[k]:
					continue
				for o in options(s, p, String(slots[k]), ctx):
					out.append({"t": "jslot", "ji": ji, "k": k, "a": String(slots[k]), "o": o})
				break    # spazi uguali: basta il primo libero
	# Token Immersione: effetto (anche al posto dell'attivazione) o Ricerca.
	var seen := {}
	for k in pl.tokens.size():
		var tid: String = pl.tokens[k]
		if seen.has(tid):
			continue
		seen[tid] = true
		for o in token_options(s, p, tid, {"staging": pl.staging}):
			out.append({"t": "tok_fx", "k": k, "o": o})
		if int(pl.res) < int(GameData.rules["research_max"]):
			out.append({"t": "tok_res", "k": k})
	if s.turn.get("tok", false):
		out.append({"t": "end"})
	else:
		out.append({"t": "pass"})
	return out


## Prime azioni possibili di uno Specialista: [{a, o, copy?}].
static func _first_options(s: Dictionary, p: int, acts: Dictionary, ctx: Dictionary, si: int) -> Array:
	var out := []
	var seen := {}
	for a in acts.get("list", []):
		if a == "copy":
			var pl: Dictionary = s.players[p]
			for j in pl.specs.size():
				if j == si:
					continue
				var other := spec_acts(s, p, j)
				if other.get("list", []).has("copy"):
					continue
				for m in _first_options(s, p, other, ctx, j):
					var mm: Dictionary = m.duplicate()
					mm["copy"] = j
					out.append(mm)
			continue
		if seen.has(a):
			continue
		seen[a] = true
		for o in options(s, p, a, ctx):
			out.append({"a": a, "o": o})
	return out


## Opzioni concrete di un'azione. ctx: staging (dischi rimasti), zone (solo questa zona), from
## (Viaggio solo da questa zona), bonus (Tecnologia +n), no5 (non a profondità 5), discount,
## depth_any (Conservazione alla profondità di una propria Nave), range/skip (Scoperta).
static func options(s: Dictionary, p: int, a: String, ctx: Dictionary) -> Array:
	var pl: Dictionary = s.players[p]
	var staging := int(ctx.get("staging", pl.staging))
	var only: String = ctx.get("zone", "")
	var out := []
	match a:
		"travel", "travel1":
			var bonus := int(ctx.get("bonus", 0)) + (1 if a == "travel1" else 0)
			var seen := {}
			for from in pl.vessels:
				if ctx.has("from") and from != ctx.from:
					continue
				if seen.has(from):
					continue
				seen[from] = true
				var t := tech(s, p) + bonus + (1 if GameData.zones[from].get("special", "") == "vortex" else 0)
				var maxd := mini(t, 4 if ctx.get("no5", false) else 5)
				for to in reachable(s, from, t, maxd):
					if GameData.zones[to].get("special", "") == "abyssal_trench" and pl.vessels.has(to):
						continue
					out.append({"a": "travel", "from": from, "to": to})
		"sonar":
			if staging < 1:
				return out
			for zid in s.zs:
				if only != "" and zid != only:
					continue
				if not has_vessel(s, p, zid):
					continue
				var z: Dictionary = GameData.zones[zid]
				for tk in z["tracks"]:
					for sid in z["tracks"][tk]:
						if int(s.zs[zid].sites[sid]) < 0:
							out.append({"a": "sonar", "z": zid, "s": sid})
							break
		"dive", "dive2":
			for zid in s.zs:
				if only != "" and zid != only:
					continue
				for sid in s.zs[zid].dives:
					if s.zs[zid].dives[sid].is_empty() or not can_access(s, p, zid, sid):
						continue
					out.append({"a": "dive", "z": zid, "s": sid, "extra": a == "dive2"})
		"cons", "cons_depth", "cons1":
			var cleaning: bool = GameData.mission(s.mission).has("cleanup")
			if staging < 1 and not cleaning:
				return out
			var avail := research_avail(s, p)
			var disc := int(ctx.get("discount", 0)) + (1 if a == "cons1" else 0)
			var depths := {}
			if a == "cons_depth":
				for v in pl.vessels:
					depths[int(s.zs[v].d)] = true
			for zid in s.zs:
				if only != "" and zid != only:
					continue
				for sid in s.zs[zid].sites:
					var st: Dictionary = site(zid, sid)
					if st["t"] != "cons" or int(s.zs[zid].sites[sid]) >= 0:
						continue
					var ok := can_access(s, p, zid, sid)
					if not ok and a == "cons_depth" and depths.has(int(s.zs[zid].d)) and not st.has("cave"):
						ok = true
					if not ok:
						continue
					var cost := maxi(0, int(st["cost"]) - disc)
					if cost > avail:
						continue
					if staging < 1 and not _cleanup_first(s, p, zid):
						continue
					out.append({"a": "cons", "z": zid, "s": sid, "cost": cost})
		"journal":
			if staging < 1:
				return out
			var avail := research_avail(s, p)
			for zid in s.zs:
				if only != "" and zid != only:
					continue
				for sid in s.zs[zid].sites:
					var st: Dictionary = site(zid, sid)
					if st["t"] != "journal" or int(s.zs[zid].sites[sid]) >= 0:
						continue
					if not can_access(s, p, zid, sid):
						continue
					for jid in s.display:
						var jd: Dictionary = GameData.journals[jid]
						if jd["fields"].has(st["field"]) and int(jd["cost"]) <= avail:
							out.append({"a": "journal", "z": zid, "s": sid, "j": jid})
		"promote":
			for i in juniors(s, p):
				out.append({"a": "promote", "si": i})
		"discover35":
			out.append({"a": "discover", "r": "3-5"})
	return out


static func token_options(s: Dictionary, p: int, tid: String, ctx: Dictionary) -> Array:
	var fx: String = GameData.dive[tid]["fx"]
	match fx:
		"":
			return []
		"impact", "any", "low", "disc":
			return [{"a": fx}]
		"trade":
			return [{"a": "trade"}] if int(s.players[p].staging) >= 1 else []
		"promote":
			return [{"a": "promote_any"}] if not juniors(s, p).is_empty() else []
	return options(s, p, fx, ctx)


# ═════════════════════════════ FRAME ═════════════════════════════

static func push_frame(s: Dictionary, fr: Dictionary) -> void:
	s.stack.append(fr)


static func push_gains(s: Dictionary, p: int, lst: Array, ctx: Dictionary = {}) -> void:
	if lst.is_empty():
		return
	push_frame(s, {"f": "gains", "p": p, "list": lst.duplicate(), "ctx": ctx})


static func push_act(s: Dictionary, p: int, a: String, ctx: Dictionary = {}) -> void:
	push_frame(s, {"f": "act", "p": p, "a": a, "ctx": ctx})


## Mosse del frame in cima; può eseguire passi automatici (e impilare altri frame).
static func frame_moves(s: Dictionary, fr: Dictionary) -> Array:
	var p := int(fr.p)
	var pl: Dictionary = s.players[p]
	match String(fr.f):
		"gains":
			while not fr.list.is_empty():
				var g: String = fr.list[0]
				if GameData.ATTRS.has(g):
					fr.list.remove_at(0)
					attr_gain(s, p, g, 1)
					if not is_same(s.stack.back(), fr):
						return []
					continue
				match g:
					"res":
						fr.list.remove_at(0)
						pl.res = mini(int(pl.res) + 1, int(GameData.rules["research_max"]))
					"disc":
						fr.list.remove_at(0)
						gain_discs(s, p, 1)
					"impact":
						fr.list.remove_at(0)
						push_frame(s, {"f": "impact", "p": p, "ctx": fr.get("ctx", {})})
						return []
					"promote":
						fr.list.remove_at(0)
						if not juniors(s, p).is_empty():
							push_frame(s, {"f": "promote", "p": p})
							return []
					"any":
						var out := []
						for a in GameData.ATTRS:
							out.append({"t": "attr", "a": a})
						return out
					"low":
						var lo := 99
						for a in GameData.ATTRS:
							lo = mini(lo, int(pl.attrs[a]))
						var out := []
						for a in GameData.ATTRS:
							if int(pl.attrs[a]) == lo:
								out.append({"t": "attr", "a": a})
						if out.size() == 1:
							fr.list.remove_at(0)
							attr_gain(s, p, out[0].a, 1)
							if not is_same(s.stack.back(), fr):
								return []
							continue
						return out
					"trade":
						fr.list.remove_at(0)
						if int(pl.staging) >= 1:
							pl.staging -= 1
							pl.supply += 1
							pl.res = mini(int(pl.res) + 5, int(GameData.rules["research_max"]))
					"sonar", "travel", "dive", "journal", "cons1", "sonar_here", "cons_here", "promote_any":
						fr.list.remove_at(0)
						var actx := {}
						var a := g
						if g == "sonar_here":
							a = "sonar"
							actx["zone"] = fr.ctx.get("zone", "")
						elif g == "cons_here":
							a = "cons"
							actx["zone"] = fr.ctx.get("zone", "")
						elif g == "promote_any":
							a = "promote"
						push_act(s, p, a, actx)
						return []
					_:
						fr.list.remove_at(0)
						if g.begins_with("discover:"):
							push_frame(s, {"f": "discover", "p": p, "r": g.substr(9), "skip": false, "drawn": []})
							return []
						if g.begins_with("F:"):
							var f := g.substr(2)
							pl.fields[f] = int(pl.fields.get(f, 0)) + 1
						elif g == "SS":
							pl.res = mini(int(pl.res) + 2, int(GameData.rules["research_max"]))
						else:
							push_warning("Ricompensa sconosciuta: " + g)
			return []
		"impact":
			return impact_moves(s, p, fr.get("ctx", {}))
		"promote":
			var out := []
			for i in juniors(s, p):
				out.append({"t": "promote", "si": i})
			if not out.is_empty():
				out.append({"t": "skip"})
			return out
		"act":
			var out := []
			var seen := {}
			for o in options(s, p, String(fr.a), fr.get("ctx", {})):
				var k := str(o)
				if not seen.has(k):
					seen[k] = true
					out.append({"t": "opt", "a": fr.a, "o": o})
			if not out.is_empty():
				out.append({"t": "skip"})
			return out
		"acts":
			var out := []
			var seen := {}
			for a in fr.list:
				if seen.has(a):
					continue
				seen[a] = true
				for o in options(s, p, String(a), {}):
					out.append({"t": "opt", "a": a, "o": o})
			if not out.is_empty():
				out.append({"t": "skip"})
			return out
		"discover":
			return discover_moves(s, fr)
		"launch":
			if pl.vessels_left < 0:
				return []
			var mid: Dictionary = GameData.mission(s.mission)
			var lz := String(mid["launch"])
			if not fr.get("start", false) and mid.has("launch_later"):
				lz = String(mid["launch_later"])
			if lz == "any_depth1":
				var out := []
				for zid in s.zs:
					if int(s.zs[zid].d) == 1:
						out.append({"t": "launch", "z": zid})
				return out
			_launch(s, p, lz, fr)
			return []
		"excess":
			if pl.tokens.size() <= int(GameData.rules["dive_keep"]):
				return []
			var out := []
			var seen := {}
			for k in pl.tokens.size():
				var tid: String = pl.tokens[k]
				if seen.has(tid):
					continue
				seen[tid] = true
				out.append({"t": "tok_res", "k": k})
				for o in token_options(s, p, tid, {}):
					out.append({"t": "tok_fx", "k": k, "o": o})
			return out
		"pick_token":
			var out := []
			for k in fr.toks.size():
				out.append({"t": "pick", "k": k})
			return out
		"goal_choice":
			var gdef: Dictionary = GameData.mission(s.mission)["goals"][int(fr.g) - 1]
			var out := []
			for k in gdef["options"].size():
				out.append({"t": "gchoice", "g": int(fr.g), "o": k})
			return out
		"star_choice":
			return [{"t": "star", "k": "cons"}, {"t": "star", "k": "journal"}]
	push_error("Frame sconosciuto: " + str(fr.f))
	return []


static func impact_moves(s: Dictionary, p: int, ctx: Dictionary) -> Array:
	var M := GameData.mission(s.mission)
	var hexes: Array = M["hexes"]
	var pl: Dictionary = s.players[p]
	if M.get("moving", false):
		return _moving_moves(s, p)
	var rows := {}
	if M.get("depth_rows", false):
		var z: String = ctx.get("zone", "")
		if z != "" and s.zs.has(z):
			rows[int(s.zs[z].d)] = true
		else:
			for v in pl.vessels:
				rows[int(s.zs[v].d)] = true
	var main_full := true
	if M.get("clusters", false):
		for i in hexes.size():
			if not hexes[i]["inf"] and s.impact[i].is_empty():
				main_full = false
				break
	var out := []
	for i in hexes.size():
		var h: Dictionary = hexes[i]
		var g: String = h.get("g", "")
		if M.get("one_group", false) and String(pl.group) != "" and g != String(pl.group):
			continue
		if g == "rescue" and String(ctx.get("zone", "")) != "fallen_star":
			continue
		if h.has("special"):
			if String(h["special"]) == "cons_zone" and ctx.get("cons", false) and ctx.get("zone", "") != "" \
					and not s.zs[ctx.zone].flags.get("pink", false):
				out.append({"t": "hex", "h": i})
			continue
		if not h["inf"] and not s.impact[i].is_empty():
			continue
		if h.get("full", false) and not main_full:
			continue
		if not rows.is_empty() or M.get("depth_rows", false):
			var hr: Array = h.get("rows", [h.get("row", 0)])
			var okr := false
			for r in hr:
				if rows.has(int(r)):
					okr = true
			if not okr:
				continue
		var ok: bool = h["entry"]
		if h.get("full", false):
			ok = true
		if h.get("cons_direct", false) and ctx.get("cons", false):
			ok = true
		if not ok:
			for j in h["adj"]:
				if not s.impact[j].is_empty():
					ok = true
					break
		if not ok:
			for j in h.get("from", []):
				if not s.impact[int(j)].is_empty():
					ok = true
					break
		if ok:
			out.append({"t": "hex", "h": i})
	return out


## Missione 6: un segnalino che si sposta in un esagono vicino libero.
static func _moving_moves(s: Dictionary, p: int) -> Array:
	var M := GameData.mission(s.mission)
	var hexes: Array = M["hexes"]
	var pl: Dictionary = s.players[p]
	var star := star_col(s)
	var out := []
	var all_stuck := true
	for mk in pl.markers:
		var h: Dictionary = hexes[int(mk)]
		var stuck := true
		for j in h["adj"]:
			if not s.impact[j].is_empty():
				continue
			if hexes[j].has("score_col") and star < 0:
				continue
			out.append({"t": "hex", "h": j, "from": int(mk)})
			stuck = false
		if not stuck and not h.has("score_col"):
			all_stuck = false
	if all_stuck:
		for i in hexes.size():
			if hexes[i]["entry"] and s.impact[i].is_empty():
				out.append({"t": "hex", "h": i})
	return out


## Colonna della Stella caduta (se scoperta), altrimenti -1.
static func star_col(s: Dictionary) -> int:
	if s.zs.has("fallen_star"):
		return int(s.zs["fallen_star"].c)
	return -1


static func discover_moves(s: Dictionary, fr: Dictionary) -> Array:
	var rng: Array = _range(String(fr.r))
	var skip: bool = fr.get("skip", false)
	var drawn: Array = fr.drawn
	if not fr.get("done_draw", false):
		var legal := []
		for d in rng:
			if not legal_spots(s, d, skip).is_empty() and not s.stacks[str(d)].is_empty():
				legal.append(d)
		if legal.is_empty() and drawn.is_empty():
			# Scoperta impossibile: si pesca dalla profondità più bassa con uno spazio libero.
			for d in range(1, max_depth(s) + 1):
				if not legal_spots(s, d, skip).is_empty() and not s.stacks[str(d)].is_empty():
					legal = [d]
					fr.r = str(d)
					break
		if legal.is_empty():
			fr.done_draw = true
			if drawn.is_empty():
				# Oceano pieno: un Impatto al posto della Scoperta.
				log_line(s, "  Oceano completo: %s ottiene un Impatto." % s.players[fr.p].name)
				fr.dead = true
				s.stack.pop_back()
				push_frame(s, {"f": "impact", "p": fr.p, "ctx": {}})
				return []
		elif legal.size() == 1:
			_draw_board(s, fr, legal[0])
			fr["_again"] = true
			return []
		else:
			var out := []
			for d in legal:
				out.append({"t": "draw", "d": d})
			return out
	var out := []
	for zid in drawn:
		var d := int(GameData.zones[zid]["depth"])
		for v in legal_spots(s, d, skip):
			out.append({"t": "place", "z": zid, "c": v.x, "d": v.y})
	if out.is_empty():
		for zid in drawn:
			s.stacks[str(int(GameData.zones[zid]["depth"]))].push_front(zid)
		fr.drawn = []
	return out


static func _draw_board(s: Dictionary, fr: Dictionary, d: int) -> void:
	var zid: String = s.stacks[str(d)].pop_back()
	fr.drawn.append(zid)
	if fr.drawn.size() >= 2:
		fr.done_draw = true


static func _range(r: String) -> Array:
	if r.ends_with("+"):
		return range(int(r.trim_suffix("+")), 6)
	if r.contains("-"):
		var parts := r.split("-")
		return range(int(parts[0]), int(parts[1]) + 1)
	return [int(r)]


# ═════════════════════════════ APPLICAZIONE ═════════════════════════════

static func apply(s: Dictionary, m: Dictionary) -> void:
	var d := current_decision(s)
	var p: int = d.p
	s.last = {"p": p, "m": m}
	var pl: Dictionary = s.players[p] if p >= 0 else {}
	match String(m["t"]):
		"recruit":
			recruit(s, p, String(m.id), int(m.pk))
			s.idx += 1
		"reclaim":
			pl.specs[int(m.si)].disc = false
			pl.staging += 1
			s.reassign_left = int(s.reassign_left) - 1
			log_line(s, "%s riassegna %s." % [pl.name, spec_name(s, p, int(m.si))])
			if int(s.reassign_left) <= 0:
				s.idx += 1
				s.reassign_left = -1
		"activate":
			var si := int(m.si)
			pl.specs[si].disc = true
			pl.staging -= 1
			s.turn.acted = true
			var src := int(m.get("copy", si))
			var acts := spec_acts(s, p, src)
			log_line(s, "%s attiva %s%s." % [pl.name, spec_name(s, p, si),
				(" (copia %s)" % spec_name(s, p, src)) if m.has("copy") else ""])
			if String(acts.get("mode", "one")) == "all":
				var rest: Array = acts["list"].duplicate()
				rest.erase(m.a)
				if not rest.is_empty():
					push_frame(s, {"f": "acts", "p": p, "list": rest})
			exec_option(s, p, String(m.a), m.o, {})
		"jslot":
			var je: Dictionary = pl.journals[int(m.ji)]
			je.used[int(m.k)] = true
			pl.staging -= 1
			s.turn.acted = true
			log_line(s, "%s usa l'azione del Diario «%s»." % [pl.name, GameData.journals[je.id]["en"]])
			exec_option(s, p, String(m.a), m.o, {})
		"tok_fx":
			var tid: String = pl.tokens[int(m.k)]
			pl.tokens.remove_at(int(m.k))
			s.dive_discard.append(tid)
			if s.phase == "action" and s.stack.is_empty():
				s.turn.tok = true
			log_line(s, "%s usa un segnalino Immersione: %s." % [pl.name, GameData.REWARD_NAMES.get(GameData.dive[tid]["fx"], "")])
			var a: String = m.o.get("a", "")
			if a in ["impact", "any", "low", "disc", "trade", "promote_any"]:
				push_gains(s, p, [a])
			else:
				exec_option(s, p, String(GameData.dive[tid]["fx"]), m.o, {})
		"tok_res":
			var tid: String = pl.tokens[int(m.k)]
			pl.tokens.remove_at(int(m.k))
			s.dive_discard.append(tid)
			pl.res = mini(int(pl.res) + int(GameData.dive[tid]["res"]), int(GameData.rules["research_max"]))
			log_line(s, "%s converte un segnalino in %d Ricerca." % [pl.name, int(GameData.dive[tid]["res"])])
		"pass":
			s.passed[p] = true
			log_line(s, "%s passa." % pl.name)
			_next_turn(s)
		"end":
			s.turn.acted = true
		"attr":
			var fr: Dictionary = s.stack.back()
			fr.list.remove_at(0)
			attr_gain(s, p, String(m.a), 1)
		"hex":
			var fr: Dictionary = s.stack.pop_back()
			place_impact(s, p, int(m.h), fr.get("ctx", {}), int(m.get("from", -1)))
		"gchoice":
			s.stack.pop_back()
			s.goal_choice[str(int(m.g))] = int(m.o)
			var gdef: Dictionary = GameData.mission(s.mission)["goals"][int(m.g) - 1]
			log_line(s, "  %s sceglie per l'obiettivo %d: %s." % [s.players[p].name, int(m.g), gdef["options"][int(m.o)]["label"]])
		"star":
			s.stack.pop_back()
			s.star = {"p": p, "k": String(m.k)}
			log_line(s, "  %s sceglie i siti di %s per l'obiettivo 3." % [s.players[p].name, "Conservazione" if m.k == "cons" else "Diario"])
		"promote":
			s.stack.pop_back()
			promote(s, p, int(m.si))
		"skip":
			s.stack.pop_back()
		"opt":
			var fr: Dictionary = s.stack.back()
			if String(fr.f) == "acts":
				fr.list.erase(m.a)
				if fr.list.is_empty():
					s.stack.pop_back()
			else:
				s.stack.pop_back()
			exec_option(s, p, String(m.a), m.o, fr.get("ctx", {}))
		"draw":
			_draw_board(s, s.stack.back(), int(m.d))
		"place":
			var fr: Dictionary = s.stack.back()
			s.stack.pop_back()
			discover_place(s, p, fr, String(m.z), int(m.c), int(m.d))
		"launch":
			var fr: Dictionary = s.stack.back()
			_launch(s, p, String(m.z), fr)
		"pick":
			var fr: Dictionary = s.stack.back()
			s.stack.pop_back()
			var keep: String = fr.toks[int(m.k)]
			for k in fr.toks.size():
				if k != int(m.k):
					s.dive_discard.append(fr.toks[k])
			pl.tokens.append(keep)
		_:
			push_error("Mossa sconosciuta: " + str(m))


static func _launch(s: Dictionary, p: int, zid: String, fr: Dictionary) -> void:
	var pl: Dictionary = s.players[p]
	if is_same(s.stack.back(), fr):
		s.stack.pop_back()
	if not fr.get("start", false):
		pl.vessels_left -= 1
	pl.vessels.append(zid)
	log_line(s, "%s mette una Nave in %s." % [pl.name, GameData.zone_name(zid)])
	arrive(s, p, zid)


static func recruit(s: Dictionary, p: int, sid: String, pk: int) -> void:
	var pl: Dictionary = s.players[p]
	if pk >= 0:
		s.t5[pk].erase(sid)
		if s.t5[pk].is_empty():
			# la tasca vuota si riempie con la prima tessera di un'altra
			for k in s.t5.size():
				if s.t5[k].size() > 1:
					s.t5[pk].append(s.t5[k].pop_front())
					break
	else:
		s.tray[sid] = int(s.tray[sid]) - 1
	pl.specs.append({"id": sid, "senior": false, "disc": false})
	var side: Dictionary = GameData.side(sid, false)
	log_line(s, "%s recluta %s (livello %d)." % [pl.name, side["name"], spec_tier(sid)])
	push_gains(s, p, side["gain"])


static func promote(s: Dictionary, p: int, si: int) -> void:
	var pl: Dictionary = s.players[p]
	var e: Dictionary = pl.specs[si]
	if e.senior:
		return
	e.senior = true
	if e.disc:
		e.disc = false
		pl.supply += 1
	var side: Dictionary = GameData.side(e.id, true)
	log_line(s, "  %s promuove: %s." % [pl.name, side["name"]])
	push_gains(s, p, side["gain"])


static func gain_discs(s: Dictionary, p: int, k: int) -> void:
	var pl: Dictionary = s.players[p]
	pl.staging += k
	pl.supply -= k      # se la riserva finisce si usano sostituti (riserva negativa)


## Un passo su un tracciato: Impatto al 10 e oltre la fine (si torna al 10); Navi a 2 e 7 di Ingegno.
static func attr_gain(s: Dictionary, p: int, a: String, k: int) -> void:
	var pl: Dictionary = s.players[p]
	for i in k:
		var v := int(pl.attrs[a]) + 1
		if v > int(GameData.rules["track_max"]):
			v = int(GameData.rules["impact_at"])
			push_frame(s, {"f": "impact", "p": p, "ctx": {}})
		elif v == int(GameData.rules["impact_at"]):
			push_frame(s, {"f": "impact", "p": p, "ctx": {}})
		pl.attrs[a] = v
		if a == "ing":
			for at in GameData.rules["vessel_at"]:
				if v == int(at) and not pl.got_vessel.has(str(at)) and int(pl.vessels_left) > 0:
					pl.got_vessel[str(at)] = true
					push_frame(s, {"f": "launch", "p": p})


static func arrive(s: Dictionary, p: int, zid: String) -> void:
	push_gains(s, p, GameData.zones[zid].get("arrive", []), {"zone": zid})


static func place_impact(s: Dictionary, p: int, h: int, ctx: Dictionary, from: int = -1) -> void:
	var M := GameData.mission(s.mission)
	var hx: Dictionary = M["hexes"][h]
	var pl: Dictionary = s.players[p]
	if from >= 0:
		s.impact[from].erase(p)
		pl.markers.erase(from)
	s.impact[h].append(p)
	if M.get("moving", false):
		pl.markers.append(h)
	if M.get("one_group", false) and String(pl.group) == "":
		pl.group = String(hx.get("g", ""))
	if hx.has("goal") and not s.goal_choice.has(str(int(hx["goal"]))):
		push_frame(s, {"f": "goal_choice", "p": p, "g": int(hx["goal"])})
	s.players[p].impact_n = int(s.players[p].impact_n) + 1
	if hx.has("special") and ctx.get("zone", "") != "":
		s.zs[ctx.zone].flags["pink"] = true
	log_line(s, "  %s piazza un segnalino Impatto%s." % [s.players[p].name,
		"" if String(hx["r"]) == "" else " (" + reward_letters_text(String(hx["r"])) + ")"])
	var g := reward_letters(String(hx["r"]))
	push_gains(s, p, g)


const LETTERS := {"R": "rep", "I": "insp", "C": "coord", "N": "ing", "S": "res", "D": "disc", "A": "any",
	"L": "low", "P": "promote"}


static func reward_letters(r: String) -> Array:
	if r == "":
		return []
	if r.begins_with("F:"):
		return [r]
	var out := []
	for ch in r:
		if LETTERS.has(ch):
			out.append(LETTERS[ch])
	return out


static func reward_letters_text(r: String) -> String:
	if r.begins_with("F:"):
		return "Campo " + GameData.FIELD_NAMES.get(r.substr(2), r)
	return GameData.rewards_text(reward_letters(r))


static func exec_option(s: Dictionary, p: int, a: String, o: Dictionary, ctx: Dictionary) -> void:
	var pl: Dictionary = s.players[p]
	match String(o.get("a", a)):
		"travel":
			var from: String = o.from
			var to: String = o.to
			pl.vessels.erase(from)
			pl.vessels.append(to)
			log_line(s, "  → Viaggio: %s → %s." % [GameData.zone_name(from), GameData.zone_name(to)])
			if int(s.zs[to].d) == 5:
				_first(s, "travel5", p)
			var sp: String = GameData.zones[from].get("special", "")
			if sp == "jellyfish_bloom":
				var mine := false
				for sid in s.zs[from].sites:
					if site(from, sid).get("marked", false) and int(s.zs[from].sites[sid]) == p:
						mine = true
				if mine:
					push_frame(s, {"f": "impact", "p": p, "ctx": {}})
			arrive(s, p, to)
		"sonar":
			var zid: String = o.z
			var sid: String = o.s
			_put_disc(s, p, zid, sid)
			var st: Dictionary = site(zid, sid)
			log_line(s, "  → Sonar in %s." % GameData.zone_name(zid))
			if st.has("disc"):
				push_frame(s, {"f": "discover", "p": p, "r": String(st["disc"]), "skip": st.get("skip_depth", false), "drawn": []})
			else:
				push_gains(s, p, st.get("r", []), {"zone": zid})
			_complete_links(s, p, zid, sid)
		"dive":
			_dive(s, p, String(o.z), String(o.s), o.get("extra", false))
		"cons":
			var zid: String = o.z
			var sid: String = o.s
			pay(s, p, int(o.cost))
			var st: Dictionary = site(zid, sid)
			if _cleanup_first(s, p, zid):
				s.zs[zid].sites[sid] = p
				s.zs[zid].imp[sid] = true
				s.zs[zid].flags["clean_%d" % p] = true
				var mx := int(GameData.mission(s.mission)["cleanup"]["max"])
				s.cleanup[p] = mini(int(s.cleanup[p]) + 1, mx)
				log_line(s, "  → Conservazione in %s con un segnalino Impatto: Bonifica %d." % [GameData.zone_name(zid), int(s.cleanup[p])])
			else:
				_put_disc(s, p, zid, sid)
				log_line(s, "  → Conservazione in %s (costo %d)." % [GameData.zone_name(zid), int(o.cost)])
			var sp: String = GameData.zones[zid].get("special", "")
			# effetti dopo l'azione (impilati prima, così si risolvono dopo i guadagni)
			if sp == "turtle_migration":
				push_act(s, p, "travel", {"from": zid})
			if sp == "whale_calving" and not ctx.get("second", false):
				for jsid in s.zs[zid].sites:
					if site(zid, jsid).get("marked", false) and int(s.zs[zid].sites[jsid]) == p:
						push_act(s, p, "cons", {"zone": zid, "second": true})
			if sp == "oil_rig" and not s.zs[zid].flags.get("oil", false):
				var full := true
				for csid in s.zs[zid].sites:
					if site(zid, csid)["t"] == "cons" and int(s.zs[zid].sites[csid]) < 0:
						full = false
				if full:
					s.zs[zid].flags["oil"] = true
					log_line(s, "  ⚠ Piattaforma dismessa completa: promozioni per chi ha gettoni qui.")
					for i in range(s.n - 1, -1, -1):
						var q: int = (p + i) % s.n
						var has := false
						for csid in s.zs[zid].sites:
							if int(s.zs[zid].sites[csid]) == q:
								has = true
						if has and not juniors(s, q).is_empty():
							push_frame(s, {"f": "promote", "p": q})
			push_gains(s, p, st.get("r", []), {"zone": zid, "cons": true})
			_complete_links(s, p, zid, sid)
		"journal":
			var zid: String = o.z
			var sid: String = o.s
			var jid: String = o.j
			var jd: Dictionary = GameData.journals[jid]
			pay(s, p, int(jd["cost"]))
			_put_disc(s, p, zid, sid)
			s.display.erase(jid)
			if not s.jdeck.is_empty():
				s.display.append(s.jdeck.pop_back())
			var used := []
			for k in jd["slots"].size():
				used.append(false)
			pl.journals.append({"id": jid, "used": used})
			log_line(s, "  → Diario in %s: pubblica «%s» (costo %d)." % [GameData.zone_name(zid), jd["en"], int(jd["cost"])])
			# altri giocatori (in ordine orario dopo il giocatore attivo), poi il giocatore
			for i in range(s.n - 1, 0, -1):
				var q: int = (p + i) % s.n
				push_gains(s, q, jd["others"])
			push_gains(s, p, jd["you"])
			_complete_links(s, p, zid, sid)
			var fb: Array = st_bonus(zid, sid)
			if not fb.is_empty():
				push_gains(s, p, fb, {"zone": zid})
		"promote":
			promote(s, p, int(o.si))
		"discover":
			push_frame(s, {"f": "discover", "p": p, "r": String(o.r), "skip": false, "drawn": []})


static func _cleanup_first(s: Dictionary, p: int, zid: String) -> bool:
	return GameData.mission(s.mission).has("cleanup") and not s.zs[zid].flags.get("clean_%d" % p, false)


static func st_bonus(zid: String, sid: String) -> Array:
	return site(zid, sid).get("bonus", [])


static func _dive(s: Dictionary, p: int, zid: String, sid: String, extra: bool) -> void:
	var pl: Dictionary = s.players[p]
	var stack: Array = s.zs[zid].dives[sid]
	var sp: String = GameData.zones[zid].get("special", "")
	var taken := []
	var k := 2 if sp == "shipwreck" else 1
	for i in k:
		if not stack.is_empty():
			taken.append(stack.pop_back())
	if taken.is_empty():
		return
	log_line(s, "  → Immersione in %s." % GameData.zone_name(zid))
	# effetti della zona (impilati in ordine inverso)
	if sp == "sunken_ruins" and stack.is_empty() and not s.zs[zid].flags.get("ruins", false):
		s.zs[zid].flags["ruins"] = true
		for i in range(s.n - 1, -1, -1):
			var q: int = (p + i) % s.n
			if has_vessel(s, q, zid):
				push_act(s, q, "travel", {"from": zid})
	if sp == "black_smoker":
		push_act(s, p, "travel", {"from": zid, "no5": true})
	if sp == "scaly_snails":
		push_act(s, p, "journal", {"zone": zid})
	if extra and not stack.is_empty():
		pl.tokens.append(stack.pop_back())
	match sp:
		"thermal_vents":
			var r := 0
			for msid in s.zs[zid].sites:
				if site(zid, msid).get("marked", false) and int(s.zs[zid].sites[msid]) == p:
					r += 1
			pl.res = mini(int(pl.res) + r, int(GameData.rules["research_max"]))
		"deepwater_shark":
			push_gains(s, p, ["rep"])
		"dive_impact":
			push_gains(s, p, ["impact"], {"zone": zid})
		"seamount":
			for msid in s.zs[zid].sites:
				if site(zid, msid).get("marked", false) and int(s.zs[zid].sites[msid]) == p:
					push_gains(s, p, ["low"])
					break
	var b: Array = site(zid, sid).get("bonus", [])
	if not b.is_empty():
		push_gains(s, p, b)
	if taken.size() > 1:
		push_frame(s, {"f": "pick_token", "p": p, "toks": taken})
	else:
		pl.tokens.append(taken[0])


static func _put_disc(s: Dictionary, p: int, zid: String, sid: String) -> void:
	s.zs[zid].sites[sid] = p
	s.players[p].staging -= 1


static func _complete_links(s: Dictionary, p: int, zid: String, sid: String) -> void:
	var z: Dictionary = GameData.zones[zid]
	var pend := []
	for li in z["site_links"][sid]:
		if s.zs[zid].links[li]:
			continue
		var l: Dictionary = z["links"][li]
		var other: String = l["b"] if l["a"] == sid else l["a"]
		var q := int(s.zs[zid].sites[other])
		if q < 0:
			continue
		s.zs[zid].links[li] = true
		pend.append([li, q])
	# l'attivo per primo, poi gli altri in senso orario: si impila al contrario
	for i in range(s.n - 1, 0, -1):
		var q: int = (p + i) % s.n
		for e in pend:
			if int(e[1]) == q:
				push_gains(s, q, z["links"][int(e[0])]["r"], {"zone": zid})
	for e in pend:
		push_gains(s, p, z["links"][int(e[0])]["r"], {"zone": zid})
	if not pend.is_empty():
		log_line(s, "  ↔ %d collegament%s completat%s." % [pend.size(), "o" if pend.size() == 1 else "i", "o" if pend.size() == 1 else "i"])


## Paga la Ricerca: prima dal tracciato, poi (se serve) spendendo token Immersione.
static func pay(s: Dictionary, p: int, cost: int) -> void:
	var pl: Dictionary = s.players[p]
	while int(pl.res) < cost and not pl.tokens.is_empty():
		# spende il token con meno valore d'effetto (prima quelli senza effetto)
		var best := 0
		var bv := 99.0
		for k in pl.tokens.size():
			var t: Dictionary = GameData.dive[pl.tokens[k]]
			var v := (0.0 if String(t["fx"]) == "" else 1.0) - float(t["res"]) * 0.1
			if v < bv:
				bv = v
				best = k
		var tid: String = pl.tokens[best]
		pl.tokens.remove_at(best)
		s.dive_discard.append(tid)
		pl.res = int(pl.res) + int(GameData.dive[tid]["res"])
	pl.res = mini(maxi(0, int(pl.res) - cost), int(GameData.rules["research_max"]))


static func discover_place(s: Dictionary, p: int, fr: Dictionary, zid: String, c: int, d: int) -> void:
	for other in fr.drawn:
		if other != zid:
			s.stacks[str(int(GameData.zones[other]["depth"]))].push_front(other)
	var M := GameData.mission(s.mission)
	if zid == "looking_glass" and M.get("glass_in_stack", false) and s.zs.has("sea_star"):
		var sc := int(s.zs["sea_star"].c)
		if c != sc:
			var occupant := zone_at(s, sc, 2)
			if occupant != "":
				# la zona sotto la Stella Marina si sposta (con tutto quello che ha) nello spazio scelto
				s.grid.erase("%d,2" % sc)
				s.grid["%d,%d" % [c, d]] = occupant
				s.zs[occupant].c = c
				log_line(s, "  %s si sposta per far posto al Osservatorio." % GameData.zone_name(occupant))
			c = sc
	_place_zone(s, zid, c, d)
	s.zs[zid].by = p
	if d == 5:
		_first(s, "discover5", p)
	if zid == "fallen_star" and M["goals"].any(func(g): return String(g["kind"]) == "star_sites"):
		push_frame(s, {"f": "star_choice", "p": p})
	log_line(s, "  ★ %s scopre %s (colonna %s, profondità %d)." % [s.players[p].name, GameData.zone_name(zid),
		GameData.COL_LETTERS[c], d])
	push_gains(s, p, GameData.zones[zid].get("discover", []), {"zone": zid})


static func _first(s: Dictionary, ev: String, p: int) -> void:
	var lst: Array = s.firsts.get(ev, [])
	if not lst.has(p):
		lst.append(p)
		s.firsts[ev] = lst


static func _next_turn(s: Dictionary) -> void:
	s.turn = {"p": -1}
	for k in s.n:
		s.turn_i = (s.turn_i + 1) % s.n
		if not s.passed[order(s, s.turn_i)]:
			return


static func _end_round(s: Dictionary) -> void:
	log_line(s, "— Fine del round %d —" % s.round)
	s.round += 1
	if s.round > int(GameData.rules["rounds"]):
		s.phase = "game_over"
		var sc := []
		for p in s.n:
			sc.append("%s %d" % [s.players[p].name, score(s, p)["total"]])
		log_line(s, "Partita finita. " + ", ".join(sc))
		return
	s.wave = (int(s.wave) + 1) % s.n
	s.phase = "recruit"
	s.idx = 0
	log_line(s, "Round %d: l'Onda passa a %s." % [s.round, s.players[s.wave].name])


# ═════════════════════════════ PUNTEGGIO ═════════════════════════════

static func discs_on_sites(s: Dictionary, p: int, kind: String = "", cols: Array = [], depths: Array = []) -> int:
	var n := 0
	for zid in s.zs:
		var zs: Dictionary = s.zs[zid]
		if not cols.is_empty() and not cols.has(int(zs.c)):
			continue
		if not depths.is_empty() and not depths.has(int(zs.d)):
			continue
		for sid in zs.sites:
			if int(zs.sites[sid]) != p:
				continue
			if kind != "" and String(site(zid, sid)["t"]) != kind:
				continue
			n += 1
	return n


static func vessels_in(s: Dictionary, p: int, cols: Array = [], depths: Array = []) -> int:
	var n := 0
	for v in s.players[p].vessels:
		var zs: Dictionary = s.zs[v]
		if not cols.is_empty() and not cols.has(int(zs.c)):
			continue
		if not depths.is_empty() and not depths.has(int(zs.d)):
			continue
		n += 1
	return n


static func zones_with(s: Dictionary, p: int, cols: Array, depths: Array, vessels: bool) -> int:
	var n := 0
	for zid in s.zs:
		var zs: Dictionary = s.zs[zid]
		if not cols.is_empty() and not cols.has(int(zs.c)):
			continue
		if not depths.is_empty() and not depths.has(int(zs.d)):
			continue
		var has: bool = vessels and s.players[p].vessels.has(zid)
		if not has:
			for sid in zs.sites:
				if int(zs.sites[sid]) == p:
					has = true
					break
		if has:
			n += 1
	return n


static func _ints(a: Array) -> Array:
	return a.map(func(x): return int(x))


static func goal_count(s: Dictionary, p: int, g: Dictionary) -> int:
	var cols: Array = _ints(g.get("cols", []))
	var depths: Array = _ints(g.get("depths", []))
	match String(g["kind"]):
		"discs":
			return discs_on_sites(s, p, String(g.get("site", "")), cols, depths)
		"discs_vessels":
			return discs_on_sites(s, p, "", cols, depths) + vessels_in(s, p, cols, depths)
		"journal_vessels":
			return discs_on_sites(s, p, "journal", cols, depths) + vessels_in(s, p, cols, depths)
		"sonar_vessels":
			return discs_on_sites(s, p, "sonar", cols, depths) + vessels_in(s, p, cols, depths)
		"cons_journal":
			return discs_on_sites(s, p, "cons", cols, depths) + discs_on_sites(s, p, "journal", cols, depths)
		"zones_with_disc":
			return zones_with(s, p, cols, depths, false)
		"zones_disc_vessel":
			return zones_with(s, p, cols, depths, true)
		"zones_side":
			var sc := int(s.zs["sea_star"].c) if s.zs.has("sea_star") else 0
			var cs := []
			for c in columns(s):
				if (String(g["side"]) == "left" and c <= sc) or (String(g["side"]) == "right" and c >= sc):
					cs.append(c)
			return zones_with(s, p, cs, [], false)
		"fields":
			var f := fields(s, p)
			var best := 0
			for k in f:
				best = maxi(best, int(f[k]))
			return best
		"field_sets":
			var f := fields(s, p)
			var m := 99
			for k in f:
				m = mini(m, int(f[k]))
			return m
		"discovered":
			var n := 0
			for zid in s.zs:
				if int(s.zs[zid].by) == p:
					n += 1
			return n
		"rescue":
			var hexes: Array = GameData.mission(s.mission)["hexes"]
			var n := 0
			for i in hexes.size():
				if String(hexes[i].get("g", "")) == "rescue":
					n += s.impact[i].count(p)
			return n
		"cleanup":
			return int(s.cleanup[p])
		"star_sites":
			if s.star.is_empty():
				return 0
			return discs_on_sites(s, p, String(s.star.k))
	return 0


## Punti di un obiettivo: base + premi per il 1° e il 2° (pari merito: tutti il 1°, nessun 2°).
static func goal_points(s: Dictionary, p: int, g: Dictionary) -> int:
	match String(g["kind"]):
		"choice":
			var key := str(int(g["hex_goal"]))
			if not s.goal_choice.has(key):
				return 0
			var opt: Dictionary = g["options"][int(s.goal_choice[key])]
			var mult := 3 if String(opt["kind"]) == "field_sets" else 1
			return _ranked(s, p, opt, mult)
		"first":
			var lst: Array = s.firsts.get(String(g["event"]), [])
			var lead: Array = g.get("lead", [0, 0])
			var k := lst.find(p)
			return int(lead[k]) if k >= 0 and k < 2 else 0
		"rescue":
			return _ranked(s, p, g, 0)
		"star_sites":
			var pts := goal_count(s, p, g)
			if not s.star.is_empty() and int(s.star.p) == p:
				pts += 3
			return pts
		"discovered":
			var pts := goal_count(s, p, g)
			for spec in g.get("most", []):
				var counts := []
				for q in s.n:
					var c := 0
					for zid in s.zs:
						if int(s.zs[zid].by) != q:
							continue
						if String(spec[0]) == "depth" and int(s.zs[zid].d) == int(spec[1]):
							c += 1
						elif String(spec[0]) == "col" and int(s.zs[zid].c) == int(spec[1]):
							c += 1
					counts.append(c)
				var best := 0
				for c in counts:
					best = maxi(best, int(c))
				if best > 0 and int(counts[p]) == best:
					pts += int(g.get("bonus", 2))
			return pts
	return _ranked(s, p, g, 1)


static func _ranked(s: Dictionary, p: int, g: Dictionary, mult: int) -> int:
	var counts := []
	for q in s.n:
		counts.append(goal_count(s, q, g))
	var pts := int(counts[p]) * mult * int(g.get("mult", 1))
	if String(g["kind"]) == "fields" and not g.has("lead"):
		var mine := fields(s, p)
		for f in mine:
			var best := 0
			for q in s.n:
				best = maxi(best, int(fields(s, q)[f]))
			if best > 0 and int(mine[f]) == best:
				pts += int(g.get("most", 2))
		return pts
	if int(counts[p]) <= 0:
		return pts
	var lead: Array = g.get("lead", [0, 0])
	var first := 0
	for c in counts:
		first = maxi(first, int(c))
	var n_first := counts.count(first)
	if int(counts[p]) == first:
		return pts + int(lead[0])
	if n_first > 1:
		return pts
	var second := 0
	for c in counts:
		if int(c) < first:
			second = maxi(second, int(c))
	if second > 0 and int(counts[p]) == second:
		return pts + int(lead[1])
	return pts


static func impact_points(s: Dictionary, p: int) -> int:
	var M := GameData.mission(s.mission)
	var hexes: Array = M["hexes"]
	var star := star_col(s)
	var clean_at: Array = M["cleanup"]["clean_at"] if M.has("cleanup") else []
	var n := 0
	for i in hexes.size():
		var k: int = s.impact[i].count(p)
		if k == 0:
			continue
		var h: Dictionary = hexes[i]
		var v := int(h["pts"])
		if h.has("score_col") and int(h["score_col"]) == star:
			v += 2
		if v < 0 and h.has("col") and not clean_at.is_empty() and int(s.cleanup[p]) >= int(clean_at[int(h["col"])]):
			v = 0
		n += v * k
	# Missione 8: ogni segnalino del secondo gruppo più grande vale +1
	if M.get("clusters", false):
		var seen := {}
		var sizes := []
		for i in hexes.size():
			if hexes[i]["inf"] or seen.has(i) or not s.impact[i].has(p):
				continue
			var q := [i]
			seen[i] = true
			var size := 0
			while not q.is_empty():
				var cur: int = q.pop_back()
				size += 1
				for j in hexes[cur]["adj"]:
					if not seen.has(j) and not hexes[j]["inf"] and s.impact[j].has(p):
						seen[j] = true
						q.append(j)
			sizes.append(size)
		sizes.sort()
		if sizes.size() >= 2:
			n += int(sizes[sizes.size() - 2])
	return n


static func spec_points(s: Dictionary, p: int) -> int:
	var pl: Dictionary = s.players[p]
	var n := 0
	for e in pl.specs:
		if not e.senior or e.id == "leader":
			continue
		var sd: Dictionary = GameData.side(e.id, true)
		match String(sd.get("score", "")):
			"zones3":
				var zs := {}
				for v in pl.vessels:
					zs[v] = true
				for zid in s.zs:
					for sid in s.zs[zid].sites:
						if int(s.zs[zid].sites[sid]) == p:
							zs[zid] = true
				n += zs.size() / 3
			"cons_zones":
				for zid in s.zs:
					for sid in s.zs[zid].sites:
						if int(s.zs[zid].sites[sid]) == p and String(site(zid, sid)["t"]) == "cons":
							n += 1
							break
			"seniors":
				for e2 in pl.specs:
					if e2.senior and not is_same(e2, e):
						n += 1
			"shared_links":
				var k := 0
				for zid in s.zs:
					var z: Dictionary = GameData.zones[zid]
					for li in z["links"].size():
						if not s.zs[zid].links[li]:
							continue
						var a := int(s.zs[zid].sites[z["links"][li]["a"]])
						var b := int(s.zs[zid].sites[z["links"][li]["b"]])
						if (a == p and b != p) or (b == p and a != p):
							k += 1
				n += k / 2
			"field_sets":
				var f := fields(s, p)
				var m := 99
				for kf in f:
					m = mini(m, int(f[kf]))
				n += 3 * m
			"flat4":
				n += 4
			"cons_one_zone":
				var best := 0
				for zid in s.zs:
					var k := 0
					for sid in s.zs[zid].sites:
						if int(s.zs[zid].sites[sid]) == p and String(site(zid, sid)["t"]) == "cons":
							k += 1
					best = maxi(best, k)
				n += best
			"empty_dives":
				var k := 0
				for zid in s.zs:
					for sid in s.zs[zid].dives:
						if s.zs[zid].dives[sid].is_empty():
							k += 1
				n += k / 2
			"journal_depths":
				var ds := {}
				for zid in s.zs:
					for sid in s.zs[zid].sites:
						if int(s.zs[zid].sites[sid]) == p and String(site(zid, sid)["t"]) == "journal":
							ds[int(s.zs[zid].d)] = true
				n += ds.size()
	return n


static func score(s: Dictionary, p: int) -> Dictionary:
	var pl: Dictionary = s.players[p]
	var res := {}
	var a := 0
	for k in GameData.ATTRS:
		a += GameData.bracket(int(pl.attrs[k]))
	res["attributi"] = a
	res["impatto"] = impact_points(s, p)
	var jp := 0
	for e in pl.journals:
		jp += int(GameData.journals[e.id]["points"])
	res["diari"] = jp
	res["specialisti"] = spec_points(s, p)
	var left: int = int(pl.res) + maxi(0, int(pl.staging))
	for t in pl.tokens:
		left += int(GameData.dive[t]["res"])
	res["avanzi"] = left / 3
	var goals: Array = GameData.mission(s.mission)["goals"]
	for i in goals.size():
		res["obiettivo %d" % (i + 1)] = goal_points(s, p, goals[i])
	var tot := 0
	for k in res:
		tot += int(res[k])
	res["total"] = tot
	return res


## Dischi totali di un giocatore ovunque si trovino (controllo di conservazione).
static func disc_total(s: Dictionary, p: int) -> int:
	var pl: Dictionary = s.players[p]
	var n: int = int(pl.supply) + int(pl.staging)
	for e in pl.specs:
		if e.disc:
			n += 1
	for je in pl.journals:
		for u in je.used:
			if u:
				n += 1
	for zid in s.zs:
		for sid in s.zs[zid].sites:
			if int(s.zs[zid].sites[sid]) == p and not s.zs[zid].imp.has(sid):
				n += 1
	return n


# ═════════════════════════════ TESTI ═════════════════════════════

static func spec_name(s: Dictionary, p: int, si: int) -> String:
	return String(spec_side(s, p, si)["name"])


static func log_line(s: Dictionary, msg: String) -> void:
	s.log.append(msg)
	if s.log.size() > LOG_MAX:
		s.log = s.log.slice(s.log.size() - LOG_MAX)


static func option_text(s: Dictionary, p: int, a: String, o: Dictionary) -> String:
	match String(o.get("a", a)):
		"travel":
			return "Viaggio %s → %s" % [GameData.zone_name(o.from), GameData.zone_name(o.to)]
		"sonar":
			var st: Dictionary = site(o.z, o.s)
			return "Sonar in %s (%s)" % [GameData.zone_name(o.z), ("Scoperta " + String(st["disc"])) if st.has("disc") else GameData.rewards_text(st.get("r", []))]
		"dive":
			return "Immersione in %s" % GameData.zone_name(o.z)
		"cons":
			var st: Dictionary = site(o.z, o.s)
			return "Conservazione in %s: costo %d → %s" % [GameData.zone_name(o.z), int(o.cost), GameData.rewards_text(st.get("r", []))]
		"journal":
			return "Diario in %s: «%s» (costo %d)" % [GameData.zone_name(o.z), GameData.journals[o.j]["en"], int(GameData.journals[o.j]["cost"])]
		"promote":
			return "Promuovi %s" % spec_name(s, p, int(o.si))
		"discover":
			return "Scoperta %s" % String(o.r)
		"impact", "any", "low", "disc", "trade", "promote_any":
			return GameData.REWARD_NAMES.get(o.a, o.a) if o.a != "promote_any" else "Promozione"
	return str(o)


static func describe(s: Dictionary, p: int, m: Dictionary) -> String:
	match String(m["t"]):
		"recruit":
			var sd: Dictionary = GameData.side(m.id, false)
			return "Recluta %s (livello %d): %s; %s" % [sd["name"], spec_tier(m.id), GameData.rewards_text(sd["gain"]), GameData.acts_text(sd["acts"])]
		"reclaim":
			return "Riassegna %s" % spec_name(s, p, int(m.si))
		"activate":
			return "%s → %s" % [spec_name(s, p, int(m.si)), option_text(s, p, String(m.a), m.o)]
		"jslot":
			return "Diario → %s" % option_text(s, p, String(m.a), m.o)
		"tok_fx":
			return "Segnalino → %s" % option_text(s, p, "", m.o)
		"tok_res":
			return "Segnalino → %d Ricerca" % int(GameData.dive[s.players[p].tokens[int(m.k)]]["res"])
		"pass":
			return "Passa"
		"end":
			return "Fine turno"
		"attr":
			return GameData.ATTR_NAMES[m.a]
		"hex":
			return "Impatto sull'esagono %d" % int(m.h)
		"promote":
			return "Promuovi %s" % spec_name(s, p, int(m.si))
		"skip":
			return "Salta"
		"opt":
			return option_text(s, p, String(m.a), m.o)
		"draw":
			return "Pesca una tessera di profondità %d" % int(m.d)
		"place":
			return "Metti %s in colonna %s, profondità %d" % [GameData.zone_name(m.z), GameData.COL_LETTERS[int(m.c)], int(m.d)]
		"launch":
			return "Zona di partenza: %s" % GameData.zone_name(m.z)
		"gchoice":
			var gdef: Dictionary = GameData.mission(s.mission)["goals"][int(m.g) - 1]
			var opt: Dictionary = gdef["options"][int(m.o)]
			return "Obiettivo %d: %s — %s" % [int(m.g), opt["label"], opt["text"]]
		"star":
			return "Obiettivo 3: siti di %s" % ("Conservazione" if m.k == "cons" else "Diario")
		"pick":
			return "Tieni il segnalino %s" % String(s.stack.back().toks[int(m.k)]) if not s.stack.is_empty() else "Tieni il segnalino"
	return str(m)


## Bersagli cliccabili di una mossa, in ordine: il primo è ciò che si "prende" (Specialista,
## token, spazio del Giornale), poi i bersagli sul tabellone. Chiavi:
## spec:<i> tok:<k> jslot:<ji> zone:<zid> vsl:<zid> site:<zid>:<sid> jdisp:<jid> hex:<i>
## track:<attr> res stack:<d> board:<zid> slot:<c>:<d> rec:<id>:<pk> pick:<k>
static func move_keys(s: Dictionary, m: Dictionary) -> Array:
	var out := []
	match String(m["t"]):
		"recruit":
			return ["rec:%s:%d" % [m.id, int(m.pk)]]
		"reclaim", "promote":
			return ["spec:%d" % int(m.si)]
		"activate":
			out.append("spec:%d" % int(m.si))
			if m.has("copy"):
				out.append("copy:%d" % int(m.copy))
		"jslot":
			out.append("jslot:%d" % int(m.ji))
		"tok_fx":
			out.append("tok:%d" % int(m.k))
		"tok_res":
			return ["tok:%d" % int(m.k), "res"]
		"attr":
			return ["track:" + String(m.a)]
		"hex":
			if m.has("from"):
				return ["hex:%d" % int(m.from), "hex:%d" % int(m.h)]
			return ["hex:%d" % int(m.h)]
		"draw":
			return ["stack:%d" % int(m.d)]
		"place":
			return ["board:" + String(m.z), "slot:%d:%d" % [int(m.c), int(m.d)]]
		"launch":
			return ["zone:" + String(m.z)]
		"pick":
			return ["pick:%d" % int(m.k)]
		"gchoice":
			return ["fx:goal%d" % int(m.o)]
		"star":
			return ["fx:" + String(m.k)]
		"pass", "end", "skip":
			return []
	var o: Dictionary = m.get("o", {})
	match String(o.get("a", "")):
		"travel":
			out.append("zone:" + String(o.to))
			out.append("vsl:" + String(o.from))
		"sonar", "dive", "cons":
			out.append("site:%s:%s" % [o.z, o.s])
		"journal":
			out.append("site:%s:%s" % [o.z, o.s])
			out.append("jdisp:" + String(o.j))
		"promote":
			out.append("spec:%d" % int(o.si))
		"impact", "any", "low", "disc", "trade", "promote_any", "discover":
			out.append("fx:" + String(o.a))
	return out
