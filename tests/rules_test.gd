extends SceneTree
## Test mirati sulle regole (zone speciali, collegamenti, tracciati, pagamenti).
## Uso: godot --headless --path . -s res://tests/rules_test.gd

var fails := 0


func _init() -> void:
	GameData.ensure_loaded()
	_t_links()
	_t_track_overflow()
	_t_vessel_gain()
	_t_whale_calving()
	_t_shipwreck()
	_t_cave()
	_t_trench_and_vortex()
	_t_oil_rig()
	_t_payment()
	_t_discover_full()
	_t_goals()
	print("Test regole: %s" % ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		push_error("FALLITO: " + msg)
	else:
		print("  ok  ", msg)


func _new(n: int = 2, mission: int = 1) -> Dictionary:
	var specs := []
	for i in n:
		specs.append({"name": "P%d" % i, "ai": true, "color": GameData.COLORS[i]})
	var s := Rules.new_game(specs, 3, {"mission": mission})
	# risolve le Navi iniziali
	_settle(s)
	s.phase = "action"
	s.turn = {"p": 0, "acted": false, "tok": false}
	s.turn_i = (0 - int(s.wave) + n) % n
	for i in n:
		s.passed[i] = false
	return s


## Risolve le decisioni pendenti scegliendo sempre la prima mossa.
func _settle(s: Dictionary) -> void:
	var g := 0
	while not s.stack.is_empty() and g < 50:
		var d := Rules.current_decision(s)
		if d.type != "frame":
			break
		Rules.apply(s, d.moves[0])
		g += 1


func _put(s: Dictionary, zid: String, c: int, d: int) -> void:
	for k in s.stacks:
		s.stacks[k].erase(zid)
	Rules._place_zone(s, zid, c, d)


func _t_links() -> void:
	var s := _new()
	_put(s, "kelp_forest", 0, 1)
	s.players[0].staging = 5
	s.players[1].staging = 5
	s.players[0].res = 5
	s.players[1].res = 5
	var r0 := int(s.players[0].attrs.coord)
	var r1 := int(s.players[1].attrs.coord)
	Rules.exec_option(s, 0, "cons", {"a": "cons", "z": "kelp_forest", "s": "c1", "cost": 2}, {})
	_settle(s)
	Rules.exec_option(s, 1, "cons", {"a": "cons", "z": "kelp_forest", "s": "c2", "cost": 1}, {})
	_settle(s)
	# c2 dà +1 Coordinazione, il collegamento c1–c2 +1 Coordinazione a entrambi
	_ok(int(s.players[1].attrs.coord) == r1 + 2, "collegamento: chi completa ottiene ricompensa del sito + collegamento")
	_ok(int(s.players[0].attrs.coord) == r0 + 1 + 1, "collegamento: anche l'altro capo ottiene la ricompensa")
	_ok(s.zs["kelp_forest"].links[0] == true, "collegamento segnato come completato")


func _t_track_overflow() -> void:
	var s := _new()
	s.players[0].attrs.rep = 9
	Rules.attr_gain(s, 0, "rep", 1)
	_ok(s.stack.back().f == "impact", "al 10 si ottiene un Impatto")
	_settle(s)
	s.players[0].attrs.rep = 12
	Rules.attr_gain(s, 0, "rep", 1)
	_ok(int(s.players[0].attrs.rep) == 10 and s.stack.back().f == "impact", "oltre il 12 si torna al 10 con un Impatto")
	_settle(s)


func _t_vessel_gain() -> void:
	var s := _new()
	s.players[0].attrs.ing = 1
	var nv: int = s.players[0].vessels.size()
	Rules.attr_gain(s, 0, "ing", 1)
	_settle(s)
	_ok(s.players[0].vessels.size() == nv + 1 and int(s.players[0].vessels_left) == 1, "Ingegno 2: nuova Nave nella zona di partenza")
	s.players[0].attrs.ing = 1
	Rules.attr_gain(s, 0, "ing", 1)
	_settle(s)
	_ok(s.players[0].vessels.size() == nv + 1, "la stessa soglia non dà una seconda Nave")


func _t_whale_calving() -> void:
	var s := _new()
	_put(s, "whale_calving", 0, 2)
	s.players[0].vessels.append("whale_calving")
	s.players[0].staging = 6
	s.players[0].res = 10
	s.zs["whale_calving"].sites["j1"] = 0
	s.players[0].staging -= 1
	Rules.exec_option(s, 0, "cons", {"a": "cons", "z": "whale_calving", "s": "c5", "cost": 0}, {})
	var d := Rules.current_decision(s)
	var found := false
	for i in 6:
		if d.type == "frame" and d.frame == "act":
			found = true
			break
		Rules.apply(s, d.moves[0])
		d = Rules.current_decision(s)
	_ok(found and d.moves.any(func(m): return m["t"] == "opt" and m.o.a == "cons"), "Nursery delle balene: seconda Conservazione col Giornale segnato")
	s.stack.clear()


func _t_shipwreck() -> void:
	var s := _new()
	_put(s, "shipwreck", 0, 2)
	s.players[0].vessels.append("shipwreck")
	var before: int = s.zs["shipwreck"].dives["d"].size()
	Rules.exec_option(s, 0, "dive", {"a": "dive", "z": "shipwreck", "s": "d"}, {})
	var d := Rules.current_decision(s)
	_ok(d.frame == "pick_token" and d.moves.size() == 2, "Relitto: si pescano due token e se ne sceglie uno")
	Rules.apply(s, d.moves[0])
	_ok(s.zs["shipwreck"].dives["d"].size() == before - 2 and s.players[0].tokens.size() == 1, "Relitto: uno tenuto, uno scartato")


func _t_cave() -> void:
	var s := _new()
	_put(s, "kelp_forest", 0, 1)
	_put(s, "cave_system", 0, 2)
	_put(s, "dolphin_pods", 1, 2)
	s.players[0].vessels = ["kelp_forest"]
	_ok(Rules.can_access(s, 0, "cave_system", "d_up") and not Rules.can_access(s, 0, "cave_system", "d_right"),
		"Grotte: la grotta in alto si usa dalla zona sopra, quella a destra no")
	var r := Rules.reachable(s, "kelp_forest", 3, 3)
	_ok(not r.has("cave_system"), "Grotte: le Navi non entrano")
	s.players[0].vessels = ["dolphin_pods"]
	_ok(Rules.can_access(s, 0, "cave_system", "d_right"), "Grotte: la grotta a destra si usa dalla zona a destra")


func _t_trench_and_vortex() -> void:
	var s := _new()
	_put(s, "kelp_forest", 0, 1)
	_put(s, "dolphin_pods", 0, 2)
	_put(s, "vortex", 0, 3)
	_put(s, "bioluminescent", 0, 4)
	_put(s, "abyssal_trench", 0, 5)
	s.players[0].vessels = ["vortex", "abyssal_trench"]
	s.players[0].attrs.ing = 4   # Tecnologia 3: dal Vortice +1 → 4, non basta per la profondità 5? (4 < 5)
	var opts := Rules.options(s, 0, "travel", {"staging": 1})
	_ok(opts.any(func(o): return o.from == "vortex" and o.to == "bioluminescent"), "Vortice: Tecnologia +1 viaggiando via (profondità 4)")
	s.players[0].attrs.ing = 10
	opts = Rules.options(s, 0, "travel", {"staging": 1})
	_ok(not opts.any(func(o): return o.to == "abyssal_trench"), "Fossa abissale: al massimo una Nave per giocatore")


func _t_oil_rig() -> void:
	var s := _new()
	_put(s, "oil_rig", 0, 1)
	s.players[0].specs.append({"id": "pilot", "senior": false, "disc": false})
	s.players[1].specs.append({"id": "pilot", "senior": false, "disc": false})
	s.players[0].staging = 6
	s.players[0].res = 12
	for sid in ["c1", "c2", "c4"]:
		s.zs["oil_rig"].sites[sid] = 1
	s.players[1].staging -= 3
	Rules.exec_option(s, 0, "cons", {"a": "cons", "z": "oil_rig", "s": "c3", "cost": 4}, {})
	var promos := 0
	for i in 20:
		var d := Rules.current_decision(s)
		if d.type != "frame":
			break
		if d.frame == "promote":
			promos += 1
		Rules.apply(s, d.moves[0])
	_ok(promos == 2 and s.players[0].specs[1].senior and s.players[1].specs[1].senior, "Piattaforma piena: promuovono tutti quelli con dischi")


func _t_payment() -> void:
	var s := _new()
	s.players[0].res = 1
	s.players[0].tokens = ["plain"]
	Rules.pay(s, 0, 3)
	_ok(int(s.players[0].res) == 2 and s.players[0].tokens.is_empty(), "pagamento: la Ricerca mancante si prende dai token")


func _t_discover_full() -> void:
	var s := _new()
	for d in range(1, 6):
		s.stacks[str(d)] = []
	var n0: int = s.players[0].impact_n
	s.stack.append({"f": "discover", "p": 0, "r": "1-2", "skip": false, "drawn": []})
	var d := Rules.current_decision(s)
	_ok(d.frame == "impact", "Scoperta impossibile e pile vuote: Impatto al posto")
	Rules.apply(s, d.moves[0])
	_settle(s)
	_ok(int(s.players[0].impact_n) == n0 + 1, "Impatto piazzato")


func _t_goals() -> void:
	var s := _new(3)
	var g := {"kind": "discs", "site": "sonar", "lead": [5, 3]}
	s.zs["sea_star"].sites["s1"] = 0
	s.zs["sea_star"].sites["s2"] = 0
	s.zs["sea_star"].sites["s3"] = 1
	_ok(Rules.goal_points(s, 0, g) == 2 + 5 and Rules.goal_points(s, 1, g) == 1 + 3 and Rules.goal_points(s, 2, g) == 0,
		"obiettivo: 1° e 2° posto")
	s.zs["sea_star"].sites["s3"] = 0
	s.zs["volcanic_island"].sites["s1"] = 1
	s.zs["volcanic_island"].sites["s2"] = 1
	s.zs["volcanic_island"].sites["s1"] = 1
	# 0 ha 3, 1 ha 2 → ancora 1° e 2°; ora pareggio
	s.zs["looking_glass"].sites["s1"] = 1
	_ok(Rules.goal_points(s, 0, g) == 3 + 5 and Rules.goal_points(s, 1, g) == 3 + 5, "obiettivo: pari merito, tutti il 1°")
