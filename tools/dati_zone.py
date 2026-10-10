# -*- coding: utf-8 -*-
"""Trascrizione delle 37 tessere Oceano di Endeavor: Deep Sea.

Letta dalle immagini del mod (texture 1535x1063 per tessera) e verificata con le descrizioni
del mod cinese "Full Script" (bonus di Scoperta). Coordinate in pixel della tessera.

Ricompense (liste, si ripetono per quantità):
  rep   Reputazione (arancio)      insp  Ispirazione (verde)
  coord Coordinazione (giallo)     ing   Ingegno (blu)
  any   attributo a scelta         low   attributo più basso
  res   +1 Ricerca                 impact  1 Impatto
  disc  +1 disco nell'area         promote Promozione
  sonar Sonar (in qualunque zona)  sonar_here  Sonar in questa zona

Siti:
  sonar   {"track": n, "pos", "disc": "1-2" | "r": [...]}    (spazi in ordine da sinistra)
  cons    {"pos", "cost", "r": [...]}
  journal {"pos", "field": blue|brown|green|yellow}
  dive    {"pos"}   (quantità di token in "dive")
Collegamenti: {"a", "b", "r", "pos"} fra id di siti.
"""

FIELDS = ["blue", "brown", "green", "yellow"]

ZONES = {
    # ───────────────────────── PROFONDITÀ 1 ─────────────────────────
    "sea_star": {"name": "The Sea Star", "depth": 1, "mission": True,
        "discover": ["disc", "disc"], "dive": 4, "arrive": ["disc"],
        "sites": {
            "j1": {"t": "journal", "pos": [358, 343], "field": "yellow"},
            "j2": {"t": "journal", "pos": [1222, 435], "field": "brown"},
            "s1": {"t": "sonar", "track": 0, "pos": [326, 915], "disc": "1-2"},
            "s2": {"t": "sonar", "track": 0, "pos": [546, 915], "disc": "1-2"},
            "s3": {"t": "sonar", "track": 0, "pos": [762, 915], "disc": "1-2"},
            "d": {"t": "dive", "pos": [1255, 855]},
        }, "links": []},
    "dying_reef": {"name": "Dying Reef", "depth": 1,
        "discover": ["rep", "disc"], "arrive": ["impact"],
        "sites": {
            "c1": {"t": "cons", "pos": [245, 440], "cost": 1, "r": ["rep"]},
            "c2": {"t": "cons", "pos": [655, 508], "cost": 4, "r": ["rep", "impact"]},
            "c3": {"t": "cons", "pos": [245, 870], "cost": 1, "r": ["coord"]},
            "c4": {"t": "cons", "pos": [733, 905], "cost": 0, "r": ["rep"]},
            "c5": {"t": "cons", "pos": [1125, 870], "cost": 1, "r": ["impact"]},
            "j1": {"t": "journal", "pos": [1280, 452], "field": "green"},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["coord"], "pos": [445, 472]},
            {"a": "c1", "b": "c3", "r": ["disc"], "pos": [172, 645]},
            {"a": "c3", "b": "c2", "r": ["insp"], "pos": [525, 735]},
            {"a": "c2", "b": "c4", "r": ["disc"], "pos": [742, 700]},
            {"a": "c2", "b": "c5", "r": ["rep"], "pos": [942, 603]},
        ]},
    "volcanic_island": {"name": "Volcanic Island", "depth": 1,
        "discover": ["insp", "disc"], "dive": 2, "arrive": ["ing"],
        "sites": {
            "j1": {"t": "journal", "pos": [277, 560], "field": "green"},
            "j2": {"t": "journal", "pos": [728, 490], "field": "brown"},
            "s1": {"t": "sonar", "track": 0, "pos": [510, 867], "disc": "1-2"},
            "s2": {"t": "sonar", "track": 0, "pos": [727, 867], "disc": "1-2"},
            "d": {"t": "dive", "pos": [1102, 848]},
        }, "links": []},
    "kelp_forest": {"name": "Kelp Forest", "depth": 1,
        "discover": ["rep", "res"], "dive": 4, "arrive": ["insp"],
        "sites": {
            "c1": {"t": "cons", "pos": [258, 445], "cost": 2, "r": ["rep", "coord"]},
            "c2": {"t": "cons", "pos": [531, 738], "cost": 1, "r": ["coord"]},
            "d": {"t": "dive", "pos": [886, 743]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["coord"], "pos": [475, 521]},
        ]},
    "remote_anchorage": {"name": "Remote Anchorage", "depth": 1,
        "discover": ["ing", "disc"], "arrive": ["ing"],
        "sites": {
            "j1": {"t": "journal", "pos": [250, 735], "field": "blue"},
            "s1": {"t": "sonar", "track": 0, "pos": [668, 833], "disc": "1-2"},
            "s2": {"t": "sonar", "track": 0, "pos": [885, 833], "disc": "2-3"},
            "s3": {"t": "sonar", "track": 0, "pos": [1100, 833], "r": ["ing", "res"]},
            "s4": {"t": "sonar", "track": 0, "pos": [1318, 833], "disc": "3+"},
        }, "links": []},
    "oil_rig": {"name": "Decommissioned Oil Rig", "depth": 1,
        "discover": ["coord", "res"], "arrive": ["rep"],
        # Quando tutti i siti di Conservazione sono occupati: ogni giocatore promuove una
        # volta per ogni suo disco su quei siti (interpretazione dell'icona, da verificare).
        "special": "oil_rig", "warn_pos": [300, 405],
        "sites": {
            "c1": {"t": "cons", "pos": [198, 828], "cost": 1, "r": ["ing"]},
            "c2": {"t": "cons", "pos": [620, 925], "cost": 4, "r": ["rep", "impact"]},
            "c3": {"t": "cons", "pos": [1160, 930], "cost": 4, "r": ["coord", "impact"]},
            "c4": {"t": "cons", "pos": [1360, 632], "cost": 1, "r": ["ing"]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["rep"], "pos": [386, 930]},
            {"a": "c2", "b": "c3", "r": ["insp", "insp"], "pos": [893, 965]},
            {"a": "c3", "b": "c4", "r": ["coord"], "pos": [1368, 845]},
        ]},
    "calm_seas": {"name": "Calm Seas", "depth": 1,
        "discover": ["ing", "disc"], "arrive": ["res"],
        "sites": {
            "j1": {"t": "journal", "pos": [1248, 508], "field": "brown"},
            "s1": {"t": "sonar", "track": 0, "pos": [403, 730], "r": ["insp", "res"]},
            "s2": {"t": "sonar", "track": 0, "pos": [618, 730], "disc": "3+"},
            "t1": {"t": "sonar", "track": 1, "pos": [1028, 888], "disc": "1-2"},
            "t2": {"t": "sonar", "track": 1, "pos": [1245, 888], "disc": "1-2"},
        }, "links": []},
    "atoll": {"name": "Atoll", "depth": 1,
        "discover": ["insp", "disc"], "dive": 4, "arrive": ["coord"],
        "sites": {
            "d": {"t": "dive", "pos": [280, 775]},
            "s1": {"t": "sonar", "track": 0, "pos": [850, 812], "disc": "1-2"},
            "s2": {"t": "sonar", "track": 0, "pos": [1068, 812], "disc": "1-2"},
        }, "links": []},
}

