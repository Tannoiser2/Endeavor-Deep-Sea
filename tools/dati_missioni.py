# -*- coding: utf-8 -*-
"""Missioni (fogli Scenario) di Endeavor: Deep Sea, trascritte dalle immagini del mod.

Tabellone Impatto: reticolo esagonale misurato sul foglio a piena risoluzione (3189x2126).
Ogni esagono è (i, j, contenuto, punti): il centro è  O + i*v1 + j*v2,  con v2 = v1 ruotato di "ang".
Contenuto: lettere di ricompensa  R Reputazione, I Ispirazione, C Coordinazione, N Ingegno,
S +1 Ricerca, D +1 disco, A attributo a scelta, L attributo più basso, P Promozione,
"F:<campo>" simbolo di campo (missione 3), "INF" esagono infinito; "" = vuoto.
Le posizioni delle zone iniziali vengono dal mod cinese "Full Script" (griglia 7 colonne):
qui sono colonna (0 = A) e profondità (1..5).
"""

MISSIONS = {
    1: {
        "name": "Il richiamo dell'oceano", "name_en": "The Call of the Ocean",
        "columns": 5, "max_depth": 5,
        "setup": [["volcanic_island", 1, 1], ["sea_star", 2, 1], ["random", 3, 1], ["looking_glass", 2, 2]],
        "launch": "sea_star",
        "lattice": {"O": [289, 777], "v1": [210, 0], "ang": 60},
        "hexes": [
            [0, 0, "R", 0], [1, 0, "R", 0], [2, 0, "S", 1], [3, 0, "S", 1], [4, 0, "S", 1], [5, 0, "D", 1], [6, 0, "", 2],
            [0, 1, "R", 0], [1, 1, "I", 0], [6, 1, "", 2],
            [-1, 2, "I", 0], [0, 2, "I", 0], [5, 2, "S", 1], [6, 2, "", 2],
            [2, 3, "INF", 2], [3, 3, "S", 1], [4, 3, "D", 1], [5, 3, "D", 1],
            [-2, 4, "C", 0], [-1, 4, "C", 0], [4, 4, "S", 1], [5, 4, "", 2],
            [-2, 5, "N", 0], [-1, 5, "C", 0], [4, 5, "", 2],
            [-3, 6, "N", 0], [-2, 6, "N", 0], [-1, 6, "D", 1], [0, 6, "S", 1], [1, 6, "S", 1], [2, 6, "S", 1], [3, 6, "", 2],
        ],
        "entries": [[0, 0], [-1, 2], [-2, 4], [-3, 6]],
        "goals": [
            {"kind": "discs", "site": "sonar", "lead": [5, 3], "text": "1 per gettone Sonar nell'oceano"},
            {"kind": "discs", "site": "journal", "lead": [3, 1], "text": "1 per gettone Diario nell'oceano"},
            {"kind": "discs", "site": "cons", "lead": [7, 4], "text": "1 per gettone Conservazione nell'oceano"},
        ],
    },
    2: {
        "name": "Mappe e carte nautiche", "name_en": "Maps and Charts",
        "columns": 5, "max_depth": 5,
        "setup": [["sea_star", 0, 1], ["calm_seas", 1, 1], ["remote_anchorage", 2, 1], ["looking_glass", 0, 2]],
        "launch": "sea_star",
        "lattice": {"O": [289, 887], "v1": [0, 210], "ang": -60},
        "hexes": [
            [-1, 1, "I", 0], [0, 0, "SS", 0], [0, 1, "SS", 0], [1, 0, "C", 0], [2, 0, "C", 0], [3, 0, "S", 1], [4, 0, "", 2],
            [3, 1, "D", 1],
            [-1, 2, "", 2], [0, 2, "I", 0], [1, 2, "R", 0], [2, 2, "S", 1], [3, 2, "", 2],
            [-2, 3, "", 2], [1, 3, "I", 0],
            [-2, 4, "", 2], [-1, 4, "N", 0], [0, 4, "R", 0], [1, 4, "S", 1], [2, 4, "", 2],
            [-3, 5, "", 2], [1, 5, "D", 1],
            [-3, 6, "C", 0], [-2, 6, "N", 0], [-1, 6, "C", 0], [0, 6, "S", 1], [1, 6, "", 2],
            [-4, 7, "", 2], [-2, 7, "I", 0],
            [-4, 8, "", 2], [-3, 8, "", 2], [-2, 8, "D", 1], [-1, 8, "D", 1], [0, 8, "INF", 2],
        ],
        "entries": [[-1, 1], [0, 0], [1, 0]],
        "goals": [
            {"kind": "discs", "site": "sonar", "cols": [1, 2], "lead": [4, 2], "text": "1 per gettone Sonar nelle colonne B e C"},
            {"kind": "discs_vessels", "cols": [3, 4], "lead": [7, 4], "text": "1 per gettone/Nave nelle colonne D ed E"},
            {"kind": "zones_with_disc", "depths": [2, 3, 4], "lead": [2, 1], "text": "1 per zona a profondità 2/3/4 con almeno un tuo gettone"},
        ],
    },
    3: {
        "name": "Il diario dell'oceano", "name_en": "The Oceanic Journal",
        "columns": 5, "max_depth": 5,
        "setup": [["sea_star", 2, 1], ["random", 3, 1], ["looking_glass", 2, 2], ["carbonate_spires", 2, 3]],
        "launch": "any_depth1",
        "lattice": {"O": [299, 808], "v1": [210, 0], "ang": 60},
        "start_hex": [3, 3],
        "hexes": [
            [0, 0, "F:yellow", 1], [1, 0, "F:green", 1], [2, 0, "", 2], [3, 0, "", 2], [6, 0, "", 2], [7, 0, "P", 0],
            [0, 1, "F:green", 1], [1, 1, "F:brown", 1], [3, 1, "N", 0], [4, 1, "R", 0], [5, 1, "", 2], [6, 1, "", 2],
            [-1, 2, "F:blue", 1], [0, 2, "F:yellow", 1], [2, 2, "R", 0], [3, 2, "N", 0], [5, 2, "R", 0],
            [-1, 3, "F:brown", 1], [0, 3, "", 2], [1, 3, "", 2], [4, 3, "R", 0], [5, 3, "C", 0],
            [-2, 4, "F:blue", 1], [1, 4, "I", 0], [2, 4, "R", 0], [4, 4, "C", 0],
            [1, 5, "I", 0], [2, 5, "R", 0], [3, 5, "", 2], [4, 5, "S", 1], [5, 5, "R", 0],
            [-2, 6, "INF", 2], [-1, 6, "D", 1], [0, 6, "S", 1], [1, 6, "D", 1], [2, 6, "S", 1], [3, 6, "D", 1], [4, 6, "R", 0], [5, 6, "P", 0],
        ],
        "entries": [[3, 2], [4, 3], [2, 4]],
        "rule": "Quando ottieni una Nave puoi scegliere qualsiasi zona di profondità 1 come zona di partenza. "
                "I simboli di Campo sul tabellone Impatto non danno ricompense immediate ma contano come tuoi.",
        "goals": [
            {"kind": "discs", "site": "sonar", "depths": [1, 2], "lead": [6, 3], "text": "1 per gettone Sonar a profondità 1/2"},
            {"kind": "journal_vessels", "depths": [3, 4, 5], "lead": [4, 2], "text": "1 per gettone Diario/Nave a profondità 3/4/5"},
            {"kind": "fields", "most": 2, "text": "1 per simbolo di Campo del tuo tipo più numeroso; 2 a chi ne ha di più per ogni tipo"},
        ],
    },
    4: {
        "name": "Meglio di come l'avete trovato", "name_en": "Better Than You Found It",
        "columns": 5, "max_depth": 5,
        "setup": [["random", 1, 1], ["sea_star", 2, 1], ["dying_reef", 3, 1], ["looking_glass", 2, 2]],
        "launch": "sea_star",
        "lattice": {"O": [857, 1057], "v1": [206, 30], "ang": 60},
        "hexes": [
            [-1, -2, "I", 2], [2, -2, "", 2], [3, -2, "", 2],
            [-2, -1, "", 2], [-1, -1, "", 2], [0, -1, "C", 1], [1, -1, "C", 1], [2, -1, "D", 1], [3, -1, "", 2],
            [-2, 0, "", 2], [-1, 0, "SS", 1], [0, 0, "R", 0], [1, 0, "R", 0], [2, 0, "D", 1],
            [-3, 1, "A", 0], [-2, 1, "A", 0], [-1, 1, "N", 0], [0, 1, "N", 0], [1, 1, "N", 0], [2, 1, "A", 0], [3, 1, "", 1], [4, 1, "INF", 2],
            [-3, 2, "", 2], [-2, 2, "SS", 1], [-1, 2, "R", 0], [0, 2, "R", 0], [1, 2, "D", 1],
            [-4, 3, "", 2], [-3, 3, "", 2], [-2, 3, "C", 1], [-1, 3, "C", 1], [0, 3, "D", 1], [1, 3, "", 2],
            [-4, 4, "I", 2], [-1, 4, "", 2], [0, 4, "", 2],
        ],
        "entries": [[-3, 1]],
        # Esagono rosa (3 punti, infinito): una volta per zona, l'Impatto ottenuto direttamente
        # da una Conservazione in quella zona può andare qui.
        "special_hex": {"px": [2030, 1760], "pts": 3, "kind": "cons_zone"},
        "rule": "Una volta per zona, un Impatto ottenuto da una Conservazione lì può andare nell'esagono rosa.",
        "goals": [
            {"kind": "discs", "site": "cons", "depths": [1, 2, 3], "lead": [6, 3], "text": "1 per gettone Conservazione a profondità 1/2/3"},
            {"kind": "discs_vessels", "cols": [0, 4], "lead": [7, 4], "text": "1 per gettone/Nave nelle colonne A ed E"},
            {"kind": "discs", "depths": [4, 5], "lead": [4, 2], "text": "1 per gettone a profondità 4/5"},
        ],
    },
}


