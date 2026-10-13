class_name GameScreen
extends Control
## Schermata di gioco. Si gioca cliccando direttamente sulle cose:
## - plancia (a destra, del giocatore di turno): clic su uno Specialista = ci metti un disco
##   ("in mano" sul cerchio) e si illuminano i bersagli; clic sul bersaglio nell'oceano = l'azione
##   parte. Di nuovo clic sullo Specialista = il disco torna nell'area di preparazione. Allo stesso
##   modo il token Immersione e le azioni dei Giornali pubblicati.
## - oceano: zone (Viaggio), siti (Sonar, Immersione, Conservazione, Giornale), pile e spazi vuoti
##   (Scoperta); poi il Giornale in vetrina da pubblicare.
## - Specialisti in basso: clic per reclutare; tabellone Impatto (scheda Missione): clic sull'esagono.
## Ogni mossa ha una lista di chiavi-bersaglio (Rules.move_keys): i clic restringono le mosse
## possibili finché ne resta una. Le scelte obbligate partono da sole.

signal back_to_menu
signal rematch_requested

const BOARD_KEYS := ["spec", "jslot", "tok", "track", "res", "copy"]
const OCEAN_KEYS := ["zone", "vsl", "site", "slot", "stack", "board"]

var state: Dictionary
var ai: AIPlayer
var decision: Dictionary = {}
var chosen: Array = []            # chiavi già cliccate per la mossa in costruzione
var _tex_cache := {}
var game_specs: Array = []
var game_opts: Dictionary = {}

var ocean: OceanView
var board: PlayerBoardView
var team: PlayerBoardView          # squadra del giocatore (Specialisti e Diari) in carte grandi
var mission: MissionView
var supply: SupplyView
var tabs: TabContainer
var top_label: Label
var prompt: Label
var chips: HFlowContainer
var net_label: Label
var players_box: HBoxContainer
var view_tabs: TabContainer        # Oceano / Reclutamento / Missione
var journals_view: SupplyView      # vetrina dei Diari, sotto l'area grande
var _auto_tab := -1                # ultima scheda scelta in automatico
var _view_pick := -1               # giocatore scelto dai riquadri (-1 = quello di turno)
var log_label: RichTextLabel
var ai_timer: Timer
var speed: HSlider
var pause_btn: CheckButton
var popup: PopupMenu
var _popup_moves: Array = []
var big_view: Window
var big_tex: TextureRect
var _shown_player := 0
var _final_layer: Control
var online: OnlineSession = null    # partita online (null = sullo stesso dispositivo)
var _net_busy := false              # una mossa sta viaggiando in rete: niente clic
var _net_status := ""
var _wait_token := 0                # cambia a ogni nuova decisione: ferma le attese vecchie


func setup(specs: Array, seed_value: int, opts: Dictionary = {}) -> void:
	game_specs = specs
	game_opts = opts
	state = Rules.new_game(specs, seed_value, opts)
	ai = AIPlayer.new(seed_value)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if online != null:
		add_child(online)
		online.status_changed.connect(_on_net_status)
		_shown_player = online.seat
		if not online.is_host():
			online.heartbeat_loop()
		if online.catching_up():
			_on_net_status("Riprendo la partita dal punto in cui era…")
	_step()


func tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