ZONES.update({
    # ───────────────────────── PROFONDITÀ 2 ─────────────────────────
    "looking_glass": {"name": "The Looking Glass", "depth": 2, "mission": True,
        "discover": ["any", "disc", "res"], "arrive": ["insp"],
        "sites": {
            "j1": {"t": "journal", "pos": [728, 415], "field": "yellow"},
            "j2": {"t": "journal", "pos": [222, 763], "field": "blue"},
            "s1": {"t": "sonar", "track": 0, "pos": [735, 893], "disc": "1-3"},
            "s2": {"t": "sonar", "track": 0, "pos": [953, 893], "disc": "1-3"},
            "s3": {"t": "sonar", "track": 0, "pos": [1170, 893], "disc": "1-3"},
            "s4": {"t": "sonar", "track": 0, "pos": [1385, 893], "disc": "4"},
        }, "links": []},
    "dolphin_pods": {"name": "Dolphin Pods", "depth": 2,
        "discover": ["insp", "ing"], "dive": 3, "arrive": ["insp"],
        "sites": {
            "c1": {"t": "cons", "pos": [240, 410], "cost": 4, "r": ["coord", "impact"]},
            "c2": {"t": "cons", "pos": [665, 475], "cost": 2, "r": ["insp"]},
            "c3": {"t": "cons", "pos": [1140, 465], "cost": 3, "r": ["impact", "insp"]},
            "c4": {"t": "cons", "pos": [515, 915], "cost": 1, "r": ["insp"]},
            "d": {"t": "dive", "pos": [987, 848]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["impact"], "pos": [482, 490]},
            {"a": "c2", "b": "c3", "r": ["insp"], "pos": [900, 440]},
            {"a": "c1", "b": "c4", "r": ["rep"], "pos": [245, 830]},
            {"a": "c2", "b": "c4", "r": ["disc"], "pos": [620, 700]},
        ]},
})

