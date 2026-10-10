class_name AIPlayer
extends RefCounted
## IA a simulazione: per ogni mossa legale simula l'esito su una copia dello stato e la valuta.
## Livello 1 = principiante (molto rumore), 2 = normale, 3 = esperta (con un passo di anticipo
## sulle sotto-decisioni dello stesso giocatore). I pesi sono tutti in W.

const W := {
	"score": 1.0,
	"track_step": 0.35,          # passo sul tracciato verso il prossimo scaglione di punti
	"act": 0.5,                  # valore di un'azione in un round futuro
	"res_val": 0.0,              # Ricerca in mano (fino a 6) per Diari e Conservazioni future
	"engine": 2.2,               # combinazioni: Specialisti x occasioni vicine x Ricerca, per round futuro
	"insp_mult": 2.0,            # azioni per livello di Impegno (dischi nuovi per round)
	"act_now": 1.5,              # azione ancora possibile in questo round (si perde passando)
	"rep_lvl": 0.5,              # livello di Reclutamento (Specialisti migliori), per round futuro
	"ing_lvl": 0.35,             # livello di Tecnologia, per round futuro
	"token": 0.7,
	"vessel": 1.2,               # Nave in mare
	"junior": 0.9,               # Specialista Junior promuovibile (valore della futura Promozione)
	"deep_vessel": 0.25,         # Nave in profondità (accesso a zone più ricche)
	"dive_access": 0.2,          # siti Immersione raggiungibili dalle proprie Navi
	"journal_slot": 0.9,         # azione di Giornale non usata
	"journal_pub": 1.0,          # Giornale pubblicato (Campi per gli obiettivi, effetti duraturi)
	"presence": 0.3,             # dischi nei siti dell'oceano (obiettivi, collegamenti, maggioranze)
	"opp": 5.0,                  # opportunità: siti liberi e token Immersione alla portata delle Navi
	"rival": 0.3,
}
const NOISE := [0.0, 2.2, 0.8, 0.15]
const MAX_EVAL := 160
const ROLLOUT_K := 4          # mosse migliori esaminate fino a fine round (IA esperta)
const ROLLOUT_STEPS := 40
const ROLLOUT_EVAL := 24
const FOLLOW_DEPTH := 3       # sotto-decisioni proprie risolte dopo una mossa
const FOLLOW_EVAL := 12

var rng := RandomNumberGenerator.new()
var w: Dictionary = W.duplicate()      # pesi di questa IA (i test possono variarli)


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func choose(s: Dictionary, decision: Dictionary) -> Dictionary:
	var moves: Array = decision.moves
	if moves.size() == 1:
		return moves[0]
	var p: int = decision.p
	var level: int = clampi(int(s.players[p].get("ai_level", 2)), 0, 3)
	var noise: float = NOISE[level]
	var pool := _sample(moves, MAX_EVAL)
	var scored := []
	for m in pool:
		var v := _value_after(s, p, m, level >= 3)
		scored.append([v + rng.randf_range(-noise, noise), m])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	# Esperta: le mosse migliori si giocano fino alla fine del round (tutti col criterio di base)
	if level >= 3 and decision.type in ["action", "recruit"] and scored.size() > 1:
		var best_v := -INF
		var best: Dictionary = scored[0][1]
		for i in mini(ROLLOUT_K, scored.size()):
			var m: Dictionary = scored[i][1]
			var v := 0.5 * float(scored[i][0]) + 0.5 * _rollout(s, p, m)
			if v > best_v:
				best_v = v
				best = m
		return best
	return scored[0][1]


