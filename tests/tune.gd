extends SceneTree
## Taratura dei pesi dell'IA: un giocatore con i pesi variati contro due con i pesi di base
## (tutti livello 2), sedile a rotazione. Stampa la differenza media di punteggio.
## Uso: godot --headless --path . -s res://tests/tune.gd -- <partite> chiave=valore ...

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 12
	var over := {}
	for a in args.slice(1):
		var kv := String(a).split("=")
		over[kv[0]] = float(kv[1])
	GameData.ensure_loaded()
	var diff := 0.0
	var wins := 0
	var t0 := Time.get_ticks_msec()
	for g in games:
		var seat := g % 3
		var specs := []
		for i in 3:
			specs.append({"name": "IA%d" % i, "ai": true, "ai_level": 2, "color": GameData.COLORS[i]})
		var s := Rules.new_game(specs, 500 + g, {"mission": 1 + (g / 3) % 4})
		var ais := []
		for i in 3:
			var a := AIPlayer.new(900 + g * 7 + i)
			if i == seat:
				for k in over:
					a.w[k] = over[k]
			ais.append(a)
		while true:
			var d := Rules.current_decision(s)
			if d.type == "game_over":
				break
			Rules.apply(s, ais[d.p].choose(s, d))
		var mine: int = Rules.score(s, seat)["total"]
		var others := 0.0
		var best := true
		for q in 3:
			if q != seat:
				var o: int = Rules.score(s, q)["total"]
				others += o / 2.0
				if o >= mine:
					best = false
		diff += mine - others
		if best:
			wins += 1
	print("VARIANTE %s: diff media %+.2f, vittorie %d/%d (%d ms)" % [over, diff / games, wins, games, Time.get_ticks_msec() - t0])
	quit()