ZONES.update({
    "sunken_ruins": {"name": "Sunken Ruins", "depth": 2,
        "discover": ["ing", "rep"], "dive": 4, "arrive": ["disc"],
        "special": "sunken_ruins", "warn_pos": [780, 645],
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [1078, 437], "disc": "2-3"},
            "s2": {"t": "sonar", "track": 0, "pos": [1295, 437], "disc": "2-3"},
            "d": {"t": "dive", "pos": [555, 665]},
        }, "links": []},
    "resupply_modules": {"name": "Resupply Modules", "depth": 2,
        "discover": ["coord", "ing"], "arrive": ["disc"],
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [345, 435], "disc": "1-3"},
            "s2": {"t": "sonar", "track": 0, "pos": [563, 435], "disc": "1-3"},
            "s3": {"t": "sonar", "track": 0, "pos": [780, 435], "r": ["ing", "ing"]},
            "t1": {"t": "sonar", "track": 1, "pos": [590, 758], "disc": "3"},
            "t2": {"t": "sonar", "track": 1, "pos": [805, 758], "disc": "3"},
            "t3": {"t": "sonar", "track": 1, "pos": [1020, 758], "disc": "3"},
        }, "links": [
            {"a": "s1", "b": "t1", "r": ["disc"], "pos": [460, 600]},
            {"a": "s2", "b": "t2", "r": ["rep"], "pos": [678, 600]},
            {"a": "s3", "b": "t3", "r": ["disc"], "pos": [893, 600]},
        ]},
    # Nessuna nave entra qui: le tre grotte si usano con una nave nella zona confinante
    # (up = profondità 1 sopra, left/right = zone di profondità 2 accanto).
    "cave_system": {"name": "Submerged Cave System", "depth": 2,
        "discover": ["coord", "ing"], "dive": 4, "no_vessels": True, "special": "cave_system",
        "warn_pos": [598, 762],
        "sites": {
            "d_up": {"t": "dive", "pos": [1175, 205], "cave": "up", "n": 2},
            "j_up": {"t": "journal", "pos": [775, 255], "field": "blue", "cave": "up"},
            "d_left": {"t": "dive", "pos": [203, 503], "cave": "left", "n": 1},
            "c_left": {"t": "cons", "pos": [360, 870], "cost": 2, "r": ["ing"], "cave": "left"},
            "j_right": {"t": "journal", "pos": [1015, 580], "field": "green", "cave": "right"},
            "d_right": {"t": "dive", "pos": [1330, 812], "cave": "right", "n": 1},
        }, "links": [
            {"a": "c_left", "b": "j_up", "r": ["rep"], "pos": [528, 477]},
            {"a": "j_up", "b": "j_right", "r": ["ing"], "pos": [855, 430]},
            {"a": "c_left", "b": "j_right", "r": ["insp"], "pos": [690, 615]},
        ]},
    "shipwreck": {"name": "Shipwreck", "depth": 2,
        "discover": ["insp", "ing"], "dive": 8, "arrive": ["rep"],
        "special": "shipwreck",
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [285, 440], "r": ["coord", "res"]},
            "s2": {"t": "sonar", "track": 0, "pos": [503, 437], "disc": "3"},
            "d": {"t": "dive", "pos": [975, 808]},
        }, "links": []},
    "whale_calving": {"name": "Whale Calving Grounds", "depth": 2,
        "discover": ["rep", "coord"], "arrive": ["res"],
        "special": "whale_calving",
        "sites": {
            "c1": {"t": "cons", "pos": [180, 390], "cost": 1, "r": ["impact"]},
            "c2": {"t": "cons", "pos": [445, 615], "cost": 2, "r": ["rep", "rep"]},
            "c3": {"t": "cons", "pos": [780, 480], "cost": 4, "r": ["rep", "impact"]},
            "c4": {"t": "cons", "pos": [1375, 500], "cost": 2, "r": ["rep", "coord"]},
            "c5": {"t": "cons", "pos": [855, 900], "cost": 0, "r": ["rep"]},
            "c6": {"t": "cons", "pos": [1230, 925], "cost": 2, "r": ["coord", "insp"]},
            "j1": {"t": "journal", "pos": [190, 880], "field": "green", "marked": True},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["rep"], "pos": [265, 530]},
            {"a": "c3", "b": "c5", "r": ["impact"], "pos": [770, 650]},
            {"a": "c4", "b": "c6", "r": ["insp"], "pos": [1265, 680]},
        ]},
})