# ───────────────────────── costruzione UI ─────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#08141c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := HSplitContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.45
	root.add_child(left)
	var top := HBoxContainer.new()
	left.add_child(top)
	top_label = Label.new()
	top_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_label.add_theme_font_size_override("font_size", 17)
	top.add_child(top_label)
	pause_btn = CheckButton.new()
	pause_btn.text = "Pausa IA"
	pause_btn.toggled.connect(func(on): if not on: _step())
	top.add_child(pause_btn)
	var sl := Label.new()
	sl.text = "Velocità IA"
	top.add_child(sl)
	speed = HSlider.new()
	speed.min_value = 0.05
	speed.max_value = 1.5
	speed.step = 0.05
	speed.value = 0.5
	speed.custom_minimum_size = Vector2(110, 0)
	top.add_child(speed)
	var menu := Button.new()
	menu.text = "Menu"
	menu.pressed.connect(func(): back_to_menu.emit())
	top.add_child(menu)

	# area grande: Oceano, Reclutamento e Missione a schede (si alternano da sole quando servono)
	view_tabs = TabContainer.new()
	view_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view_tabs.add_theme_font_size_override("font_size", 16)
	left.add_child(view_tabs)
	ocean = OceanView.new()
	ocean.name = "Oceano"
	ocean.tex_fn = tex
	ocean.custom_minimum_size = Vector2(500, 300)
	ocean.target_clicked.connect(_on_click)
	ocean.enlarge_requested.connect(show_big)
	view_tabs.add_child(ocean)
	supply = SupplyView.new()
	supply.name = "Reclutamento"
	supply.show_journals = false
	supply.tex_fn = tex
	supply.target_clicked.connect(_on_click)
	supply.enlarge_requested.connect(show_big)
	view_tabs.add_child(supply)
	mission = MissionView.new()
	mission.name = "Missione"
	mission.tex_fn = tex
	mission.target_clicked.connect(_on_click)
	mission.enlarge_requested.connect(show_big)
	view_tabs.add_child(mission)
	# sotto: la vetrina dei Diari
	journals_view = SupplyView.new()
	journals_view.show_specs = false
	journals_view.tex_fn = tex
	journals_view.custom_minimum_size = Vector2(500, 215)
	journals_view.target_clicked.connect(_on_click)
	journals_view.enlarge_requested.connect(show_big)
	left.add_child(journals_view)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(540, 0)
	root.add_child(right)
	# messaggi e scelte in cima alla colonna, sopra la plancia
	var pbox := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.06, 0.13, 0.19, 0.97)
	psb.border_color = Color("#d2a24c")
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(8)
	psb.content_margin_left = 12
	psb.content_margin_right = 12
	psb.content_margin_top = 8
	psb.content_margin_bottom = 8
	pbox.add_theme_stylebox_override("panel", psb)
	pbox.custom_minimum_size = Vector2(0, 96)
	right.add_child(pbox)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pbox.add_child(pv)
	net_label = Label.new()
	net_label.add_theme_font_size_override("font_size", 15)
	net_label.add_theme_color_override("font_color", Color("#f1d38a"))
	net_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	net_label.visible = false
	pv.add_child(net_label)
	prompt = Label.new()
	prompt.add_theme_font_size_override("font_size", 19)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt.custom_minimum_size = Vector2(300, 0)
	pv.add_child(prompt)
	chips = HFlowContainer.new()
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 6)
	pv.add_child(chips)
	# plancia del giocatore e, sotto, la sua squadra in carte grandi
	board = PlayerBoardView.new()
	board.show_team = false
	board.custom_minimum_size = Vector2(480, 300)
	right.resized.connect(func(): board.custom_minimum_size = Vector2(480, maxf(260.0, right.size.x * 0.9 * 1713.0 / 2657.0)))
	board.clicked.connect(_on_click)
	board.enlarge_requested.connect(show_big)
	right.add_child(board)
	team = PlayerBoardView.new()
	team.team_only = true
	team.custom_minimum_size = Vector2(480, 230)
	team.size_flags_vertical = Control.SIZE_EXPAND_FILL
	team.clicked.connect(_on_click)
	team.enlarge_requested.connect(show_big)
	right.add_child(team)
	# riquadri riassuntivi dei giocatori: clic = la sua plancia al posto di quella sopra
	players_box = HBoxContainer.new()
	players_box.add_theme_constant_override("separation", 6)
	right.add_child(players_box)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 130)
	right.add_child(tabs)
	log_label = RichTextLabel.new()
	log_label.name = "Registro"
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", 12)
	tabs.add_child(log_label)
	# Chiarimenti in italiano (zone e scenari), dalle scansioni: clic per ingrandire
	var rscroll := ScrollContainer.new()
	rscroll.name = "Regole"
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(rscroll)
	var rbox := VBoxContainer.new()
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(rbox)
	for pair in [["res://assets/rules/scenari_it.jpg", "Chiarimenti sugli scenari"], ["res://assets/rules/zone_it.jpg", "Regole speciali delle plance Oceano"]]:
		var rt := tex(pair[0])
		if rt == null:
			continue
		var tr := TextureRect.new()
		tr.texture = rt
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tr.tooltip_text = pair[1] + " — clic per ingrandire"
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		var title: String = pair[1]
		tr.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				show_big(rt, title))
		rbox.add_child(tr)

	popup = PopupMenu.new()
	popup.id_pressed.connect(func(i): if i < _popup_moves.size(): _apply_human(_popup_moves[i]))
	add_child(popup)

	big_view = Window.new()
	big_view.title = "Dettaglio"
	big_view.size = Vector2i(900, 640)
	big_view.visible = false
	big_view.close_requested.connect(func(): big_view.hide())
	big_tex = TextureRect.new()
	big_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	big_view.add_child(big_tex)
	add_child(big_view)

	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.timeout.connect(_ai_move)
	add_child(ai_timer)