# ───────────────────────── missioni 5-10 ─────────────────────────
# Esagoni con campi extra: {"g": gruppo (delfino, griglia di soccorso), "col": colonna (Spill),
# "goal": n (Esagono obiettivo), "row": profondità (Deepest Sea), "score_col": lettera (Star Search)}.
# "px": posizione esplicita in pixel per gli esagoni fuori reticolo (infiniti).
# "from": esagoni da cui si entra a senso unico.

MISSIONS[5] = {
    "name": "Stella cadente", "name_en": "Fallen Star",
    "columns": 7, "max_depth": 3, "remove_depths": [4, 5],
    "setup": [["atoll", 0, 1], ["calm_seas", 1, 1], ["random", 2, 1], ["random", 3, 1], ["ledge_elevator", 0, 2]],
    "launch": "any_depth1",
    "lattice": {"O": [793, 647], "v1": [210, 0], "ang": 120},
    "one_group": True,
    "hexes": [
        # delfino in alto (a)
        [0, 0, "P", 0, {"g": "a"}],
        [0, 1, "I", 0, {"g": "a"}], [1, 1, "R", 0, {"g": "a"}], [2, 1, "C", 0, {"g": "a"}], [3, 1, "CD", 0, {"g": "a"}],
        [0, 2, "ID", 0, {"g": "a"}], [1, 2, "SS", 1, {"g": "a"}], [2, 2, "SS", 1, {"g": "a"}], [3, 2, "SS", 1, {"g": "a"}], [4, 2, "AD", 1, {"g": "a"}],
        [0, 3, "A", 0, {"g": "a"}], [1, 3, "RD", 0, {"g": "a"}], [3, 3, "AA", 0, {"g": "a"}],
        [-1, 4, "RD", 0, {"g": "a"}], [0, 4, "A", 0, {"g": "a"}],
        [0, 5, "CD", 0, {"g": "a"}],
        [99, 99, "INF", 1, {"g": "a", "px": [1856, 1160], "from": [[4, 2]]}],
        # delfino in basso (b)
        [5, 4, "", 2, {"g": "b"}], [8, 4, "", 2, {"g": "b"}],
        [3, 5, "", 2, {"g": "b"}], [4, 5, "", 2, {"g": "b"}], [5, 5, "", 2, {"g": "b"}], [6, 5, "", 2, {"g": "b"}],
        [8, 5, "", 2, {"g": "b"}], [9, 5, "", 2, {"g": "b"}],
        [4, 6, "D", 1, {"g": "b"}], [5, 6, "D", 1, {"g": "b"}], [6, 6, "D", 1, {"g": "b"}], [7, 6, "", 2, {"g": "b"}], [8, 6, "", 2, {"g": "b"}],
        [6, 7, "", 2, {"g": "b"}],
        [98, 98, "INF", 2, {"g": "b", "px": [564, 1760], "from": [[3, 5]]}],
    ],
    "entries": [[-1, 4], [0, 5], [8, 4], [9, 5]],
    "rule": "Il tabellone Impatto è diviso in due delfini: ogni giocatore mette i suoi segnalini su uno solo (lo sceglie col primo).",
    "goals": [
        {"kind": "sonar_vessels", "cols": [0, 1], "lead": [2, 1], "text": "1 per gettone Sonar/Nave nelle colonne A e B"},
        {"kind": "journal_vessels", "cols": [4, 5, 6], "lead": [2, 1], "text": "1 per gettone Diario/Nave nelle colonne E, F e G"},
        {"kind": "discs", "site": "cons", "depths": [2, 3], "lead": [4, 2], "text": "1 per gettone Conservazione a profondità 2/3"},
    ],
}