func _sample(moves: Array, k: int) -> Array:
	if moves.size() <= k:
		return moves
	var pool := []
	var idx := range(moves.size())
	for i in range(idx.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = idx[i]
		idx[i] = idx[j]
		idx[j] = t
	for i in k:
		pool.append(moves[idx[i]])
	for m in moves:
		if m["t"] in ["pass", "end", "skip"] and not pool.has(m):
			pool.append(m)
	return pool


## Gioca la mossa e poi il resto del round con la scelta "a un passo" per tutti; valuta per p.
func _rollout(s: Dictionary, p: int, m: Dictionary) -> float:
	var c := clone(s)
	_hide(c)
	Rules.apply(c, m)
	var rnd := int(c.round)
	for step in ROLLOUT_STEPS:
		var d := Rules.current_decision(c)
		if d.type == "game_over" or int(c.round) != rnd or d.moves.is_empty():
			break
		var bm: Dictionary = d.moves[0]
		if d.moves.size() > 1:
			var bv := -INF
			for mm in _sample(d.moves, ROLLOUT_EVAL):
				var c2 := clone(c)
				Rules.apply(c2, mm)
				Rules.current_decision(c2)
				var v := evaluate(c2, d.p)
				if v > bv:
					bv = v
					bm = mm
		Rules.apply(c, bm)
	Rules.current_decision(c)
	return evaluate(c, p)


func _value_after(s: Dictionary, p: int, m: Dictionary, lookahead: bool) -> float:
	var c := clone(s)
	_hide(c)
	Rules.apply(c, m)
	var d := Rules.current_decision(c)
	if lookahead and d.p == p and d.type == "frame" and d.moves.size() <= 40:
		var bv := -INF
		for m2 in d.moves:
			var c2 := clone(c)
			Rules.apply(c2, m2)
			_finish_own(c2, p, FOLLOW_DEPTH - 1)
			bv = maxf(bv, evaluate(c2, p))
		return bv
	_finish_own(c, p, FOLLOW_DEPTH)
	return evaluate(c, p)


## Risolve in modo goloso le sotto-decisioni dello stesso giocatore (Scoperta, guadagni a scelta,
## Promozione...), così il valore di una mossa include ciò che porta (es. il bonus della tessera
## scoperta) e non solo lo stato a metà.
func _finish_own(c: Dictionary, p: int, depth: int) -> void:
	for i in depth:
		var d := Rules.current_decision(c)
		if d.p != p or d.type != "frame" or d.moves.is_empty():
			return
		var best: Dictionary = d.moves[0]
		if d.moves.size() > 1:
			var bv := -INF
			for m2 in _sample(d.moves, FOLLOW_EVAL):
				var c2 := clone(c)
				Rules.apply(c2, m2)
				Rules.current_decision(c2)
				var v := evaluate(c2, p)
				if v > bv:
					bv = v
					best = m2
		Rules.apply(c, best)
	Rules.current_decision(c)


## L'IA non conosce l'ordine delle pile coperte: nella copia le rimescola.
func _hide(c: Dictionary) -> void:
	for d in c.stacks:
		var a: Array = c.stacks[d]
		for i in range(a.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var x = a[i]
			a[i] = a[j]
			a[j] = x
	for zid in c.zs:
		for sid in c.zs[zid].dives:
			c.zs[zid].dives[sid].shuffle()
	var ds: Array = c.dive_supply
	for i in range(ds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var x = ds[i]
		ds[i] = ds[j]
		ds[j] = x


static func clone(s: Dictionary) -> Dictionary:
	var lg = s.log
	s.log = []
	var c: Dictionary = s.duplicate(true)
	s.log = lg
	return c


func evaluate(s: Dictionary, p: int) -> float:
	var mine := _raw(s, p)
	var rival := -INF
	for q in s.n:
		if q != p:
			rival = maxf(rival, _raw(s, q))
	if rival == -INF:
		rival = 0.0
	return mine - w.rival * rival


func _raw(s: Dictionary, p: int) -> float:
	var R := GameData.rules
	var pl: Dictionary = s.players[p]
	var sc := Rules.score(s, p)
	if s.phase == "game_over":
		return float(sc["total"])
	var rnd := int(s.round)
	var in_action: bool = s.phase == "action"
	# round futuri completi (il round in corso conta se non siamo ancora all'Attivazione)
	var fr := float(int(R["rounds"]) - rnd + (0 if in_action else 1))
	var v: float = float(sc["total"] - sc["avanzi"]) * w.score
	# avanzi continui: Ricerca + dischi + token valgono 1/3 di punto
	var left := float(pl.res) + float(maxi(0, int(pl.staging)))
	for t in pl.tokens:
		left += float(GameData.dive[t]["res"])
	v += left / 3.0
	# avvicinarsi al prossimo scaglione di punti di ogni tracciato
	for a in GameData.ATTRS:
		var val := int(pl.attrs[a])
		var b := GameData.bracket(val)
		var nxt := val + 1
		while nxt <= 12 and GameData.bracket(nxt) == b:
			nxt += 1
		if nxt <= 12:
			v += w.track_step * float(GameData.bracket(nxt) - b) / float(nxt - val + 1)
	# motore: azioni per round = Specialisti con azioni, limitati da Coordinazione e Ispirazione
	var act_specs := 0
	var free_now := 0
	for e in pl.specs:
		if not e.senior:
			v += w.junior
		var sd: Dictionary = GameData.side(e.id, e.senior)
		if not sd.get("acts", {}).get("list", []).is_empty():
			act_specs += 1
			if not e.disc:
				free_now += 1
	var coord := float(Rules.lvl(s, p, "coord"))
	var insp := float(Rules.lvl(s, p, "insp"))
	# i dischi sugli Specialisti tornano con la Riassegnazione: l'Impegno limita meno della Coordinazione
	var per_round := minf(float(act_specs) + 0.5, minf(coord + 1.0, insp * w.insp_mult + 0.5))
	v += per_round * w.act * fr
	if fr > 0:
		v += w.res_val * minf(float(Rules.research_avail(s, p)), 6.0)
	if w.engine > 0.0 and fr > 0:
		v += w.engine * _engine(s, p, int(coord + 1.0), insp * w.insp_mult + 0.5) * fr
	v += w.rep_lvl * float(Rules.lvl(s, p, "rep") - 1) * minf(fr, 4.0)
	v += w.ing_lvl * float(Rules.lvl(s, p, "ing") - 1) * minf(fr, 3.0)
	if in_action and not s.passed[p]:
		v += float(mini(free_now, maxi(0, int(pl.staging)))) * w.act_now
		for je in pl.journals:
			for u in je.used:
				if not u:
					v += w.journal_slot
					break
	elif fr > 0:
		for je in pl.journals:
			for u in je.used:
				if not u:
					v += w.journal_slot
					break
	for t in pl.tokens:
		v += w.token
	v += float(pl.vessels.size()) * w.vessel * minf(fr + 1.0, 3.0) / 3.0
	for z in pl.vessels:
		v += w.deep_vessel * float(int(s.zs[z].d) - 1)
		for sid in s.zs[z].dives:
			if not s.zs[z].dives[sid].is_empty():
				v += w.dive_access
	v += w.journal_pub * float(pl.journals.size())
	if w.presence > 0.0:
		var nd := 0
		for z in s.zs:
			for sid in s.zs[z].sites:
				if int(s.zs[z].sites[sid]) == p:
					nd += 1
		v += w.presence * float(nd)
	if w.opp > 0.0 and (fr > 0 or in_action):
		v += w.opp * _opportunity(s, p) * minf(fr + (1.0 if in_action else 0.0), 3.0) / 3.0
	return v


## Quanto oceano utile hanno a portata le Navi del giocatore: siti liberi (Sonar: la prima casella
## libera di ogni tracciato) e token Immersione, pieni nelle zone con una propria Nave, a metà in
## quelle raggiungibili con un Viaggio. Radice quadrata: conta la varietà, non riempire i siti.
func _opportunity(s: Dictionary, p: int) -> float:
	var pl: Dictionary = s.players[p]
	# quanto il giocatore sa fare ogni azione: 1 con due Specialisti che la fanno (il Capo squadra
	# vale mezzo), così reclutare un Operatore sonar rende preziosi i tracciati Sonar vicini
	var cap := {"sonar": 0.0, "cons": 0.0, "journal": 0.0, "dive": 0.0}
	for si in pl.specs.size():
		var lst: Array = Rules.spec_acts(s, p, si).get("list", [])
		var k := 0.5 if String(pl.specs[si].id) == "leader" else 1.0
		var seen := {}
		for a in lst:
			if cap.has(a) and not seen.has(a):
				seen[a] = true
				cap[a] += k
	for je in pl.journals:
		for sl in GameData.journals[je.id]["slots"]:
			var a := String(sl)
			if a.begins_with("cons"):
				a = "cons"
			elif a.begins_with("dive"):
				a = "dive"
			if cap.has(a):
				cap[a] += 0.5
	for a in cap:
		cap[a] = 0.3 + 0.7 * minf(cap[a], 2.0) / 2.0
	var t := Rules.tech(s, p)
	var near := {}
	for z in pl.vessels:
		near[z] = 1.0
	for z in pl.vessels:
		for z2 in Rules.reachable(s, z, t, mini(t, 5)):
			if not near.has(z2):
				near[z2] = 0.5
	var opp := 0.0
	for z in near:
		var f: float = near[z]
		var gz: Dictionary = GameData.zones[z]
		var zs: Dictionary = s.zs[z]
		for sid in zs.sites:
			if int(zs.sites[sid]) >= 0:
				continue
			var tt: String = gz["sites"][sid]["t"]
			if tt == "cons" or tt == "journal":
				opp += f * cap[tt]
		for tk in gz["tracks"]:
			for sid in gz["tracks"][tk]:
				if int(zs.sites[sid]) < 0:
					opp += f * cap["sonar"]
					break
		for sid in zs.dives:
			opp += f * 0.5 * minf(float(zs.dives[sid].size()), 3.0) * cap["dive"]
	return sqrt(opp)


## Valore delle combinazioni per un round futuro: ogni Specialista vale l'azione migliore che può
## fare con le occasioni alla portata delle Navi (Sonar con tracciati liberi, Diari con siti adatti
## e Ricerca per pagarli, Conservazione, Immersioni con token); si contano i migliori che la
## Coordinazione permette di riattivare. Così reclutare, viaggiare e fare Ricerca si legano.
func _engine(s: Dictionary, p: int, slots: int, discs: float) -> float:
	var pl: Dictionary = s.players[p]
	var t := Rules.tech(s, p)
	var near := {}
	for z in pl.vessels:
		near[z] = 1.0
	for z in pl.vessels:
		for z2 in Rules.reachable(s, z, t, mini(t, 5)):
			if not near.has(z2):
				near[z2] = 0.5
	var res := float(Rules.research_avail(s, p)) + 2.0   # un round di Immersioni porta Ricerca
	var fields_ok := {}
	var min_cost := 99
	for jid in s.display:
		for f in GameData.journals[jid]["fields"]:
			fields_ok[f] = true
		min_cost = mini(min_cost, int(GameData.journals[jid]["cost"]))
	var n_sonar := 0.0
	var n_journal := 0.0
	var n_cons := 0.0
	var n_dive := 0.0
	for z in near:
		var f: float = near[z]
		var gz: Dictionary = GameData.zones[z]
		var zs: Dictionary = s.zs[z]
		for sid in zs.sites:
			if int(zs.sites[sid]) >= 0:
				continue
			var st: Dictionary = gz["sites"][sid]
			if st["t"] == "journal" and fields_ok.has(st["field"]):
				n_journal += f
			elif st["t"] == "cons" and float(st["cost"]) <= res:
				n_cons += f
		for tk in gz["tracks"]:
			for sid in gz["tracks"][tk]:
				if int(zs.sites[sid]) < 0:
					n_sonar += f
					break
		for sid in zs.dives:
			n_dive += f * minf(float(zs.dives[sid].size()), 3.0) / 3.0
	var afford := clampf((res - float(min_cost) + 1.0) / 3.0, 0.2, 1.0)
	var q := {"travel": 0.6,
		"sonar": 1.4 * minf(n_sonar / 2.0, 1.0),
		"journal": 1.6 * minf(n_journal / 2.0, 1.0) * afford,
		"cons": 1.5 * minf(n_cons / 2.0, 1.0),
		"dive": 1.1 * minf(n_dive / 2.0, 1.0)}
	var vals := []
	for si in pl.specs.size():
		var acts: Dictionary = Rules.spec_acts(s, p, si)
		var lst: Array = acts.get("list", [])
		if lst.is_empty():
			continue
		var sv := 0.0
		if String(acts.get("mode", "one")) == "all":
			for a in lst:
				sv += 0.8 * float(q.get(a, 0.8))
		else:
			for a in lst:
				sv = maxf(sv, float(q.get(a, 0.8)))
		vals.append(sv)
	vals.sort()
	vals.reverse()
	var out := 0.0
	var k := mini(vals.size(), mini(slots, int(discs)))
	for i in k:
		out += vals[i]
	return out