func show_big(t: Texture2D, title: String) -> void:
	if t == null:
		return
	big_tex.texture = t
	big_view.title = title
	big_view.popup_centered()


# ───────────────────────── ciclo di gioco ─────────────────────────

func _human() -> bool:
	if online != null:
		return decision.get("p", -1) == online.seat and not _net_busy
	return decision.get("p", -1) >= 0 and not state.players[decision.p].ai


func _human_exists() -> bool:
	for pl in state.players:
		if not pl.ai:
			return true
	return false


func _step() -> void:
	if online != null:
		_step_online()
		return
	decision = Rules.current_decision(state)
	chosen = []
	var guard := 0
	while _human() and decision.moves.size() == 1 and guard < 60:
		Rules.apply(state, decision.moves[0])
		decision = Rules.current_decision(state)
		guard += 1
	if _human():
		_view_pick = -1
	if decision.get("p", -1) >= 0 and (_human() or not _human_exists()):
		_shown_player = decision.p
	elif decision.get("p", -1) >= 0 and state.players[_shown_player].ai:
		_shown_player = decision.p
	_refresh_all()
	if decision.type == "game_over":
		_show_final()
		return
	if not _human() and not pause_btn.button_pressed:
		ai_timer.start(speed.value)


func _ai_move() -> void:
	if decision.is_empty() or decision.type == "game_over" or _human():
		return
	if online != null:
		_net_play(ai.choose(state, decision))
		return
	Rules.apply(state, ai.choose(state, decision))
	_step()


func _apply_human(m: Dictionary) -> void:
	chosen = []
	if online != null:
		if _human():
			_net_play(m)
		return
	Rules.apply(state, m)
	_step()


# ───────────────────────── online ─────────────────────────

## Come _step, ma in lockstep: le scelte obbligate le applicano tutti da soli; le mosse già nel
## registro (rientro) si riapplicano in fila; poi decide chi tocca: io, l'IA (se ho creato la stanza)
## oppure si aspetta la mossa dalla rete.
func _step_online() -> void:
	_wait_token += 1
	chosen = []
	var guard := 0
	while guard < 20000:
		guard += 1
		decision = Rules.current_decision(state)
		if decision.type == "game_over" or decision.get("p", -1) < 0:
			break
		if decision.moves.size() == 1:
			Rules.apply(state, decision.moves[0])
			continue
		var a := online.from_backlog()
		if a.is_empty():
			break
		if not _apply_act(a):
			return
	if online.n >= online.backlog.size() and _net_status.begins_with("Riprendo"):
		_on_net_status("")
	if decision.get("p", -1) >= 0:
		_shown_player = decision.p
	if _human():
		_view_pick = -1
	_refresh_all()
	if decision.type == "game_over":
		online.finish()
		_show_final()
		return
	var p: int = decision.p
	var tok := _wait_token
	if p == online.seat:
		_on_net_status("")
		_watch_mine(tok)
	elif online.is_host() and state.players[p].ai:
		if not pause_btn.button_pressed:
			ai_timer.start(speed.value)
	elif online.is_host() and online.away.has(p):
		_host_away_turn(p, tok)
	else:
		_wait_remote(tok)


