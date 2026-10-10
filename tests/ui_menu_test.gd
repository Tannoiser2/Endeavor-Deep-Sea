extends SceneTree
## Menu: seleziona una per una tutte le missioni (e prova le combinazioni di giocatori),
## poi avvia la partita con ognuna. Uso: godot --path . -s res://tests/ui_menu_test.gd
var main: Node
var frames := 0
var ss
var mid := 1

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _process(_d: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	if mid > GameData.missions.size():
		print("MENU OK: tutte le missioni selezionate e avviate")
		return true
	if frames % 2 == 1:
		ss = main._current
		if not (ss is SetupScreen):
			main._show_setup()
			return false
		for b in ss._mission.get_buttons():
			if int(b.get_meta("v")) == mid:
				b.button_pressed = true
				b.pressed.emit()
		ss._refresh_mission()
		print("Missione %d: %s" % [mid, ss._mission_info.text.split("\n")[0]])
		ss._on_start()
	else:
		var gs = main._current
		if gs is GameScreen:
			print("   partita avviata, round ", gs.state.round)
		mid += 1
		main._show_setup()
	return false