ZONES.update({
    "ledge_elevator": {"name": "Ledge Elevator", "depth": 2,
        "discover": ["rep", "coord"], "dive": 3, "arrive": ["ing"],
        "sites": {
            "j1": {"t": "journal", "pos": [345, 375], "field": "yellow"},
            "s1": {"t": "sonar", "track": 0, "pos": [262, 755], "r": ["ing", "res"]},
            "s2": {"t": "sonar", "track": 0, "pos": [478, 755], "disc": "3"},
            "s3": {"t": "sonar", "track": 0, "pos": [695, 755], "disc": "3"},
            "d": {"t": "dive", "pos": [1330, 820]},
        }, "links": [
            {"a": "s2", "b": "s3", "r": ["ing"], "pos": [590, 925]},
        ]},
    "turtle_migration": {"name": "Sea Turtle Migration", "depth": 2,
        "discover": ["rep", "insp"], "arrive": ["coord"],
        "special": "turtle_migration", "warn_pos": [808, 955],
        "sites": {
            "c1": {"t": "cons", "pos": [275, 520], "cost": 2, "r": ["discover:1-3"]},
            "c2": {"t": "cons", "pos": [790, 690], "cost": 4, "r": ["coord", "impact"]},
            "c3": {"t": "cons", "pos": [1318, 805], "cost": 2, "r": ["discover:1-3"]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["impact"], "pos": [530, 505]},
            {"a": "c2", "b": "c3", "r": ["impact"], "pos": [1030, 820]},
        ]},
})