## Applica una mossa del registro; false se la partita non è allineata.
func _apply_act(a: Dictionary) -> bool:
	var i := int(a.get("i", -1))
	if i < 0 or i >= decision.moves.size() or OnlineSession.check(decision.moves[i]) != String(a.get("c", "")):
		_on_net_status("⚠ La partita non è più allineata con gli altri dispositivi (mossa %d). Torna al menu e rientra nella stanza." % online.n)
		_net_busy = true
		_refresh_all()
		return false
	online.n += 1
	Rules.apply(state, decision.moves[i])
	return true


## Gioca la mossa m (mia o dell'IA): prima la scrive nel registro, poi la applica.
## Se nel frattempo un altro dispositivo aveva già scritto quella mossa, vale la sua.
func _net_play(m: Dictionary) -> void:
	if _net_busy:
		return
	var idx: int = decision.moves.find(m)
	if idx < 0:
		for j in decision.moves.size():
			if var_to_str(decision.moves[j]) == var_to_str(m):
				idx = j
				break
	if idx < 0:
		return
	_net_busy = true
	ai_timer.stop()
	_refresh_interaction()
	var a := await online.publish(int(decision.p), idx, OnlineSession.check(decision.moves[idx]))
	if not is_inside_tree():
		return
	_net_busy = false
	if int(a.get("i", -1)) != idx and int(decision.p) == online.seat:
		_on_net_status("Eri via: l'IA ha giocato al tuo posto.")
	if _apply_act(a):
		_step()


## Aspetta la mossa di un altro dispositivo. Chi ha creato la stanza controlla anche la presenza:
## se il giocatore tace da un minuto, gioca l'IA al suo posto finché non rientra.
func _wait_remote(tok: int) -> void:
	var p: int = decision.p
	var t0 := Time.get_ticks_msec()
	var polls := 0
	_on_net_status("Online · stanza %s · tocca a %s" % [online.code, state.players[p].name])
	while is_inside_tree() and tok == _wait_token:
		var a := await online.poll()
		if not is_inside_tree() or tok != _wait_token:
			return
		if not a.is_empty() and not a.has("_err"):
			_on_net_status("")
			if _apply_act(a):
				_step()
			return
		var waited := Time.get_ticks_msec() - t0
		if online.is_host() and not state.players[p].ai and polls % 4 == 3:
			if not await online.check_presence(p, waited):
				if not is_inside_tree() or tok != _wait_token:
					return
				_step()
				return
		if waited > 60000:
			_on_net_status("Online · stanza %s · tocca a %s (aspetto da più di un minuto…)" % [online.code, state.players[p].name])
		polls += 1
		await get_tree().create_timer(1.2).timeout


## Mentre decido io, controllo che l'IA non abbia già giocato al mio posto (se ero stato via).
## Chi ha creato la stanza controlla invece se i giocatori assenti sono tornati.
func _watch_mine(tok: int) -> void:
	while is_inside_tree() and tok == _wait_token:
		await get_tree().create_timer(3.0).timeout
		if not is_inside_tree() or tok != _wait_token or _net_busy:
			return
		var a := await online.poll()
		if not is_inside_tree() or tok != _wait_token or _net_busy:
			return
		if not a.is_empty() and not a.has("_err"):
			_on_net_status("Eri via: l'IA ha giocato al tuo posto.")
			if _apply_act(a):
				_step()
			return


