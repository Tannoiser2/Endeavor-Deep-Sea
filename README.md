# Endeavor: Deep Sea — versione digitale (Godot 4)

Endeavor: Deep Sea per 2–4 giocatori, in hotseat e/o contro IA (principiante, normale, esperta),
con tutte e 10 le missioni del gioco base in modalità competitiva. Dati e grafica arrivano dal mod
Tabletop Simulator "Endeavor: Deep Sea" (Workshop 2976002512); le regole dal "Draft rulebook" e
dal foglio "Ocean Board Special Rule Clarifications" del mod.

## Avvio
Apri la cartella con Godot 4.7 e premi Play. Al primo avvio Godot importa le immagini in `assets/`.

## Menu e fine partita
- Menu iniziale: copertina a sinistra, impostazioni a destra, tutto a pulsanti dorati: chi gioca
  (Umano / IA facile / normale / esperta) per ognuno dei quattro colori, la missione, il seme.
- A fine partita: classifica con il dettaglio dei punti e tre pulsanti, **Guarda il tabellone**
  (chiude la classifica; **Punteggi finali** la riapre), **Rivincita** e **Menu iniziale**.

## Come si gioca (tutto a clic)
- **Oceano** (a sinistra): le tessere originali nella griglia della missione (colonne A–E,
  profondità 1–5), dischi dei giocatori sui siti, Navi nel riquadro di Viaggio, pile di token
  Immersione; a destra le pile coperte delle tessere per profondità.
- **Plancia** (a destra, del giocatore di turno): la plancia originale con i cubetti su
  Reputazione, Ispirazione, Coordinazione, Ingegno e Ricerca, i dischi nell'area di preparazione,
  il token Immersione nello stemma, le Navi non ancora in mare e i punti attuali; sotto, la
  squadra: Specialisti col disco sul cerchio di attivazione e Giornali pubblicati.
- **Attivazione**: clic su uno Specialista = il disco va "in mano" sul suo cerchio e si illuminano
  i bersagli; clic sul bersaglio nell'oceano = l'azione parte (Viaggio: la zona di arrivo, e la
  Nave se ne hai più d'una che può andarci; Sonar/Immersione/Conservazione: il sito; Giornale: il
  sito e poi il Giornale in vetrina). Di nuovo clic sullo Specialista = il disco torna indietro.
  Gli Specialisti con più azioni proseguono con le azioni restanti (o **Salta**).
- **Token Immersione** e **azioni dei Giornali**: si usano allo stesso modo (clic, poi bersaglio);
  il token si converte in Ricerca cliccando poi la fascia della Ricerca.
- **Scoperta**: si pesca dalle pile illuminate, le due tessere compaiono in grande sopra l'oceano;
  clic sulla tessera scelta e poi sullo spazio libero tratteggiato.
- **Reclutamento**: clic sullo Specialista nella plancia in basso (livelli 1–5).
  **Riassegnazione**: clic sugli Specialisti da cui riprendere i dischi.
- **Impatto**: si apre la scheda Missione con gli esagoni possibili illuminati.
- **Scelte obbligate automatiche**: un'unica mossa possibile parte da sola; la Riassegnazione è
  automatica se la Coordinazione basta per tutti; la Ricerca mancante si paga da sola coi token.
- Tasto destro su tessere, carte e token per ingrandirli; rotellina e trascinamento col tasto
  destro per lo zoom dell'oceano; doppio clic per tornare alla vista intera.

## Regole implementate
Preparazione (Reclutamento, Impegno, Riassegnazione), Attivazione con Specialisti, token e
Giornali, le cinque azioni, Scoperta con i limiti di profondità e di colonna, collegamenti,
Promozioni, Navi a 2 e 7 di Ingegno, Impatto al 10 e oltre la fine del tracciato, tabellone
Impatto della missione, obiettivi con premi per 1° e 2° posto, punteggi degli Specialisti di
livello 5, avanzi (Ricerca + dischi) / 3. Tutte le regole speciali delle 37 zone, dal foglio
dei chiarimenti. Regole delle missioni (dal foglio "Scenario clarifications"):
- 3: zona di partenza a scelta, simboli di Campo sul tabellone Impatto;
- 4: esagono rosa da 3 punti (una volta per zona, Impatto da Conservazione);
- 5: 7 colonne, profondità massima 3, i due delfini (ognuno ne sceglie uno col primo segnalino);
- 6: segnalino Impatto che si sposta, esagoni a punti solo dopo la Stella caduta (+2 nella sua
  colonna), zone scoperte marcate, scelta Conservazione/Giornale per l'obiettivo 3;