MISSIONS[6] = {
    "name": "Ricerca de «La Stella Marina»", "name_en": "Star Search",
    "columns": 5, "max_depth": 5,
    "setup": [["atoll", 0, 1], ["remote_anchorage", 2, 1], ["calm_seas", 4, 1],
              ["ledge_elevator", 0, 2], ["resupply_modules", 2, 2], ["shipwreck", 4, 2]],
    "fallen_star": "depth5", "mark_discovered": True,
    "launch": "any_depth1",
    "lattice": {"O": [184, 1110], "v1": [0, 214], "ang": -120},
    "moving": True,
    "hexes": [
        [0, 0, "D", 0], [1, 2, "D", 0], [2, 4, "D", 0], [3, 6, "D", 0], [4, 8, "D", 0],
        [0, 1, "R", 0], [1, 3, "I", 0], [2, 5, "C", 0], [3, 7, "N", 0],
        [1, 1, "C", 0], [2, 3, "N", 0], [3, 5, "R", 0], [4, 7, "I", 0],
        [2, 1, "S", 0], [3, 3, "S", 0], [4, 5, "S", 0], [5, 7, "S", 0],
        [3, 1, "S", 0], [4, 3, "S", 0], [5, 5, "S", 0], [6, 7, "S", 0],
        [4, 1, "L", 0], [5, 3, "L", 0], [6, 5, "L", 0], [7, 7, "L", 0],
        [2, 0, "", 2, {"score_col": 0}], [3, 0, "", 4, {"score_col": 0}], [4, 0, "", 6, {"score_col": 0}],
        [3, 2, "", 2, {"score_col": 1}], [4, 2, "", 4, {"score_col": 1}], [5, 2, "", 6, {"score_col": 1}],
        [4, 4, "", 2, {"score_col": 2}], [5, 4, "", 4, {"score_col": 2}], [6, 4, "", 6, {"score_col": 2}],
        [5, 6, "", 2, {"score_col": 3}], [6, 6, "", 4, {"score_col": 3}], [7, 6, "", 6, {"score_col": 3}],
        [6, 8, "", 2, {"score_col": 4}], [7, 8, "", 4, {"score_col": 4}], [8, 8, "", 6, {"score_col": 4}],
    ],
    "entries": [[0, 0], [1, 2], [2, 4], [3, 6], [4, 8]],
    "rule": "Un solo segnalino Impatto che si sposta: ogni Impatto lo muove in un esagono vicino libero (e ne dai la ricompensa); "
            "negli esagoni a punti solo dopo la scoperta della Stella Cadente (+2 nella sua colonna). Ogni zona che scopri "
            "vale per l'obiettivo 2; chi scopre la Stella Cadente sceglie il tipo di sito dell'obiettivo 3.",
    "goals": [
        {"kind": "zones_with_disc", "depths": [2, 3, 4], "lead": [4, 2], "text": "1 per zona a profondità 2/3/4 con un tuo gettone"},
        {"kind": "discovered", "most": [["depth", 3], ["depth", 4], ["depth", 5], ["col", 1], ["col", 3]], "bonus": 2,
         "text": "1 per zona scoperta da te; 2 a chi ne ha scoperte di più a profondità 3, 4, 5 e nelle colonne B e D"},
        {"kind": "star_sites", "text": "1 per gettone nel tipo di sito scelto da chi scopre la Stella Cadente (3 punti a lui)"},
    ],
}