## Tocca a un giocatore assente: se è tornato lo si aspetta, altrimenti gioca l'IA al suo posto.
func _host_away_turn(p: int, tok: int) -> void:
	if await online.back_again(p):
		if is_inside_tree() and tok == _wait_token:
			_wait_remote(tok)
		return
	if not is_inside_tree() or tok != _wait_token:
		return
	_on_net_status("%s è assente: per ora gioca l'IA al suo posto." % state.players[p].name)
	if not pause_btn.button_pressed:
		ai_timer.start(speed.value)


func _on_net_status(text: String) -> void:
	_net_status = text
	if is_instance_valid(net_label):
		net_label.text = text
		net_label.visible = text != ""


# ───────────────────────── interazione ─────────────────────────

func _keys(m: Dictionary) -> Array:
	return Rules.move_keys(state, m)


func _cands() -> Array:
	if decision.is_empty() or not decision.has("moves"):
		return []
	var out := []
	for m in decision.moves:
		var ks := _keys(m)
		var ok := true
		for c in chosen:
			if not ks.has(c):
				ok = false
				break
		if ok and (not chosen.is_empty() or not ks.is_empty()):
			out.append(m)
	return out


## Chiavi da illuminare: per ogni mossa candidata la prima chiave non ancora scelta.
func _next_keys(cands: Array) -> Array:
	var out := []
	for m in cands:
		for k in _keys(m):
			if chosen.has(k):
				continue
			if not out.has(k):
				out.append(k)
			break
	return out


func _on_click(key: String) -> void:
	if not _human() or decision.type == "game_over":
		return
	if not chosen.is_empty() and chosen[0] == key:
		chosen = []            # il disco torna nell'area di preparazione
		_refresh_interaction()
		return
	var hits := _cands().filter(func(m): return _keys(m).has(key))
	if hits.is_empty() and not chosen.is_empty():
		# clic su un'altra "presa": si ricomincia da quella
		var fresh: Array = decision.moves.filter(func(m): return _keys(m).size() > 0 and _keys(m)[0] == key)
		if fresh.is_empty():
			return
		chosen = []
		hits = fresh
	if hits.is_empty():
		return
	chosen.append(key)
	var c := _cands()
	if c.size() == 1:
		_apply_human(c[0])
		return
	var remaining := _next_keys(c).filter(func(k): return not String(k).begins_with("fx:"))
	if remaining.is_empty():
		_resolve(c)
		return
	_refresh_interaction()


func _resolve(hits: Array) -> void:
	if hits.size() == 1:
		_apply_human(hits[0])
		return
	_popup_moves = hits
	popup.clear()
	for i in hits.size():
		popup.add_item(Rules.describe(state, decision.p, hits[i]), i)
	popup.position = Vector2i(get_global_mouse_position()) + Vector2i(get_window().position)
	popup.popup()


func _refresh_interaction() -> void:
	var human := _human()
	var cands := _cands() if human else []
	var keys := _next_keys(cands) if human else []
	var b := []
	var o := []
	var h := []
	var s := []
	var jd := []
	for k in keys:
		var pre := String(k).split(":")[0]
		if pre in BOARD_KEYS:
			b.append(k)
		elif pre in OCEAN_KEYS:
			o.append(k)
		elif pre == "hex":
			h.append(k)
		elif pre == "rec":
			s.append(k)
		elif pre == "jdisp":
			jd.append(k)
	state["_ui_p"] = decision.get("p", -1)
	ocean.set_highlights(o)
	mission.set_highlights(h)
	supply.set_highlights(s)
	journals_view.set_highlights(jd)
	board.set_interaction(b, chosen[0] if not chosen.is_empty() else "", human and _shown_player == decision.p)
	team.set_interaction(b, chosen[0] if not chosen.is_empty() else "", human and _shown_player == decision.p)
	_auto_view(not h.is_empty())
	_update_prompt()
	_update_chips(cands)


