extends SceneTree
## Simulazione headless: N partite IA contro IA, controlla invarianti e stampa statistiche.
## Uso: godot --headless --path . -s res://tests/sim.gd -- [partite] [giocatori] [missione 0=a rotazione] [livello IA fisso]

var errors := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 6
	var players := int(args[1]) if args.size() > 1 else 3
	var mission := int(args[2]) if args.size() > 2 else 0
	var fixed_level := int(args[3]) if args.size() > 3 else 0
	GameData.ensure_loaded()
	var wins := {}
	var totals := []
	var t0 := Time.get_ticks_msec()
	var discovered := 0
	var lvl_sum := {}
	var lvl_n := {}
	for g in games:
		var specs := []
		for i in players:
			var lvl := fixed_level if fixed_level > 0 else 1 + ((i + g) % 3)
			specs.append({"name": "IA%d" % (i + 1), "ai": true, "ai_level": lvl, "color": GameData.COLORS[i]})
		var mid := mission if mission > 0 else 1 + (g % 10)
		var s := Rules.new_game(specs, g, {"mission": mid})
		var ai := AIPlayer.new(g)
		var steps := 0
		while true:
			var d := Rules.current_decision(s)
			if d.type == "game_over" or d.type == "error":
				if d.type == "error":
					errors += 1
				break
			if d.moves.is_empty():
				push_error("Partita %d: decisione senza mosse %s" % [g, d])
				errors += 1
				break
			Rules.apply(s, ai.choose(s, d))
			steps += 1
			_check(s, g)
			if steps > 5000:
				push_error("Partita %d: troppi passi" % g)
				errors += 1
				break
		discovered += s.zs.size()
		var best := -1
		var best_sc := -999
		for p in players:
			var sc: int = Rules.score(s, p)["total"]
			totals.append(sc)
			var lv: int = s.players[p].ai_level
			lvl_sum[lv] = lvl_sum.get(lv, 0) + sc
			lvl_n[lv] = lvl_n.get(lv, 0) + 1
			if sc > best_sc:
				best_sc = sc
				best = p
		var lvl: int = s.players[best].ai_level
		wins[lvl] = wins.get(lvl, 0) + 1
		print("Partita %d (M%d, %d passi, %d zone): %s" % [g, mid, steps, s.zs.size(),
			", ".join(range(players).map(func(p): return "%s L%d=%d" % [s.players[p].name, s.players[p].ai_level, Rules.score(s, p)["total"]]))])
		if g == 0:
			for line in s.log.slice(maxi(0, s.log.size() - 8)):
				print("   ", line)
			for p in players:
				print("   ", s.players[p].name, " ", Rules.score(s, p), " attr ", s.players[p].attrs, " spec ", s.players[p].specs.size())
	totals.sort()
	print("Partite: %d, errori: %d. Vittorie per livello IA: %s" % [games, errors, wins])
	print("Punteggi min/mediana/max: %d / %d / %d — zone medie %.1f" % [totals[0], totals[totals.size() / 2], totals[-1], float(discovered) / games])
	for lv in [1, 2, 3]:
		if lvl_n.has(lv):
			print("Media livello %d: %.1f" % [lv, float(lvl_sum[lv]) / lvl_n[lv]])
	print("Tempo: %d ms" % (Time.get_ticks_msec() - t0))
	quit(1 if errors > 0 else 0)


func _check(s: Dictionary, g: int) -> void:
	var expected := int(GameData.rules["discs"])
	for p in s.n:
		var pl: Dictionary = s.players[p]
		if pl.staging < 0 or pl.res < 0 or pl.res > 12:
			push_error("Partita %d: valori fuori scala per %s (staging %d, ricerca %d) dopo %s" % [g, pl.name, pl.staging, pl.res, s.last])
			errors += 1
		var tot := Rules.disc_total(s, p)
		if tot != expected:
			push_error("Partita %d: dischi di %s = %d (attesi %d) dopo %s" % [g, pl.name, tot, expected, s.last])
			errors += 1
		var launching: bool = s.stack.any(func(f): return String(f.f) == "launch")
		if not launching and pl.vessels.size() + int(pl.vessels_left) != int(GameData.rules["vessels"]):
			push_error("Partita %d: navi di %s incoerenti" % [g, pl.name])
			errors += 1
	if errors > 20:
		quit(1)
