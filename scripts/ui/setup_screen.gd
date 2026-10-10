class_name SetupScreen
extends Control
## Menu iniziale: copertina a sinistra, impostazioni a destra, tutto a pulsanti dorati
## (niente menu a tendina né caselle di spunta): chi gioca e come, missione, seme.

signal start_requested(specs: Array, seed_value: int, opts: Dictionary)

const COLORS := ["purple", "yellow", "red", "white"]
const DEFAULT_NAMES := ["Viola", "Giallo", "Rosso", "Bianco"]

var _rows: Array = []
var _seed: LineEdit
var _mission: ButtonGroup
var _mission_info: Label
var _go: Button
var _warn: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists("res://assets/table.jpg"):
		bg.texture = load("res://assets/table.jpg")
	add_child(bg)
	var has_cover := ResourceLoader.exists("res://assets/copertina.jpg")
	if has_cover:
		var cover := TextureRect.new()
		cover.texture = load("res://assets/copertina.jpg")
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.anchor_left = 0.0
		cover.anchor_right = 0.5
		cover.anchor_top = 0.0
		cover.anchor_bottom = 1.0
		cover.offset_left = 40
		cover.offset_right = -20
		cover.offset_top = 40
		cover.offset_bottom = -40
		add_child(cover)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if has_cover:
		center.anchor_left = 0.5
		center.offset_left = 0
	add_child(center)
	var panel := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.09, 0.13, 0.92)
	psb.border_color = Color("#b08a4a")
	psb.set_border_width_all(1)
	psb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", psb)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Nuova partita" if has_cover else "Endeavor: Deep Sea"
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "dati e grafica dal mod Tabletop Simulator"
	sub.modulate = Color(1, 1, 1, 0.65)
	box.add_child(sub)

	box.add_child(_lbl("Giocatori (da 2 a 4): scegli chi gioca e come"))
	for i in 4:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var sw := ColorRect.new()
		sw.color = Color(GameData.players[COLORS[i]]["color"])
		sw.custom_minimum_size = Vector2(22, 22)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sw)
		var name := LineEdit.new()
		name.text = DEFAULT_NAMES[i]
		name.custom_minimum_size = Vector2(130, 0)
		row.add_child(name)
		var grp := _seg(row, ["—", "Umano", "IA facile", "IA normale", "IA esperta"], [-1, 0, 1, 2, 3],
			[0, 2, 3, -1][i], ["Non gioca", "Giocatore umano", "IA principiante", "IA normale", "IA esperta"])
		grp.pressed.connect(func(_b): _refresh_rows())
		box.add_child(row)
		_rows.append({"row": row, "name": name, "sw": sw, "group": grp})

	box.add_child(_lbl("Missione"))
	var o1 := GridContainer.new()
	o1.columns = 5
	o1.add_theme_constant_override("h_separation", 4)
	o1.add_theme_constant_override("v_separation", 4)
	var labels := []
	var vals := []
	var tips := []
	var mkeys: Array = GameData.missions.keys()
	mkeys.sort_custom(func(a, b): return int(a) < int(b))
	for k in mkeys:
		var m: Dictionary = GameData.missions[k]
		labels.append("Missione %s" % k)
		vals.append(int(k))
		tips.append("%s — %s" % [m["name"], m["name_en"]])
	_mission = _seg(o1, labels, vals, 1, tips)
	_mission.pressed.connect(func(_b): _refresh_mission())
	box.add_child(o1)
	_mission_info = Label.new()
	_mission_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_info.custom_minimum_size = Vector2(560, 0)
	_mission_info.modulate = Color(1, 1, 1, 0.75)
	box.add_child(_mission_info)

	var sh := HBoxContainer.new()
	sh.add_child(_lbl("Seme (vuoto = casuale):"))
	_seed = LineEdit.new()
	_seed.custom_minimum_size = Vector2(120, 0)
	sh.add_child(_seed)
	box.add_child(sh)

	_warn = _lbl("")
	_warn.add_theme_color_override("font_color", Color("#ff9a7a"))
	box.add_child(_warn)
	_go = Button.new()
	_go.text = "Immergiti!"
	_go.custom_minimum_size = Vector2(0, 46)
	_go.pressed.connect(_on_start)
	gold(_go)
	_go.add_theme_font_size_override("font_size", 22)
	box.add_child(_go)
	_refresh_rows()
	_refresh_mission()