MISSIONS[7] = {
    "name": "Recuperare la Stella cadente", "name_en": "Recover the Fallen Star",
    "columns": 5, "max_depth": 5,
    "setup": [["remote_anchorage", 2, 1], ["resupply_modules", 2, 2], ["random", 2, 3], ["random", 2, 4], ["fallen_star", 2, 5]],
    "launch": "remote_anchorage", "launch_later": "any_depth1",
    "lattice": {"O": [640, 600], "v1": [212, 0], "ang": 120},
    "hexes": [
        [0, 0, "N", 0], [1, 0, "N", 0],
        [0, 1, "N", 0], [1, 1, "CD", 0], [2, 1, "N", 0], [3, 1, "CD", 0], [4, 1, "R", 0],
        [0, 2, "R", 0], [1, 2, "R", 0], [3, 2, "N", 0], [4, 2, "N", 0], [5, 2, "N", 0],
        [2, 3, "IS", 0], [3, 3, "R", 0], [4, 3, "IS", 0], [5, 3, "R", 0], [6, 3, "N", 0],
        [0, 3, "S", 1], [1, 4, "S", 1], [1, 5, "INF", 2],
        [3, 5, "L", 1, {"g": "rescue"}], [4, 5, "L", 1, {"g": "rescue"}], [3, 6, "L", 1, {"g": "rescue"}],
        [5, 6, "L", 1, {"g": "rescue"}], [2, 7, "S", 2, {"g": "rescue"}], [3, 7, "L", 1, {"g": "rescue"}],
        [4, 7, "L", 1, {"g": "rescue"}], [6, 6, "", 3, {"g": "rescue"}], [7, 6, "", 3, {"g": "rescue"}],
        [7, 5, "", 3, {"g": "rescue"}], [6, 7, "S", 2, {"g": "rescue"}], [7, 7, "S", 2, {"g": "rescue"}],
    ],
    "entries": [[6, 3], [7, 5]],
    "rescue": True,
    "rule": "Nella griglia di salvataggio vanno solo gli Impatti presi direttamente dalla Stella Cadente (che puoi anche mettere nella griglia principale).",
    "goals": [
        {"kind": "zones_disc_vessel", "cols": [2], "mult": 2, "lead": [2, 1], "text": "2 per zona della colonna C con un tuo gettone o una Nave"},
        {"kind": "cons_journal", "cols": [0, 1, 3, 4], "lead": [6, 3], "text": "1 per gettone Conservazione/Diario nelle colonne A, B, D ed E"},
        {"kind": "rescue", "lead": [4, 2], "text": "4 a chi ha più segnalini nella griglia di salvataggio, 2 al secondo"},
    ],
}

