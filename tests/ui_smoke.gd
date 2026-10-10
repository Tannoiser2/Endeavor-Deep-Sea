extends SceneTree
## Smoke test dell'interfaccia: il giocatore umano gioca CLICCANDO (chiavi-bersaglio delle mosse:
## Specialista → bersaglio nell'oceano, esagoni, reclutamento...), le mosse sono scelte da un'IA di supporto.
## Uso: godot --path . -s res://tests/ui_smoke.gd -- <cartella_screenshot> [missione]

var main: Node
var frames := 0
var helper := AIPlayer.new(7)
var out_dir := "user://"
var mission := 1
var clicks := {}
var shot_at := {}
var errors := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		mission = int(args[1])
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		_shot("menu")
		return false
	if frames == 8:
		main._start_game([
			{"name": "Stefano", "ai": false, "ai_level": 0, "color": "purple"},
			{"name": "Giallo", "ai": true, "ai_level": 2, "color": "yellow"},
			{"name": "Rosso", "ai": true, "ai_level": 3, "color": "red"}], 11, {"mission": mission})
		return false
	if frames < 12:
		return false
	var gs = main._current
	gs.speed.value = 0.05
	var d: Dictionary = gs.decision
	if d.type == "game_over":
		await _shot("fine")
		print("FINE OK: ", gs.state.log.back())
		print("Clic usati: ", clicks, " errori: ", errors)
		return true
	if gs._human() and frames % 3 == 0:
		var tag := "%s_r%d" % [d.type if d.type != "frame" else d.frame, gs.state.round]
		if not shot_at.has(tag) and (tag in ["action_r1", "action_r3", "recruit_r2", "impact_r2", "impact_r3", "discover_r1", "discover_r2", "action_r5"]):
			shot_at[tag] = true
			_shot(tag)
			return false
		_play_by_click(gs, helper.choose(gs.state, d))
	if frames > 9000:
		print("Fine smoke test (limite frame)")
		return true
	return false


func _count(k: String) -> void:
	clicks[k] = clicks.get(k, 0) + 1


func _play_by_click(gs, m: Dictionary) -> void:
	var before = gs.state.get("last", {})
	var keys: Array = Rules.move_keys(gs.state, m)
	for k in keys:
		if String(k).begins_with("fx:") or String(k).begins_with("pick:"):
			continue
		if not is_same(gs.state.get("last", {}), before):
			return
		gs._on_click(k)
		_count(String(k).split(":")[0])
		if gs.popup.visible:
			_count("popup")
			var i: int = gs._popup_moves.find(m)
			gs.popup.hide()
			gs._apply_human(gs._popup_moves[i] if i >= 0 else m)
			return
	if is_same(gs.state.get("last", {}), before):
		_count("chip")
		gs._apply_human(m)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("shot_%s.png" % name))
	print("screenshot ", name)