ZONES.update({
    # ───────────────────────── PROFONDITÀ 3 ─────────────────────────
    "jellyfish_bloom": {"name": "Jellyfish Bloom", "depth": 3,
        "discover": ["coord", "coord"], "arrive": ["disc"],
        "special": "jellyfish_bloom", "warn_pos": [1060, 430],
        "sites": {
            "c1": {"t": "cons", "pos": [735, 450], "cost": 5, "r": ["insp", "insp", "coord"], "marked": True},
            "c2": {"t": "cons", "pos": [455, 835], "cost": 5, "r": ["rep", "rep", "coord"], "marked": True},
            "j1": {"t": "journal", "pos": [970, 850], "field": "yellow", "marked": True},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["insp"], "pos": [508, 615]},
            {"a": "c1", "b": "j1", "r": ["rep"], "pos": [918, 612]},
            {"a": "c2", "b": "j1", "r": ["coord"], "pos": [708, 925]},
        ]},
    "vortex": {"name": "Vortex", "depth": 3,
        "discover": ["ing", "ing"], "arrive": ["rep"],
        "special": "vortex", "warn_pos": [665, 340],
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [298, 372], "disc": "3", "skip_depth": True},
            "t1": {"t": "sonar", "track": 1, "pos": [470, 815], "r": ["coord", "res"]},
            "t2": {"t": "sonar", "track": 1, "pos": [690, 815], "disc": "1-4"},
            "u1": {"t": "sonar", "track": 2, "pos": [1068, 900], "r": ["insp", "res"]},
            "u2": {"t": "sonar", "track": 2, "pos": [1288, 900], "disc": "4"},
        }, "links": []},
})

ZONES.update({
    "thermal_vents": {"name": "Thermal Vents", "depth": 3,
        "discover": ["ing", "ing"], "dive": 4, "arrive": ["ing"],
        "special": "thermal_vents",
        "sites": {
            "j1": {"t": "journal", "pos": [285, 768], "field": "green", "marked": True},
            "j2": {"t": "journal", "pos": [1010, 793], "field": "blue", "marked": True},
            "d": {"t": "dive", "pos": [655, 725]},
        }, "links": []},
    "deepwater_shark": {"name": "Deepwater Shark", "depth": 3,
        "discover": ["insp", "ing"], "dive": 5, "arrive": ["coord"],
        "special": "deepwater_shark",
        "sites": {
            "d": {"t": "dive", "pos": [930, 785]},
        }, "links": []},
})

