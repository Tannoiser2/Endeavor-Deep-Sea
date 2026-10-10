extends SceneTree
## Fuzz: partite con mosse casuali (più qualche partita con IA) per stanare stati illegali.
## Uso: godot --headless --path . -s res://tests/fuzz.gd -- [partite] [giocatori]

var errors := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 40
	var players := int(args[1]) if args.size() > 1 else 4
	GameData.ensure_loaded()
	var rng := RandomNumberGenerator.new()
	var kinds := {}
	for g in games:
		rng.seed = g * 31 + 7
		var specs := []
		for i in players:
			specs.append({"name": "R%d" % i, "ai": true, "ai_level": 1, "color": GameData.COLORS[i]})
		var mid := 1 + g % 10
		var s := Rules.new_game(specs, g + 1000, {"mission": mid})
		var steps := 0
		while true:
			var d := Rules.current_decision(s)
			if d.type == "game_over":
				break
			if d.type == "error" or d.moves.is_empty():
				push_error("Partita %d: decisione non valida %s" % [g, d])
				errors += 1
				break
			# preferisce non passare, per esplorare più stati
			var m: Dictionary = d.moves[rng.randi_range(0, d.moves.size() - 1)]
			if m["t"] in ["pass", "skip", "end"] and d.moves.size() > 1 and rng.randf() < 0.85:
				m = d.moves[rng.randi_range(0, d.moves.size() - 2)]
			kinds[m["t"]] = kinds.get(m["t"], 0) + 1
			Rules.apply(s, m)
			steps += 1
			for p in s.n:
				var pl: Dictionary = s.players[p]
				if Rules.disc_total(s, p) != int(GameData.rules["discs"]):
					push_error("Partita %d: conservazione dischi violata dopo %s" % [g, m])
					errors += 1
				if pl.staging < 0 or pl.res < 0 or pl.res > 12:
					push_error("Partita %d: valori fuori scala dopo %s" % [g, m])
					errors += 1
				for a in GameData.ATTRS:
					if int(pl.attrs[a]) < 0 or int(pl.attrs[a]) > 12:
						push_error("Partita %d: attributo fuori scala" % g)
						errors += 1
			if steps > 8000:
				push_error("Partita %d: troppi passi" % g)
				errors += 1
				break
			if errors > 10:
				quit(1)
				return
		for p in s.n:
			Rules.score(s, p)
		if g % 10 == 0:
			print("Partita %d (M%d): %d passi, %d zone, punteggi %s" % [g, mid, steps, s.zs.size(),
				range(s.n).map(func(p): return Rules.score(s, p)["total"])])
	print("Mosse: ", kinds)
	print("Fuzz: %d partite, errori %d" % [games, errors])
	quit(1 if errors > 0 else 0)
