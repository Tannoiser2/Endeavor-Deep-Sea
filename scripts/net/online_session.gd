class_name OnlineSession
extends Node
## Partita online in lockstep (stesso schema di Kingsburg). Tutti i dispositivi fanno girare lo stesso
## motore (Rules) con lo stesso seme: ogni decisione con più di una mossa possibile diventa una mossa
## numerata nel database (acts/0, acts/1, …) che contiene solo l'indice della mossa scelta nella lista
## di Rules.current_decision, più un controllo per accorgersi se due dispositivi non sono allineati.
## Le decisioni con una sola mossa possibile le applicano tutti da soli, senza passare dalla rete.
## - la decisione del proprio colore la prende chi è davanti al dispositivo;
## - i colori IA li gioca il dispositivo di chi ha creato la stanza;
## - le altre si aspettano dal database. Se un giocatore tace per un minuto, al suo posto gioca l'IA
##   (sul dispositivo di chi ha creato la stanza) finché non rientra.

signal status_changed(text: String)

var net: Net
var code := ""
var seat := -1
var role := "guest"
var n := 0                     # prossima mossa del registro da applicare
var backlog: Array = []        # mosse già giocate (rientro in una partita in corso)
var away := {}                 # posti di giocatori assenti, giocati dall'IA di chi ha creato la stanza
var alive := true
var names: Array = []


func setup(p_net: Net, p_code: String, p_seat: int, p_role: String, p_backlog: Array) -> void:
	net = p_net
	code = p_code
	seat = p_seat
	role = p_role
	backlog = p_backlog


func _exit_tree() -> void:
	alive = false


func is_host() -> bool:
	return role == "host"


func catching_up() -> bool:
	return n < backlog.size()


## Controllo della mossa: uguale su tutti i dispositivi se la partita è allineata.
static func check(m: Dictionary) -> String:
	return "%08x" % (var_to_str(m).hash() & 0xffffffff)


## La mossa n del registro già scaricata (rientro), oppure {}.
func from_backlog() -> Dictionary:
	if n < backlog.size():
		var a = backlog[n]
		return a if a is Dictionary else {}
	return {}


## Pubblica la mossa di posto s (indice nella lista delle mosse). Restituisce la mossa che vale davvero:
## la propria, oppure quella che un altro dispositivo aveva già scritto con lo stesso numero.
func publish(s: int, idx: int, chk: String) -> Dictionary:
	var a := {"s": s, "k": "m", "i": idx, "c": chk}
	while alive:
		if await net.post_act(code, n, a):
			return a
		var ex := await net.get_act(code, n)
		if not ex.is_empty() and not ex.has("_err"):
			return ex
		status_changed.emit("Rete non raggiungibile, riprovo… (%s)" % net.last_error)
		await get_tree().create_timer(2.0).timeout
	return a


## Controlla una volta se è arrivata la mossa n: {} se non c'è ancora, {"_err": true} se la rete non risponde.
func poll() -> Dictionary:
	return await net.get_act(code, n)


## Chi ha creato la stanza: il giocatore del posto s è ancora collegato? Se tace da troppo lo segna assente.
var _seen := {}
func check_presence(s: int, waited_ms: int) -> bool:
	var st := await net.seat(code, s)
	if st.is_empty():
		return true
	var now := Time.get_ticks_msec()
	var seen = st.get("seen", null)
	if not _seen.has(s) or _seen[s][0] != seen:
		_seen[s] = [seen, now]
	if st.get("away", false) or (now - int(_seen[s][1]) > 45000 and waited_ms > 60000):
		await net.set_away(code, s, true)
		away[s] = true
		return false
	return true


## Un giocatore segnato assente è tornato?
func back_again(s: int) -> bool:
	var st := await net.seat(code, s)
	if not st.is_empty() and not st.get("away", false):
		away.erase(s)
		return true
	return false


## Segnale di presenza ogni 5 secondi.
func heartbeat_loop() -> void:
	while alive:
		net.heartbeat(code, seat)
		await get_tree().create_timer(5.0).timeout


func finish() -> void:
	if is_host():
		net.set_status(code, "over")
	net.remember_room("")
