extends SceneTree
## Stress dell'interfaccia: tutte le missioni, 2-4 giocatori, semi diversi, un umano che gioca a clic
## (mosse casuali fra quelle legali) e gli altri IA. Si ferma al primo errore di script.
## Uso: godot --path . -s res://tests/ui_stress.gd -- <missione_da> <missione_a> <giocatori>
var main: Node
var frames := 0
var rng := RandomNumberGenerator.new()
var queue: Array = []
var cur := {}
var t_start := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var m0 := int(a[0]) if a.size() > 0 else 1
	var m1 := int(a[1]) if a.size() > 1 else 10
	var np := int(a[2]) if a.size() > 2 else 4
	for m in range(m0, m1 + 1):
		queue.append({"m": m, "n": np, "seed": m * 13 + np})
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rng.seed = 99

func _next() -> bool:
	if queue.is_empty():
		print("STRESS FINITO")
		return true
	cur = queue.pop_front()
	var specs := []
	var cols := ["purple", "yellow", "red", "white"]
	for i in cur.n:
		specs.append({"name": "P%d" % i, "ai": i > 0, "ai_level": 1 + i % 3, "color": cols[i]})
	main._start_game(specs, cur.seed, {"mission": cur.m})
	t_start = frames
	print("== Missione %d, %d giocatori" % [cur.m, cur.n])
	return false

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if cur.is_empty():
		return _next()
	var gs = main._current
	if not (gs is GameScreen):
		return false
	gs.speed.value = 0.05
	var d: Dictionary = gs.decision
	if d.type == "game_over" or frames - t_start > 6000:
		print("   finita: ", gs.state.log.back())
		cur = {}
		return false
	if gs._human() and frames % 2 == 0:
		var m: Dictionary = d.moves[rng.randi_range(0, d.moves.size() - 1)]
		if m["t"] in ["pass", "end"] and d.moves.size() > 1 and rng.randf() < 0.8:
			m = d.moves[rng.randi_range(0, d.moves.size() - 1)]
		var before = gs.state.get("last", {})
		for k in Rules.move_keys(gs.state, m):
			if String(k).begins_with("fx:") or String(k).begins_with("pick:"):
				continue
			if not is_same(gs.state.get("last", {}), before):
				break
			gs._on_click(k)
			if gs.popup.visible:
				var i: int = gs._popup_moves.find(m)
				gs.popup.hide()
				gs._apply_human(gs._popup_moves[i] if i >= 0 else m)
				break
		if is_same(gs.state.get("last", {}), before):
			gs._apply_human(m)
	return false
