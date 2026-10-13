extends Control
## Punto d'ingresso: alterna menu iniziale e partita (sullo stesso dispositivo o online).

var _current: Control
## Collegamento a Firebase per il gioco online (resta vivo fra menu e partita).
var net: Net
## Stanza online in preparazione: {role, code, seat}. Vuota se non si è in una stanza.
var lobby := {}


func _ready() -> void:
	GameData.ensure_loaded()
	net = Net.new()
	add_child(net)
	_show_setup()


func _show_setup() -> void:
	var ss := SetupScreen.new()
	ss.net = net
	ss.lobby = lobby
	_swap(ss)
	ss.start_requested.connect(_start_game)
	ss.online_start_requested.connect(_start_online)


func _start_game(specs: Array, seed_value: int, opts: Dictionary = {}) -> void:
	var gs := GameScreen.new()
	gs.setup(specs, seed_value, opts)
	gs.back_to_menu.connect(_show_setup)
	gs.rematch_requested.connect(func(): _start_game(gs.game_specs, -1, gs.game_opts))
	_swap(gs)


func _start_online(specs: Array, seed_value: int, opts: Dictionary, session: OnlineSession) -> void:
	var gs := GameScreen.new()
	gs.setup(specs, seed_value, opts)
	gs.online = session
	gs.back_to_menu.connect(_show_setup)
	_swap(gs)


func _swap(c: Control) -> void:
	if _current:
		_current.queue_free()
	_current = c
	add_child(c)