func _update_prompt() -> void:
	if decision.type == "game_over":
		prompt.text = "Partita finita."
		return
	var p: int = decision.p
	var pl: Dictionary = state.players[p]
	if not _human():
		prompt.text = "%s sta pensando…" % pl.name
		return
	var t := ""
	match decision.type:
		"recruit":
			t = "Reclutamento: scegli uno Specialista nella scheda Reclutamento (livello massimo %d)." % Rules.lvl(state, p, "rep")
		"reassign":
			t = "Riassegnazione: clicca lo Specialista da cui riprendere il gettone (ancora %d)." % int(state.reassign_left)
		"action":
			if chosen.is_empty():
				t = "%s, tocca a te (gettoni pronti: %d). Clicca uno Specialista, il segnalino Immersione o un Diario; oppure Passa." % [pl.name, int(pl.staging)]
			else:
				t = "Clicca il bersaglio illuminato. Di nuovo clic sullo Specialista per ritirare il gettone."
		"frame":
			match String(decision.frame):
				"gains":
					t = "Scegli l'attributo da far avanzare (clic sul tracciato)."
				"impact":
					t = "Impatto: clicca l'esagono dove mettere il segnalino (scheda Missione)."
				"promote":
					t = "Promozione: clicca lo Specialista Junior da girare."
				"act", "acts":
					t = "Continua: clicca il bersaglio illuminato, oppure Salta."
				"discover":
					t = "Scoperta: pesca dalle pile illuminate, poi scegli la tessera e lo spazio."
				"launch":
					t = "Scegli la zona di profondità 1 dove mettere la Nave."
				"excess":
					t = "Puoi tenere un solo segnalino Immersione: usa o converti in Ricerca quelli in più."
				"pick_token":
					t = "Relitto: scegli quale dei due segnalini tenere."
				"goal_choice":
					t = "Esagono Obiettivo: scegli come si conterà questo obiettivo (per tutti)."
				"star_choice":
					t = "Hai scoperto la Stella Cadente: scegli il tipo di sito che conterà per l'obiettivo 3."
	prompt.text = t


func _chip(text: String, cb: Callable, tip: String = "") -> void:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(0, 36)
	SetupScreen.gold(b)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	chips.add_child(b)


func _update_chips(cands: Array) -> void:
	for c in chips.get_children():
		c.queue_free()
	if not _human():
		return
	var p: int = decision.p
	if not chosen.is_empty():
		_chip("Annulla", func():
			chosen = []
			_refresh_interaction())
	for m in decision.moves:
		var t: String = m["t"]
		if t in ["pass", "end", "skip"] and chosen.is_empty():
			var mm: Dictionary = m
			_chip({"pass": "Passa", "end": "Fine turno", "skip": "Salta"}[t], func(): _apply_human(mm))
	# mosse senza un bersaglio cliccabile (effetti dei token, scelte del Relitto)
	for m in cands:
		var ks := _keys(m)
		var rest := ks.filter(func(k): return not chosen.has(k))
		if rest.is_empty() or not rest.all(func(k): return String(k).begins_with("fx:") or String(k).begins_with("pick:")):
			continue
		var label := Rules.describe(state, p, m)
		if m["t"] == "pick":
			label = "Tieni: %s" % GameData.REWARD_NAMES.get(GameData.dive[state.stack.back().toks[int(m.k)]]["fx"], "solo Ricerca")
		var mm: Dictionary = m
		_chip(label, func(): _apply_human(mm))


# ───────────────────────── pannelli ─────────────────────────