ZONES.update({
    "rift_valley": {"name": "Rift Valley", "depth": 3,
        "discover": ["coord", "ing"], "arrive": ["coord"],
        "sites": {
            "j1": {"t": "journal", "pos": [898, 455], "field": "blue"},
            "s1": {"t": "sonar", "track": 0, "pos": [298, 760], "disc": "2-3"},
            "s2": {"t": "sonar", "track": 0, "pos": [512, 760], "r": ["rep", "res"]},
            "s3": {"t": "sonar", "track": 0, "pos": [730, 760], "disc": "3"},
            "s4": {"t": "sonar", "track": 0, "pos": [945, 760], "r": ["ing", "res"]},
            "s5": {"t": "sonar", "track": 0, "pos": [1163, 760], "disc": "3"},
        }, "links": [
            {"a": "s2", "b": "s4", "r": ["res"], "pos": [715, 960]},
            {"a": "j1", "b": "s5", "r": ["rep"], "pos": [1122, 555]},
        ]},
    "carbonate_spires": {"name": "Carbonate Spires", "depth": 3, "mission": True,
        "discover": ["rep", "rep"], "arrive": ["res"],
        "sites": {
            "j1": {"t": "journal", "pos": [418, 525], "field": "blue"},
            "j2": {"t": "journal", "pos": [843, 410], "field": "brown"},
            "j3": {"t": "journal", "pos": [1252, 445], "field": "green"},
            "j4": {"t": "journal", "pos": [1230, 910], "field": "yellow"},
            "s1": {"t": "sonar", "track": 0, "pos": [600, 905], "disc": "3"},
            "s2": {"t": "sonar", "track": 0, "pos": [815, 905], "disc": "3"},
        }, "links": [
            {"a": "j1", "b": "j2", "r": ["rep"], "pos": [548, 370]},
            {"a": "j2", "b": "j3", "r": ["rep"], "pos": [1093, 345]},
            {"a": "j3", "b": "j4", "r": ["rep"], "pos": [1352, 740]},
            {"a": "j1", "b": "s1", "r": ["res"], "pos": [545, 650]},
            {"a": "s2", "b": "j4", "r": ["res"], "pos": [1040, 940]},
        ]},
    "coldwater_reef": {"name": "Coldwater Reef", "depth": 3,
        "discover": ["insp", "insp"], "arrive": ["rep"],
        "sites": {
            "c1": {"t": "cons", "pos": [185, 540], "cost": 1, "r": ["rep"]},
            "c2": {"t": "cons", "pos": [328, 910], "cost": 2, "r": ["coord"]},
            "c3": {"t": "cons", "pos": [805, 930], "cost": 2, "r": ["insp"]},
            "c4": {"t": "cons", "pos": [1305, 885], "cost": 1, "r": ["rep"]},
            "j1": {"t": "journal", "pos": [710, 435], "field": "yellow"},
            "j2": {"t": "journal", "pos": [1035, 435], "field": "green"},
        }, "links": [
            {"a": "c1", "b": "j1", "r": ["impact"], "pos": [450, 360]},
            {"a": "c1", "b": "c2", "r": ["rep"], "pos": [175, 725]},
            {"a": "c2", "b": "c3", "r": ["rep"], "pos": [565, 940]},
            {"a": "j1", "b": "c3", "r": ["impact"], "pos": [605, 640]},
            {"a": "j2", "b": "c3", "r": ["insp"], "pos": [875, 685]},
            {"a": "j2", "b": "c4", "r": ["coord"], "pos": [1245, 630]},
            {"a": "c3", "b": "c4", "r": ["coord"], "pos": [1063, 955]},
        ]},
})

ZONES.update({
    # ───────────────────────── PROFONDITÀ 4 ─────────────────────────
    "bioluminescent": {"name": "Bioluminescent Fauna", "depth": 4,
        "discover": ["insp", "insp", "impact"], "dive": 6, "arrive": ["ing"],
        "special": "bioluminescent",
        "sites": {
            "d1": {"t": "dive", "pos": [340, 655], "n": 3, "bonus": ["res"]},
            "d2": {"t": "dive", "pos": [1078, 628], "n": 3, "bonus": ["disc"]},
        }, "links": []},
    "continental_shelf": {"name": "Continental Shelf", "depth": 4,
        "discover": ["insp", "ing", "disc"], "dive": 4, "arrive": ["coord"],
        "sites": {
            "j1": {"t": "journal", "pos": [195, 752], "field": "brown"},
            "j2": {"t": "journal", "pos": [720, 820], "field": "blue"},
            "d": {"t": "dive", "pos": [1237, 845]},
        }, "links": [
            {"a": "j1", "b": "j2", "r": ["impact"], "pos": [440, 915]},
        ]},
    "colossal_squid": {"name": "Colossal Squid", "depth": 4,
        "discover": ["rep", "rep", "res"], "dive": 3, "arrive": ["coord"],
        "sites": {
            "j1": {"t": "journal", "pos": [283, 400], "field": "yellow"},
            "c1": {"t": "cons", "pos": [995, 462], "cost": 0, "r": []},
            "c2": {"t": "cons", "pos": [1360, 850], "cost": 0, "r": []},
            "d": {"t": "dive", "pos": [382, 825]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["impact", "impact"], "pos": [1230, 595]},
        ]},
})