MISSIONS[8] = {
    "name": "Nuovi orizzonti", "name_en": "New Horizons",
    "columns": 5, "max_depth": 5,
    "setup": [["sea_star", -1, 1], ["random", -1, 1], ["random", -1, 1], ["random", -1, 1], ["random", -1, 1]],
    "glass_in_stack": True,
    "launch": "sea_star",
    "lattice": {"O": [270, 630], "v1": [210, 0], "ang": 60},
    "clusters": True,
    "hexes": [
        [0, 0, "", 1, {"goal": 3}], [1, 0, "", 1], [2, 0, "", 1], [3, 0, "F:brown", 1], [4, 0, "", 1], [5, 0, "F:blue", 1], [6, 0, "S", 1], [7, 0, "F:brown", 1],
        [0, 1, "", 1], [1, 1, "F:green", 1], [2, 1, "D", 1], [5, 1, "", 1], [6, 1, "D", 1], [7, 1, "S", 1],
        [-1, 2, "F:brown", 1], [1, 2, "", 1], [2, 2, "", 1], [3, 2, "", 1], [5, 2, "F:yellow", 1], [6, 2, "", 1],
        [-2, 3, "S", 1], [-1, 3, "", 1], [0, 3, "D", 1], [1, 3, "", 1], [2, 3, "I", 1], [3, 3, "C", 1], [4, 3, "", 1], [5, 3, "", 1], [6, 3, "F:green", 1],
        [-2, 4, "F:yellow", 1], [0, 4, "", 1], [1, 4, "I", 1], [3, 4, "C", 1], [4, 4, "", 1], [5, 4, "F:blue", 1],
        [-2, 5, "F:green", 1], [-1, 5, "", 1], [0, 5, "", 1], [1, 5, "R", 1], [2, 5, "R", 1], [3, 5, "", 1], [4, 5, "D", 1], [5, 5, "", 1],
        [-2, 6, "", 1], [-1, 6, "D", 1], [0, 6, "", 1], [1, 6, "", 1], [4, 6, "", 1],
        [-4, 7, "", 1, {"goal": 1}], [-3, 7, "", 1], [-2, 7, "", 1], [-1, 7, "F:yellow", 1], [0, 7, "", 1], [1, 7, "F:blue", 1], [2, 7, "", 1], [3, 7, "", 1, {"goal": 2}],
        [97, 97, "INF", 1, {"px": [2110, 1704], "full": True}],
    ],
    "entries": [[2, 3], [3, 3], [1, 4], [3, 4], [1, 5], [2, 5]],
    "rule": "Esagoni Obiettivo: chi ci mette un segnalino sceglie come si conta quell'obiettivo per tutti (senza segnalino non si conta). "
            "Ogni segnalino del tuo secondo agglomerato più grande vale +1. Il Osservatorio, se scoperto, va sotto la Stella Marina. "
            "L'infinito solo a griglia piena.",
    "goals": [
        {"kind": "choice", "hex_goal": 1, "options": [
            {"kind": "zones_side", "side": "left", "lead": [2, 1], "label": "Vicino",
             "text": "1 per zona nella colonna della Stella Marina e a sinistra con un tuo gettone"},
            {"kind": "zones_side", "side": "right", "lead": [2, 1], "label": "Lontano",
             "text": "1 per zona nella colonna della Stella Marina e a destra con un tuo gettone"}]},
        {"kind": "choice", "hex_goal": 2, "options": [
            {"kind": "discs", "depths": [2, 3], "lead": [2, 1], "label": "Poco profondo", "text": "1 per gettone a profondità 2/3"},
            {"kind": "discs", "depths": [4, 5], "lead": [2, 1], "label": "Profondo", "text": "1 per gettone a profondità 4/5"}]},
        {"kind": "choice", "hex_goal": 3, "options": [
            {"kind": "fields", "lead": [2, 1], "label": "Ristretto", "text": "1 per simbolo di Campo del tuo tipo più numeroso"},
            {"kind": "field_sets", "lead": [2, 1], "label": "Ampio", "text": "3 per serie dei quattro simboli di Campo"}]},
    ],
}

