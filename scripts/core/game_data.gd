class_name GameData
extends RefCounted
## Carica e indicizza i dati di Endeavor: Deep Sea dai JSON in res://data/
## (generati da tools/estrai_tts.py a partire dal mod Tabletop Simulator).

const ATTRS := ["rep", "insp", "coord", "ing"]
const ATTR_NAMES := {"rep": "Reputazione", "insp": "Ispirazione", "coord": "Coordinazione", "ing": "Ingegno"}
const LEVEL_NAMES := {"rep": "Reclutamento", "insp": "Impegno", "coord": "Riassegnazione", "ing": "Tecnologia"}
const ACTION_NAMES := {"travel": "Viaggio", "sonar": "Sonar", "dive": "Immersione", "cons": "Conservazione",
	"journal": "Diario", "promote": "Promozione", "copy": "Copia", "discover35": "Scoperta (3-5)",
	"travel1": "Viaggio (Tecnologia +1)", "dive2": "Immersione (+1 segnalino)", "cons_depth": "Conservazione alla stessa profondità"}
const FIELD_NAMES := {"blue": "Tecnologia", "brown": "Comunicazione", "green": "Biologia", "yellow": "Sociale"}
const REWARD_NAMES := {"rep": "Reputazione", "insp": "Ispirazione", "coord": "Coordinazione", "ing": "Ingegno",
	"any": "attributo a scelta", "low": "attributo più basso", "res": "Ricerca", "impact": "Impatto",
	"disc": "gettone", "promote": "Promozione", "sonar": "Sonar", "sonar_here": "Sonar qui",
	"cons_here": "Conservazione qui", "trade": "scarta un gettone: +5 Ricerca", "travel": "Viaggio", "dive": "Immersione",
	"journal": "Diario", "cons1": "Conservazione (costo -1)"}
const COLORS := ["purple", "yellow", "red", "white"]
const COL_LETTERS := ["A", "B", "C", "D", "E", "F", "G"]

static var _loaded := false
static var rules: Dictionary = {}
static var mat: Dictionary = {}
static var players: Dictionary = {}
static var zones: Dictionary = {}
static var specs: Dictionary = {}        # id -> specialista
static var spec_order: Array = []
static var leaders: Dictionary = {}
static var leader: Dictionary = {}
static var journals: Dictionary = {}
static var journal_ids: Array = []
static var anchor_ids: Array = []
static var dive: Dictionary = {}
static var dive_ids: Array = []
static var missions: Dictionary = {}


static func ensure_loaded() -> void:
	if _loaded:
		return
	var r := _read("res://data/rules.json")
	rules = r["rules"]
	mat = r["mat"]
	players = r["players"]
	zones = _read("res://data/zones.json")
	for zid in zones:
		var z: Dictionary = zones[zid]
		# siti collegati: per ogni sito i collegamenti che lo toccano
		var site_links := {}
		for sid in z["sites"]:
			site_links[sid] = []
		for i in z["links"].size():
			var l: Dictionary = z["links"][i]
			site_links[l["a"]].append(i)
			site_links[l["b"]].append(i)
		z["site_links"] = site_links
		# tracciati sonar: track -> [sid in ordine]
		var tracks := {}
		var sids: Array = z["sites"].keys()
		sids.sort()
		for sid in sids:
			var s: Dictionary = z["sites"][sid]
			if s["t"] == "sonar":
				var k := str(int(s["track"]))
				if not tracks.has(k):
					tracks[k] = []
				tracks[k].append(sid)
		for k in tracks:
			tracks[k].sort_custom(func(a, b): return z["sites"][a]["pos"][0] < z["sites"][b]["pos"][0])
		z["tracks"] = tracks
	var c := _read("res://data/cards.json")
	for s in c["specialists"]:
		specs[s["id"]] = s
		spec_order.append(s["id"])
	leaders = c["leaders"]
	leader = c["leader"]
	for j in c["journals"]:
		journals[j["id"]] = j
		if j.get("anchor", false):
			anchor_ids.append(j["id"])
		else:
			journal_ids.append(j["id"])
	for t in c["dive"]:
		dive[t["id"]] = t
		for k in int(t["n"]):
			dive_ids.append(t["id"])
	missions = _read("res://data/missions.json")
	_loaded = true


static func level(v: int) -> int:
	return int(rules["level"][clampi(v, 0, 12)])


static func bracket(v: int) -> int:
	return int(rules["bracket"][clampi(v, 0, 12)])


static func mission(mid) -> Dictionary:
	return missions[str(mid)]


static func zone(zid: String) -> Dictionary:
	return zones[zid]


static func zone_name(zid: String) -> String:
	return String(zones[zid].get("name_it", zid)) if zones.has(zid) else zid


static func side(sid: String, senior: bool) -> Dictionary:
	if sid == "leader":
		return leader
	return specs[sid]["s" if senior else "j"]


static func rewards_text(lst: Array) -> String:
	var counts := {}
	var order := []
	for r in lst:
		if not counts.has(r):
			counts[r] = 0
			order.append(r)
		counts[r] += 1
	var parts := []
	for r in order:
		var name: String = REWARD_NAMES.get(r, String(r))
		if String(r).begins_with("discover:"):
			name = "Scoperta " + String(r).substr(9)
		parts.append(("%d %s" % [counts[r], name]) if counts[r] > 1 else name)
	return ", ".join(parts)


static func acts_text(acts: Dictionary) -> String:
	var lst: Array = acts.get("list", [])
	if lst.is_empty():
		return "nessuna azione"
	var names := lst.map(func(a): return ACTION_NAMES.get(a, a))
	return (" o " if acts.get("mode", "one") == "one" else " + ").join(names)


static func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Impossibile aprire " + path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON non valido: " + path)
		return {}
	return parsed