ZONES.update({
    "brine_pool": {"name": "Brine Pool", "depth": 4,
        "discover": ["insp", "ing", "res"], "dive": 4, "arrive": ["insp"],
        "special": "dive_impact",
        "sites": {"d": {"t": "dive", "pos": [767, 610]}}, "links": []},
    "sponge_gardens": {"name": "Sponge Gardens", "depth": 4,
        "discover": ["rep", "ing", "res"], "arrive": ["res", "res"],
        "sites": {
            "j1": {"t": "journal", "pos": [250, 485], "field": "brown"},
            "j2": {"t": "journal", "pos": [650, 582], "field": "green"},
            "j3": {"t": "journal", "pos": [1280, 457], "field": "blue"},
        }, "links": [
            {"a": "j1", "b": "j2", "r": ["impact"], "pos": [425, 622]},
            {"a": "j2", "b": "j3", "r": ["disc", "res"], "pos": [960, 380]},
        ]},
    "seamount": {"name": "Seamount", "depth": 4,
        "discover": ["ing", "disc", "res"], "dive": 4, "arrive": ["disc"],
        "special": "seamount",
        "sites": {
            "c1": {"t": "cons", "pos": [215, 530], "cost": 1, "r": ["coord"], "marked": True},
            "c2": {"t": "cons", "pos": [595, 480], "cost": 3, "r": ["coord", "coord"], "marked": True},
            "c3": {"t": "cons", "pos": [555, 880], "cost": 1, "r": ["coord"], "marked": True},
            "d": {"t": "dive", "pos": [1200, 582]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["impact"], "pos": [418, 603]},
            {"a": "c2", "b": "c3", "r": ["impact"], "pos": [620, 673]},
        ]},
})

ZONES.update({
    # ───────────────────────── PROFONDITÀ 5 ─────────────────────────
    "whale_fall": {"name": "Whale Fall", "depth": 5,
        "discover": ["insp", "coord", "coord"], "arrive": ["insp"],
        "sites": {
            "c1": {"t": "cons", "pos": [178, 595], "cost": 2, "r": ["coord", "impact"]},
            "c2": {"t": "cons", "pos": [745, 575], "cost": 4, "r": ["impact", "impact"]},
            "c3": {"t": "cons", "pos": [1385, 490], "cost": 2, "r": ["insp", "impact"]},
            "j1": {"t": "journal", "pos": [440, 415], "field": "yellow"},
            "j2": {"t": "journal", "pos": [1138, 690], "field": "brown"},
        }, "links": [
            {"a": "c1", "b": "j1", "r": ["coord"], "pos": [245, 385]},
            {"a": "j1", "b": "c2", "r": ["impact"], "pos": [540, 605]},
            {"a": "c2", "b": "j2", "r": ["impact"], "pos": [960, 625]},
            {"a": "j2", "b": "c3", "r": ["insp"], "pos": [1373, 673]},
        ]},
    "abyssal_plain": {"name": "Abyssal Plain", "depth": 5,
        "discover": ["insp", "ing", "disc"], "arrive": ["any"],
        "special": "abyssal_plain",
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [300, 848], "disc": "5", "skip_depth": True},
            "s2": {"t": "sonar", "track": 0, "pos": [517, 848], "disc": "5", "skip_depth": True},
        }, "links": []},
    "scaly_snails": {"name": "Scaly-Foot Snails", "depth": 5,
        "discover": ["coord", "ing", "ing"], "dive": 3, "arrive": ["disc"],
        "special": "scaly_snails",
        "sites": {
            "j1": {"t": "journal", "pos": [295, 512], "field": "blue"},
            "j2": {"t": "journal", "pos": [1003, 733], "field": "yellow"},
            "j3": {"t": "journal", "pos": [1230, 548], "field": "brown"},
            "d": {"t": "dive", "pos": [658, 778]},
        }, "links": []},
})

