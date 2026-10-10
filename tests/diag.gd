extends SceneTree
## Diagnostica: quali mosse sceglie l'IA (per tarare i pesi).
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mid := int(args[0]) if args.size() > 0 else 1
	var lv := int(args[1]) if args.size() > 1 else 2
	GameData.ensure_loaded()
	var cnt := {}
	var specs := []
	for i in 3:
		specs.append({"name": "IA%d" % i, "ai": true, "ai_level": lv, "color": GameData.COLORS[i]})
	var s := Rules.new_game(specs, 5, {"mission": mid})
	var ai := AIPlayer.new(5)
	while true:
		var d := Rules.current_decision(s)
		if d.type == "game_over":
			break
		var m := ai.choose(s, d)
		var k: String = m["t"]
		if m.has("a"):
			k += ":" + String(m.a)
		elif m.has("o") and m.o.has("a"):
			k += ":" + String(m.o.a)
		cnt[k] = cnt.get(k, 0) + 1
		if d.type in ["action", "recruit"] and d.p == 0:
			print("R%d %s staging=%d res=%d tok=%d  -> %s  (%d mosse)" % [s.round, s.players[d.p].name, s.players[d.p].staging, s.players[d.p].res, s.players[d.p].tokens.size(), Rules.describe(s, d.p, m), d.moves.size()])
		Rules.apply(s, m)
	print(cnt)
	for p in 3:
		print(s.players[p].name, " ", Rules.score(s, p), " ", s.players[p].attrs, " res ", s.players[p].res, " staging ", s.players[p].staging)
	quit()