## Pulsante d'azione dorato (usato anche a fine partita).
static func gold(b: Button) -> void:
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color("#b8862f")
	gs.border_color = Color("#f1d38a")
	gs.set_border_width_all(2)
	gs.set_corner_radius_all(8)
	gs.content_margin_left = 14
	gs.content_margin_right = 14
	var gh := gs.duplicate()
	gh.bg_color = Color("#d29c3c")
	var gd := gs.duplicate()
	gd.bg_color = Color("#3a3a3a")
	gd.border_color = Color("#555555")
	b.add_theme_stylebox_override("normal", gs)
	b.add_theme_stylebox_override("hover", gh)
	b.add_theme_stylebox_override("pressed", gh)
	b.add_theme_stylebox_override("disabled", gd)
	b.add_theme_color_override("font_color", Color("#1a1206"))
	b.add_theme_color_override("font_hover_color", Color("#1a1206"))
	b.add_theme_color_override("font_pressed_color", Color("#1a1206"))


func _lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


## Pulsanti a scelta singola (uno solo acceso). Restituisce il gruppo; il valore sta nel meta "v".
func _seg(parent: Container, labels: Array, values: Array, selected, tips: Array = []) -> ButtonGroup:
	var grp := ButtonGroup.new()
	if parent is BoxContainer:
		parent.add_theme_constant_override("separation", 4)
	for j in labels.size():
		var b := Button.new()
		b.text = labels[j]
		b.toggle_mode = true
		b.button_group = grp
		b.set_meta("v", values[j])
		b.focus_mode = Control.FOCUS_NONE
		if j < tips.size():
			b.tooltip_text = tips[j]
		_style(b)
		b.button_pressed = values[j] == selected
		parent.add_child(b)
	return grp


## Acceso = oro pieno, spento = scuro.
func _style(b: Button) -> void:
	var off := StyleBoxFlat.new()
	off.bg_color = Color("#1d2732")
	off.border_color = Color("#3b4a58")
	off.set_border_width_all(1)
	off.set_corner_radius_all(6)
	off.content_margin_left = 10
	off.content_margin_right = 10
	off.content_margin_top = 6
	off.content_margin_bottom = 6
	var hov := off.duplicate()
	hov.bg_color = Color("#2a3644")
	var on := off.duplicate()
	on.bg_color = Color("#c79a3e")
	on.border_color = Color("#f1d38a")
	b.add_theme_stylebox_override("normal", off)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_color_override("font_pressed_color", Color("#1a1206"))
	b.add_theme_color_override("font_hover_pressed_color", Color("#1a1206"))


func _val(grp: ButtonGroup):
	var b := grp.get_pressed_button()
	return b.get_meta("v") if b else null


func _active() -> Array:
	var out := []
	for i in _rows.size():
		if int(_val(_rows[i].group)) >= 0:
			out.append(i)
	return out


func _refresh_rows() -> void:
	for i in _rows.size():
		var on := int(_val(_rows[i].group)) >= 0
		_rows[i].name.editable = on
		_rows[i].name.modulate = Color(1, 1, 1, 1.0 if on else 0.4)
		_rows[i].sw.modulate = Color(1, 1, 1, 1.0 if on else 0.3)
	var n := _active().size()
	if _go:
		_go.disabled = n < 2
		_warn.text = "Servono almeno 2 giocatori." if n < 2 else ""


func _refresh_mission() -> void:
	var m: Dictionary = GameData.mission(int(_val(_mission)))
	var goals := []
	for g in m["goals"]:
		if g.has("options"):
			# obiettivo a scelta (Missione 8): si decide durante la partita
			var opts: Array = g["options"].map(func(o): return "%s: %s" % [o.get("label", ""), o.get("text", "")])
			goals.append("• a scelta — " + " / ".join(opts))
		else:
			goals.append("• " + String(g.get("text", "")))
	_mission_info.text = "%s (%s)\n%s%s" % [m["name"], m["name_en"], "\n".join(goals), ("\n⚠ " + String(m["rule"])) if m.has("rule") else ""]


func _on_start() -> void:
	var specs := []
	for i in _active():
		var t := int(_val(_rows[i].group))
		var nm: String = _rows[i].name.text.strip_edges()
		specs.append({"name": nm if nm != "" else DEFAULT_NAMES[i], "ai": t > 0, "ai_level": t, "color": COLORS[i]})
	var opts := {"mission": int(_val(_mission))}
	var sv := int(_seed.text) if _seed.text.is_valid_int() else -1
	start_requested.emit(specs, sv, opts)