MISSIONS[9] = {
    "name": "La fuoriuscita", "name_en": "The Spill",
    "columns": 6, "max_depth": 4, "remove_depths": [5],
    "setup": [["oil_rig", 2, 1], ["sea_star", 3, 1], ["whale_calving", 2, 2], ["looking_glass", 3, 2]],
    "launch": "sea_star",
    "lattice": {"O": [366, 1154], "v1": [0, 210], "ang": -120},
    "cleanup": {"depth_ok": {"3": 2, "4": 5}, "clean_at": [2, 2, 2, 4, 4, 6, 6, 8, 8], "max": 8,
                "px": [[370 + 181.25 * k, 784] for k in range(9)]},
    "hexes": [
        [0, 0, "A", -2, {"col": 0}],
        [1, 1, "A", -2, {"col": 1}], [2, 1, "RI", -2, {"col": 1}], [3, 1, "N", 1, {"col": 1}], [4, 1, "R", 1, {"col": 1}],
        [1, 2, "A", -2, {"col": 2}], [2, 2, "A", -2, {"col": 2}],
        [2, 3, "A", -2, {"col": 3}], [3, 3, "RC", -2, {"col": 3}], [4, 3, "I", 1, {"col": 3}], [5, 3, "R", 1, {"col": 3}],
        [2, 4, "LL", -2, {"col": 4}],
        [3, 5, "RR", -2, {"col": 5}], [4, 5, "NN", -2, {"col": 5}], [5, 5, "C", 1, {"col": 5}], [6, 5, "R", 1, {"col": 5}],
        [3, 6, "LL", -2, {"col": 6}], [4, 6, "A", -2, {"col": 6}],
        [4, 7, "II", -2, {"col": 7}], [5, 7, "CC", -2, {"col": 7}], [6, 7, "N", 1, {"col": 7}], [7, 7, "N", 1, {"col": 7}],
        [4, 8, "AA", -2, {"col": 8}], [5, 8, "IC", -2, {"col": 8}],
        [96, 96, "INF", 2, {"px": [200, 1573], "from": [[0, 0]], "cons_direct": True}],
    ],
    "entries": [[4, 8]],
    "rule": "La prima volta che Conservi in una zona usi un segnalino Impatto al posto del gettone e avanzi sul tracciato della "
            "Bonifica. Profondità 3 e 4 si scoprono solo dopo i passi «OK». Gli esagoni inquinati valgono -2 finché la tua "
            "Bonifica non raggiunge la spunta della loro colonna. Un Impatto preso direttamente da una Conservazione può andare nell'infinito.",
    "goals": [
        {"kind": "cleanup", "lead": [2, 1], "text": "Punti pari al tuo avanzamento sul tracciato Bonifica"},
        {"kind": "discs_vessels", "depths": [1], "lead": [5, 3], "text": "1 per gettone/Nave a profondità 1"},
        {"kind": "discs", "site": "cons", "depths": [2, 3, 4], "lead": [4, 2], "text": "1 per gettone Conservazione a profondità 2, 3 e 4"},
    ],
}

