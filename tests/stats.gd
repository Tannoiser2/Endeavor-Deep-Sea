extends SceneTree
## Statistiche per partita: Sonar, Scoperte, Diari pubblicati (e quante volte erano possibili).
## godot --headless --path . -s res://tests/stats.gd -- <partite> <giocatori> <livello> [peso=valore ...]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 10
	var n := int(args[1]) if args.size() > 1 else 3
	var lv := int(args[2]) if args.size() > 2 else 2
	var over := {}
	for a in args.slice(3):
		var kv := String(a).split("=")
		over[kv[0]] = float(kv[1])
	GameData.ensure_loaded()
	var tot := {}
	for g in games:
		var specs := []
		for i in n:
			specs.append({"name": "IA%d" % i, "ai": true, "ai_level": lv, "color": GameData.COLORS[i]})
		var mid := 1 + g % 10
		var s := Rules.new_game(specs, 100 + g, {"mission": mid})
		var ai := AIPlayer.new(100 + g)
		for k in over:
			ai.w[k] = over[k]
		var c := {"sonar": 0, "scoperte": 0, "diari": 0, "turni": 0, "sonar_poss": 0, "diario_poss": 0,
			"cons": 0, "res_sum": 0}
		var zones0: int = s.zs.size()
		while true:
			var d := Rules.current_decision(s)
			if d.type == "game_over":
				break
			var m := ai.choose(s, d)
			if d.type == "action":
				c.turni += 1
				var hs := false
				var hj := false
				for mv in d.moves:
					var a: String = String(mv.get("a", mv.get("o", {}).get("a", "")))
					if a == "sonar": hs = true
					if a == "journal": hj = true
				if hs: c.sonar_poss += 1
				if hj: c.diario_poss += 1
				c.res_sum += int(s.players[d.p].res)
			Rules.apply(s, m)
		c.scoperte = s.zs.size() - zones0
		c.round = s.round
		for zid in s.zs:
			for sid in s.zs[zid].sites:
				if int(s.zs[zid].sites[sid]) >= 0:
					var tt: String = Rules.site(zid, sid)["t"]
					if c.has(tt):
						c[tt] += 1
		var dj := 0
		for p in n:
			dj += s.players[p].journals.size()
		c.diari = dj
		var left := 0
		for p in n:
			left += int(s.players[p].staging)
		c.dischi_avanzati = snappedf(float(left) / n, 0.1)
		c.res_media = snappedf(float(c.res_sum) / maxf(1, c.turni), 0.1)
		c.erase("res_sum")
		print("M%d " % mid, c)
		for k in c:
			tot[k] = tot.get(k, 0.0) + float(c[k])
	for k in tot:
		tot[k] = snappedf(tot[k] / games, 0.1)
	print("MEDIA ", tot)
	quit()
