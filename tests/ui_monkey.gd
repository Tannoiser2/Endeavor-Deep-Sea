extends SceneTree
## Test "scimmia": eventi di mouse veri (movimento, clic sinistro/destro, doppio clic, rotellina) in
## punti casuali, mentre un'IA di supporto fa avanzare la partita. Cerca errori di script dell'interfaccia.
## Uso: godot --path . -s res://tests/ui_monkey.gd -- <missione_da> <missione_a> <giocatori>
var main: Node
var frames := 0
var rng := RandomNumberGenerator.new()
var helper := AIPlayer.new(3)
var queue: Array = []
var cur := {}
var t_start := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	for m in range(int(a[0]) if a.size() > 0 else 1, (int(a[1]) if a.size() > 1 else 10) + 1):
		queue.append({"m": m, "n": int(a[2]) if a.size() > 2 else 3})
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rng.seed = 7

func _ev(e: InputEvent) -> void:
	root.push_input(e)

func _mouse(pos: Vector2, btn: int = 0, dbl: bool = false) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = pos
	mm.global_position = pos
	mm.relative = Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
	if btn == MOUSE_BUTTON_RIGHT and rng.randf() < 0.5:
		mm.button_mask = MOUSE_BUTTON_MASK_RIGHT
	_ev(mm)
	if btn > 0:
		for pressed in [true, false]:
			var b := InputEventMouseButton.new()
			b.position = pos
			b.global_position = pos
			b.button_index = btn
			b.pressed = pressed
			b.double_click = dbl and pressed
			_ev(b)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if cur.is_empty():
		if queue.is_empty():
			print("SCIMMIA FINITA")
			return true
		cur = queue.pop_front()
		var specs := []
		var cols := ["purple", "yellow", "red", "white"]
		for i in cur.n:
			specs.append({"name": "P%d" % i, "ai": i > 0, "ai_level": 2, "color": cols[i]})
		main._start_game(specs, cur.m * 7, {"mission": cur.m})
		t_start = frames
		print("== Missione %d" % cur.m)
		return false
	var gs = main._current
	if not (gs is GameScreen):
		return false
	gs.speed.value = 0.05
	# chiude finestre e popup aperti ogni tanto
	if gs.big_view.visible and rng.randf() < 0.3:
		gs.big_view.hide()
	if gs.popup.visible and rng.randf() < 0.5:
		gs.popup.hide()
	# eventi casuali
	var sz: Vector2 = root.get_visible_rect().size
	for k in 4:
		var pos := Vector2(rng.randf() * sz.x, rng.randf() * sz.y)
		var r := rng.randf()
		if r < 0.55:
			_mouse(pos)
		elif r < 0.8:
			_mouse(pos, MOUSE_BUTTON_LEFT, rng.randf() < 0.15)
		elif r < 0.9:
			_mouse(pos, MOUSE_BUTTON_RIGHT)
		else:
			_mouse(pos, MOUSE_BUTTON_WHEEL_UP if rng.randf() < 0.5 else MOUSE_BUTTON_WHEEL_DOWN)
	var d: Dictionary = gs.decision
	if d.type == "game_over" or frames - t_start > 1500:
		print("   fine: ", gs.state.log.back())
		cur = {}
		return false
	if gs._human() and frames % 4 == 0:
		gs._apply_human(helper.choose(gs.state, d))
	return false