func _refresh_all() -> void:
	var drawn := []
	if not state.stack.is_empty() and String(state.stack.back().f) == "discover":
		drawn = state.stack.back().get("drawn", [])
	state["_ui_p"] = decision.get("p", -1)
	ocean.set_state(state, drawn)
	mission.set_state(state)
	supply.set_state(state)
	journals_view.set_state(state)
	if _view_pick >= 0:
		_shown_player = _view_pick
	board.set_data(state, _shown_player, tex)
	team.set_data(state, _shown_player, tex)
	var who := ""
	if decision.has("p") and decision.p >= 0:
		who = " — tocca a " + state.players[decision.p].name + (" (IA)" if state.players[decision.p].ai else "")
	top_label.text = "Missione %d — Round %d/%d — %s%s" % [int(state.mission), mini(state.round, int(GameData.rules["rounds"])),
		int(GameData.rules["rounds"]), Rules.PHASE_NAMES.get(state.phase, state.phase), who]
	for c in players_box.get_children():
		c.queue_free()
	for q in state.n:
		players_box.add_child(_summary_box(q))
	log_label.text = "\n".join(state.log.slice(maxi(0, state.log.size() - 160)))
	_refresh_interaction()


## Riquadro riassuntivo di un giocatore: punti, attributi, Ricerca, dischi, Navi, squadra.
## Clic = la sua plancia al posto di quella grande (di nuovo clic sul giocatore di turno per tornare).
func _summary_box(q: int) -> Control:
	var pl: Dictionary = state.players[q]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	var shown := q == _shown_player
	var active: bool = decision.get("p", -1) == q
	sb.bg_color = Color(pl.hex).darkened(0.72) if shown else Color("#13202a")
	sb.border_color = Color(pl.hex) if active or shown else Color(pl.hex).darkened(0.5)
	sb.set_border_width_all(3 if active else 1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", sb)
	if state.phase == "action" and state.passed[q]:
		panel.modulate = Color(0.72, 0.72, 0.72)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var sc: int = Rules.score(state, q)["total"]
	var head := Label.new()
	head.text = "%s%s — %d pt" % [pl.name, " (IA)" if pl.ai else "", sc]
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", Color(pl.hex).lightened(0.35))
	head.clip_text = true
	vb.add_child(head)
	var a: Dictionary = pl.attrs
	var l2 := Label.new()
	l2.text = "Rep %d · Isp %d · Coo %d · Ing %d" % [int(a.rep), int(a.insp), int(a.coord), int(a.ing)]
	l2.add_theme_font_size_override("font_size", 12)
	vb.add_child(l2)
	var l3 := Label.new()
	var flag := " · di turno" if active else (" · ha passato" if state.phase == "action" and state.passed[q] else "")
	l3.text = "Ric %d · Dischi %d · Navi %d" % [int(pl.res), maxi(0, int(pl.staging)), pl.vessels.size()]
	l3.add_theme_font_size_override("font_size", 12)
	l3.modulate = Color(1, 1, 1, 0.8)
	l3.clip_text = true
	vb.add_child(l3)
	var l4 := Label.new()
	l4.text = "Specialisti %d · Diari %d%s" % [pl.specs.size(), pl.journals.size(), flag]
	l4.add_theme_font_size_override("font_size", 12)
	l4.modulate = Color(1, 1, 1, 0.8)
	l4.clip_text = true
	vb.add_child(l4)
	panel.tooltip_text = "Clic per vedere la plancia di %s" % pl.name
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_view_pick = -1 if q == decision.get("p", -1) else q
			_shown_player = q if _view_pick >= 0 else int(decision.get("p", _shown_player))
			_refresh_all())
	return panel


## Sceglie da sola la scheda dell'area grande quando cambia il tipo di decisione:
## Reclutamento in fase di reclutamento, Missione quando si piazza un Impatto, altrimenti l'Oceano.
## In mezzo si può guardare liberamente un'altra scheda.
func _auto_view(hex_targets: bool) -> void:
	var want := 0
	if decision.get("type", "") == "recruit":
		want = 1
	elif hex_targets or (decision.get("type", "") == "frame" and String(decision.get("frame", "")) in ["impact", "goal_choice", "star_choice"]):
		want = 2
	if want != _auto_tab:
		_auto_tab = want
		view_tabs.current_tab = want