ZONES.update({
    "fallen_star": {"name": "Fallen Star", "depth": 5, "mission": True,
        "discover": ["rep", "ing", "impact"], "dive": 4, "arrive": ["res", "res"],
        "special": "dive_impact",
        "sites": {
            "c1": {"t": "cons", "pos": [155, 400], "cost": 6, "r": ["rep", "impact", "impact"]},
            "c2": {"t": "cons", "pos": [190, 815], "cost": 6, "r": ["coord", "impact", "impact"]},
            "j1": {"t": "journal", "pos": [420, 480], "field": "green", "bonus": ["impact"]},
            "s1": {"t": "sonar", "track": 0, "pos": [1160, 408], "r": ["insp", "impact"]},
            "s2": {"t": "sonar", "track": 0, "pos": [1378, 408], "r": ["insp", "impact"]},
            "j2": {"t": "journal", "pos": [1350, 733], "field": "brown", "bonus": ["impact"]},
            "d": {"t": "dive", "pos": [840, 612]},
        }, "links": [
            {"a": "c1", "b": "j1", "r": ["rep"], "pos": [345, 312]},
            {"a": "c1", "b": "c2", "r": ["insp"], "pos": [105, 590]},
            {"a": "c2", "b": "j1", "r": ["coord"], "pos": [285, 605]},
            {"a": "s2", "b": "j2", "r": ["disc"], "pos": [1385, 565]},
        ]},
    "abyssal_trench": {"name": "Abyssal Trench", "depth": 5,
        "discover": ["insp", "coord", "ing"], "arrive": ["sonar_here"],
        "special": "abyssal_trench", "warn_pos": [1250, 85],
        "sites": {
            "s1": {"t": "sonar", "track": 0, "pos": [298, 442], "r": ["insp", "res"]},
            "s2": {"t": "sonar", "track": 0, "pos": [515, 442], "r": ["rep", "res"]},
            "s3": {"t": "sonar", "track": 0, "pos": [730, 442], "r": ["insp", "impact"]},
            "s4": {"t": "sonar", "track": 0, "pos": [947, 442], "r": ["rep", "impact"]},
            "s5": {"t": "sonar", "track": 0, "pos": [1165, 442], "r": ["impact", "impact"]},
            "s6": {"t": "sonar", "track": 0, "pos": [1382, 442], "r": ["impact", "impact", "impact"]},
        }, "links": []},
    "black_smoker": {"name": "Black Smoker", "depth": 5,
        "discover": ["rep", "ing", "ing"], "dive": 4, "arrive": ["disc", "res"],
        "special": "black_smoker",
        "sites": {
            "j1": {"t": "journal", "pos": [1073, 435], "field": "brown"},
            "j2": {"t": "journal", "pos": [1287, 770], "field": "blue"},
            "d": {"t": "dive", "pos": [310, 585]},
        }, "links": []},
    "seafloor_restoration": {"name": "Seafloor Restoration", "depth": 5,
        "discover": ["rep", "coord", "res"], "arrive": ["cons_here"],
        "sites": {
            "c1": {"t": "cons", "pos": [205, 600], "cost": 1, "r": ["coord"]},
            "c2": {"t": "cons", "pos": [735, 535], "cost": 5, "r": ["promote"]},
            "c3": {"t": "cons", "pos": [1290, 590], "cost": 1, "r": ["rep"]},
            "c4": {"t": "cons", "pos": [345, 915], "cost": 1, "r": ["rep"]},
            "c5": {"t": "cons", "pos": [785, 915], "cost": 2, "r": ["impact"]},
            "c6": {"t": "cons", "pos": [1215, 915], "cost": 1, "r": ["coord"]},
        }, "links": [
            {"a": "c1", "b": "c2", "r": ["impact"], "pos": [490, 535]},
            {"a": "c2", "b": "c3", "r": ["impact"], "pos": [1020, 515]},
            {"a": "c1", "b": "c4", "r": ["impact"], "pos": [165, 775]},
            {"a": "c4", "b": "c5", "r": ["impact"], "pos": [570, 950]},
            {"a": "c5", "b": "c6", "r": ["impact"], "pos": [1003, 890]},
            {"a": "c3", "b": "c6", "r": ["impact"], "pos": [1375, 765]},
        ]},
})