MISSIONS[10] = {
    "name": "Acque profonde", "name_en": "The Deepest Sea",
    "columns": 5, "max_depth": 5,
    "setup": [["random", 1, 1], ["sea_star", 2, 1], ["random", 3, 1], ["looking_glass", 2, 2]],
    "launch": "sea_star",
    "depth_rows": True,
    "hex_px": True,
    "hexes": [
        [474, 740, "S", 0, {"row": 1}], [686, 740, "S", 0, {"row": 1}], [900, 740, "N", 0, {"row": 1}],
        [1110, 740, "N", 0, {"row": 1}], [1320, 740, "N", 0, {"row": 1}], [1534, 740, "A", 0, {"row": 1}],
        [474, 1040, "A", 0, {"row": 2}], [686, 1040, "I", 0, {"row": 2}], [900, 1040, "C", 0, {"row": 2}],
        [1110, 1040, "D", 1, {"row": 2}], [1320, 1040, "D", 1, {"row": 2}],
        [474, 1340, "A", 0, {"row": 3}], [686, 1340, "R", 0, {"row": 3}], [900, 1340, "S", 1, {"row": 3}],
        [1110, 1340, "S", 1, {"row": 3}], [1320, 1340, "S", 1, {"row": 3}], [1534, 1340, "S", 1, {"row": 3}],
        [474, 1640, "", 3, {"row": 4}], [686, 1640, "", 2, {"row": 4}], [900, 1640, "S", 1, {"row": 4}],
        [1110, 1640, "S", 1, {"row": 4}], [1320, 1640, "S", 1, {"row": 4}],
        [474, 1920, "", 3, {"row": 5}], [686, 1920, "", 3, {"row": 5}], [900, 1920, "", 3, {"row": 5}],
        [1110, 1920, "", 2, {"row": 5}], [1320, 1920, "", 2, {"row": 5}], [1534, 1920, "", 2, {"row": 5}],
        [1736, 940, "INF", 1, {"rows": [1, 2, 3], "from_px": [[1534, 740], [1320, 1040], [1534, 1340]]}],
        [1880, 1860, "INF", 2, {"rows": [4, 5], "from_px": [[1320, 1640], [1534, 1920]]}],
    ],
    "entries_px": [[474, 740], [474, 1040], [474, 1340], [474, 1640], [474, 1920]],
    "rule": "Ogni Impatto va sulla riga della profondità della zona dove l'hai ottenuto (se non viene da una zona, a una "
            "profondità dove hai una Nave).",
    "goals": [
        {"kind": "first", "event": "discover5", "lead": [4, 2], "text": "4 al primo che scopre una zona di profondità 5, 2 al secondo"},
        {"kind": "first", "event": "travel5", "lead": [4, 3], "text": "4 al primo che viaggia in una zona di profondità 5, 3 al secondo"},
        {"kind": "discs", "site": "journal", "depths": [4, 5], "lead": [7, 4], "text": "1 per gettone Diario a profondità 4/5"},
    ],
}