# ───────────────────────── fine partita ─────────────────────────

const SCORE_COLS := ["attributi", "impatto", "diari", "specialisti", "avanzi", "obiettivo 1", "obiettivo 2", "obiettivo 3"]


func _show_final() -> void:
	prompt.text = "Partita finita."
	if _final_layer == null:
		_final_layer = _build_final()
		add_child(_final_layer)
	_final_layer.visible = true
	for c in chips.get_children():
		c.queue_free()
	_chip("Punteggi finali", func(): _final_layer.visible = true)
	if online == null:
		_chip("Rivincita", func(): rematch_requested.emit(), "Nuova partita con gli stessi giocatori e le stesse opzioni")
	_chip("Menu iniziale", func(): back_to_menu.emit())


func _build_final() -> Control:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0f1d27")
	sb.border_color = Color("#b08a4a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_size = 18
	sb.shadow_color = Color(0, 0, 0, 0.55)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var rows := []
	for q in state.n:
		rows.append({"p": q, "sc": Rules.score(state, q)})
	rows.sort_custom(func(a, b): return a.sc.total > b.sc.total)
	var title := Label.new()
	var best: int = rows[0].sc.total
	var winners: Array = rows.filter(func(r): return r.sc.total == best).map(func(r): return state.players[r.p].name)
	title.text = ("Vince %s con %d punti" if winners.size() == 1 else "Pareggio fra %s con %d punti") % [" e ".join(winners), best]
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Missione %d — %s" % [int(state.mission), GameData.mission(state.mission)["name"]]
	sub.modulate = Color(1, 1, 1, 0.7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 3 + SCORE_COLS.size()
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	var head: Array = ["", "Giocatore", "Totale"]
	for k in SCORE_COLS:
		head.append(String(k).capitalize())
	for h in head:
		var l := Label.new()
		l.text = h
		l.modulate = Color(1, 1, 1, 0.65)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l)
	var pos := 0
	var last := -99999
	for i in rows.size():
		var r: Dictionary = rows[i]
		if r.sc.total != last:
			pos = i + 1
			last = r.sc.total
		var pl: Dictionary = state.players[r.p]
		var lp := Label.new()
		lp.text = "%d°" % pos
		lp.add_theme_font_size_override("font_size", 22)
		grid.add_child(lp)
		var nb := HBoxContainer.new()
		var sw := ColorRect.new()
		sw.color = Color(pl.hex)
		sw.custom_minimum_size = Vector2(18, 18)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nb.add_child(sw)
		var ln := Label.new()
		ln.text = String(pl.name) + (" (IA)" if pl.get("ai", false) else "")
		ln.add_theme_font_size_override("font_size", 20)
		nb.add_child(ln)
		grid.add_child(nb)
		var lt := Label.new()
		lt.text = str(int(r.sc.total))
		lt.add_theme_font_size_override("font_size", 24)
		lt.add_theme_color_override("font_color", Color("#f3d27a"))
		lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(lt)
		for k in SCORE_COLS:
			var lv := Label.new()
			var v := int(r.sc.get(k, 0))
			lv.text = str(v) if v != 0 else "–"
			lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			grid.add_child(lv)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 14)
	box.add_child(btns)
	var specs: Array = [["Guarda il tabellone", func(): layer.visible = false],
		["Rivincita", func(): rematch_requested.emit()],
		["Menu iniziale", func(): back_to_menu.emit()]]
	if online != null:
		specs.remove_at(1)    # online la rivincita si fa creando una nuova stanza
	for spec in specs:
		var b := Button.new()
		b.text = spec[0]
		b.name = "btn_" + String(spec[0]).replace(" ", "_")
		b.custom_minimum_size = Vector2(190, 42)
		SetupScreen.gold(b)
		b.pressed.connect(spec[1])
		btns.add_child(b)
	return layer
