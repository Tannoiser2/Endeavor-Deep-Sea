extends SceneTree
## Prova del gioco online: due istanze (chi crea la stanza e un amico) giocano una partita intera sul
## finto Firebase (tests/firebase_mock.py), con un terzo colore IA. Le persone sono simulate dall'IA.
## Variabili: EDS_ROLE=host|guest, EDS_CODEFILE=file per il codice della stanza, EDS_MISSION=1..10,
## EDS_PHASE=drop (l'ospite esce a metà) oppure back (rientra con lo stesso codice).
## Alla fine ognuno stampa l'impronta della partita: devono coincidere.

var main
var t0 := 0
var bot := AIPlayer.new(77)


func _init() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	t0 = Time.get_ticks_msec()
	_run()


func _wait(s: float) -> void:
	await create_timer(s).timeout


## Sceglie nel menu il tipo di giocatore di una riga (-1 non gioca, 0 umano, 1-3 IA).
func _set_row(menu, i: int, v: int) -> void:
	for b in menu._rows[i].group.get_buttons():
		if int(b.get_meta("v")) == v:
			b.button_pressed = true
	menu._refresh_rows()


func _run() -> void:
	await _wait(0.5)
	var role := OS.get_environment("EDS_ROLE")
	var cf := OS.get_environment("EDS_CODEFILE")
	var phase := OS.get_environment("EDS_PHASE")
	var mid := int(OS.get_environment("EDS_MISSION")) if OS.get_environment("EDS_MISSION") != "" else 1
	var menu = main._current
	_set_row(menu, 0, 0)
	_set_row(menu, 1, 0)
	_set_row(menu, 2, 2)
	_set_row(menu, 3, -1)
	for b in menu._mission.get_buttons():
		if int(b.get_meta("v")) == mid:
			b.button_pressed = true
	menu._online_panel()
	menu._on_name.text = "Host" if role == "host" else "Ospite"
	if role == "host":
		await menu._online_create()
		var code: String = main.lobby.get("code", "")
		print("EDSTEST stanza ", code)
		var f := FileAccess.open(cf, FileAccess.WRITE)
		f.store_string(code)
		f.close()
		while true:
			var room: Dictionary = await main.net.room(code)
			if Net._as_dict(room.get("seats", {})).size() >= 2:
				break
			await _wait(0.5)
		await menu._online_begin_host()
	else:
		var code := ""
		while code == "":
			if FileAccess.file_exists(cf):
				code = FileAccess.get_file_as_string(cf).strip_edges()
			await _wait(0.3)
		menu._on_code.text = code
		await menu._online_join()
	var drop_at := 3
	while true:
		await process_frame
		if Time.get_ticks_msec() - t0 > 1500000:
			print("EDSTEST tempo scaduto")
			quit(2)
			return
		var gs = main._current
		if not (gs is GameScreen) or gs.state.is_empty():
			continue
		gs.speed.value = 0.05
		if gs._net_status.begins_with("⚠"):
			print("EDSTEST ERRORE ", gs._net_status)
			quit(3)
			return
		if phase == "drop" and int(gs.state.round) >= drop_at and gs.decision.get("type", "") == "action":
			print("EDSTEST esco a metà partita, mossa ", gs.online.n)
			quit(0)
			return
		if gs.decision.get("type", "") == "game_over":
			await _wait(0.5)
			var sc := []
			for p in gs.state.n:
				sc.append(Rules.score(gs.state, p)["total"])
			var fp := "%s|%d|%s" % [str(sc), gs.state.log.size(), var_to_str(gs.state.players).md5_text().substr(0, 10)]
			print("EDSTEST impronta ", gs.online.n, " | ", fp)
			quit(0)
			return
		if gs._human() and not gs._net_busy:
			gs._apply_human(bot.choose(gs.state, gs.decision))
			await _wait(0.05)