- 7: griglia di soccorso solo con l'Impatto della Stella caduta, Navi successive in qualunque profondità 1;
- 8: colonne iniziali casuali, il Vetro d'osservazione nella pila della profondità 2 e sempre sotto la
  Stella Marina, esagoni Obiettivo con la scelta del criterio, +1 per il secondo gruppo più grande,
  infinito solo a griglia piena;
- 9: pulizia della marea nera (segnalino Impatto al posto del disco la prima volta in ogni zona),
  limiti di profondità 3/4, esagoni inquinati a -2 finché la pulizia non li ripulisce;
- 10: Impatto sulla riga della profondità, premi per i primi a scoprire e a raggiungere la profondità 5.

## Da dove vengono i dati
`tools/estrai_tts.py` ritaglia le immagini dalla cache del mod e scrive `data/*.json`:

```
python3 tools/estrai_tts.py "~/Desktop/Endeavor Deep Sea/Mods" .
```

Il mod non è scriptato: i contenuti delle tessere sono trascritti a mano in `tools/dati_zone.py`
(37 zone: siti, costi, ricompense, collegamenti, posizioni in pixel), `tools/dati_carte.py`
(21 Specialisti, 32 Giornali, 36 token Immersione) e `tools/dati_missioni.py` (missioni, esagoni
Impatto misurati sul foglio con un reticolo esagonale, obiettivi). Le descrizioni del mod cinese
"Full Script" sono servite per controllare bonus di Scoperta, token e Giornali.

## Struttura
```
data/                  JSON generati (zones, cards, missions, rules)
assets/                tessere Oceano, Specialisti, Giornali, token, fogli Missione, plance, dischi
scripts/core/rules.gd  motore delle regole puro (stato = Dictionary, pila di frame)
scripts/ai/            IA a simulazione con pesi in AIPlayer.W: valuta ogni mossa risolvendo anche le proprie
                       sotto-decisioni (Scoperta, Promozione...), le combinazioni Specialisti × occasioni vicine ×
                       Ricerca per i round futuri; l'esperta gioca le mosse migliori fino a fine round
scripts/ui/            menu, oceano, plancia, Specialisti/Giornali, foglio Missione
tests/                 sim.gd (IA contro IA), fuzz.gd (mosse casuali), rules_test.gd, ui_smoke.gd (partita a clic con screenshot)
tools/                 estrattore dal mod TTS e trascrizioni
```

## Test
```
godot --headless --path . -s res://tests/sim.gd -- 20 3       # 20 partite IA, 3 giocatori, missioni 1-10 a rotazione
godot --headless --path . -s res://tests/fuzz.gd -- 60 4      # mosse casuali
godot --headless --path . -s res://tests/rules_test.gd        # regole speciali, collegamenti, tracciati
godot --headless --path . -s res://tests/stats.gd -- 10 3 2   # Sonar, Scoperte, Diari, Conservazioni, dischi avanzati (pesi: engine=2 ...)
godot --path . -s res://tests/ui_stress.gd -- 1 10 4          # tutte le missioni a clic, 4 giocatori
godot --path . -s res://tests/ui_monkey.gd -- 1 10 3          # mouse vero a caso (movimento, clic, tasto destro, rotellina)
godot --headless --path . -s res://tests/tune.gd -- 36 act=2.2 # taratura dei pesi dell'IA
godot --path . -s res://tests/ui_smoke.gd -- /tmp 1           # partita a clic con screenshot
```
Controllano che i 30 dischi di ogni giocatore siano sempre al loro posto, che Ricerca e
attributi restino fra 0 e 12 e che le Navi tornino.

## Fogli missione in italiano
`tools/allinea_missioni.py` prende le scansioni di "Missioni Italiano.pdf", le raddrizza e le allinea
ai fogli del mod (SIFT + omografia), così le coordinate degli esagoni Impatto restano valide; le
pagine dei chiarimenti diventano la scheda **Regole** in partita. L'estrattore lo lancia da solo
se trova il PDF accanto alla cartella Mods.

## Attenzione: iCloud
Il Desktop è sincronizzato con iCloud: le copie in conflitto ("… 2.gd") e le cartelle duplicate
creano classi doppie (Rules, GameScreen…) che Godot può caricare male. Se ricompaiono file con
" 2" nel nome dentro il progetto, vanno cancellati (oppure spostate il progetto fuori da iCloud).

## Da fare / da verificare
- Modalità Co-op/Solo (carte Obiettivo bonus e Imprevisti).
- Espansione "Uncharted Waters" (nel mod cinese).
- Missione 6: la regola "segnalino nell'esagono a punti più profondo libero della colonna" è semplificata
  (un segnalino nuovo si può mettere quando tutti i tuoi sono bloccati o già su esagoni a punti).
