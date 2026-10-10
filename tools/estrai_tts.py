"""Estrae dati e immagini di Endeavor: Deep Sea dal mod Tabletop Simulator (Workshop 2976002512).

Uso:
    python3 tools/estrai_tts.py "<cartella Mods del mod>" [cartella progetto]

Il mod non è scriptato: le regole vengono dal "Draft rulebook" e dal foglio delle regole speciali
delle zone, i dati delle tessere sono trascritti in tools/dati_*.py dalle immagini del mod.
Questo script:
  - ritaglia dalla cache del mod tessere Oceano, Specialisti, Giornali, token Immersione,
    fogli Missione, plance dei giocatori, dischi, Navi, segnalini Impatto, segnalino Onda;
  - calcola i centri degli esagoni Impatto dal reticolo misurato sui fogli;
  - scrive data/*.json (coordinate normalizzate 0..1 sulle immagini).
"""
import json
import math
import os
import re
import shutil
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dati_carte as DC  # noqa: E402
import dati_missioni as DM  # noqa: E402
import dati_zone as DZ  # noqa: E402

MODS = os.path.expanduser(sys.argv[1]) if len(sys.argv) > 1 else os.path.expanduser("~/Desktop/Endeavor Deep Sea/Mods")
PROJ = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IMAGES = os.path.join(MODS, "Images")
DATA = os.path.join(PROJ, "data")
ASSETS = os.path.join(PROJ, "assets")
EXTRA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "immagini_extra")

_files = {}
for f in os.listdir(IMAGES):
    m = re.search(r"([0-9A-F]{40})\.", f)
    if m:
        _files[m.group(1)[:8]] = os.path.join(IMAGES, f)

missing = []


def src(h):
    p = _files.get(h)
    if p is None:
        missing.append(h)
    return p


def mk(*parts):
    p = os.path.join(ASSETS, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def save_img(im, path, width=None, quality=90):
    if width and im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    if path.endswith(".png"):
        im.save(path, optimize=True)
    else:
        im.convert("RGB").save(path, quality=quality)


def grid_cut(h, cols, rows, idx):
    im = Image.open(src(h))
    w, hh = im.width / cols, im.height / rows
    c, r = idx % cols, idx // cols
    return im.crop((round(c * w), round(r * hh), round((c + 1) * w), round((r + 1) * hh)))


# ───────────────────────── tessere Oceano ─────────────────────────
ZONE_SHEETS = [
    ("11B253B1", 4, 2, ["sea_star", "dying_reef", "volcanic_island", "kelp_forest", "remote_anchorage", "oil_rig", "calm_seas", "atoll"]),
    ("073292D2", 5, 2, ["looking_glass", "dolphin_pods", "sunken_ruins", "resupply_modules", "cave_system", "shipwreck",
                        "whale_calving", "ledge_elevator", "turtle_migration"]),
    ("5E707F75", 4, 2, ["jellyfish_bloom", "vortex", "thermal_vents", "deepwater_shark", "rift_valley", "carbonate_spires", "coldwater_reef"]),
    ("491EA2A8", 3, 2, ["bioluminescent", "continental_shelf", "colossal_squid", "brine_pool", "sponge_gardens", "seamount"]),
    ("ECFDB0C5", 4, 2, ["whale_fall", "abyssal_plain", "scaly_snails", "fallen_star", "abyssal_trench", "black_smoker", "seafloor_restoration"]),
]
ZW, ZH = 1535.0, 1063.0
NAMES_IT = {'sea_star': 'La Stella Marina', 'dying_reef': 'Barriera Corallina Morente', 'volcanic_island': 'Isola Vulcanica', 'kelp_forest': 'Foresta di Kelp', 'remote_anchorage': 'Ancoraggio Remoto', 'oil_rig': 'Piattaforma Petrolifera Dismessa', 'calm_seas': 'Acque Tranquille', 'atoll': 'Atollo', 'looking_glass': "L'Osservatorio", 'dolphin_pods': 'Branchi di Delfini', 'sunken_ruins': 'Rovine Sommerse', 'resupply_modules': 'Moduli di Rifornimento', 'cave_system': 'Sistema di Grotte Sottomarine', 'shipwreck': 'Relitto', 'whale_calving': 'Zone di Parto delle Balene', 'ledge_elevator': 'Ascensore Subacqueo', 'turtle_migration': 'Migrazione delle Tartarughe Marine', 'jellyfish_bloom': 'Proliferazione di Meduse', 'vortex': 'Vortice', 'thermal_vents': 'Camini Termici', 'deepwater_shark': 'Squalo di Acque Profonde', 'rift_valley': 'Valle del Rift', 'carbonate_spires': 'Guglie di Carbonato', 'coldwater_reef': 'Barriera di Acque Fredde', 'bioluminescent': 'Fauna Bioluminescente', 'continental_shelf': 'Piattaforma Continentale', 'colossal_squid': 'Calamaro Colossale', 'brine_pool': 'Piscina Salata', 'sponge_gardens': 'Giardini di Spugne', 'seamount': 'Montagna Sottomarina', 'whale_fall': 'Carcassa di Balena', 'abyssal_plain': 'Piana Abissale', 'scaly_snails': 'Lumache di Metallo', 'fallen_star': 'Stella Cadente', 'abyssal_trench': 'Fossa Abissale', 'black_smoker': 'Bocche Idrotermali', 'seafloor_restoration': 'Ripristino del Fondale'}


def norm(p):
    return [round(p[0] / ZW, 4), round(p[1] / ZH, 4)]


ZONE_BACKS = {1: "4C1BAB15", 2: "F04153D3", 3: "AFE6FF5A", 4: "5B0872E6", 5: "3007E682"}


def build_zones():
    out = {}
    for d, h in ZONE_BACKS.items():
        save_img(Image.open(src(h)), mk("zones", "back_%d.jpg" % d), 600, 85)
    for h, c, r, names in ZONE_SHEETS:
        for i, zid in enumerate(names):
            save_img(grid_cut(h, c, r, i), mk("zones", zid + ".jpg"), 1200, 88)
    for zid, z in DZ.ZONES.items():
        d = json.loads(json.dumps(z))
        d["id"] = zid
        d["name_it"] = NAMES_IT[zid]
        d["image"] = "res://assets/zones/%s.jpg" % zid
        for sid, s in d["sites"].items():
            s["pos"] = norm(s["pos"])
        for l in d["links"]:
            l["pos"] = norm(l["pos"])
        if "warn_pos" in d:
            d["warn_pos"] = norm(d["warn_pos"])
        # posizione dei token Immersione e numero (siti multipli: "n" nel sito)
        out[zid] = d
    return out


# ───────────────────────── Specialisti, Giornali, token ─────────────────────────
def build_cards():
    specs = []
    for s in DC.SPECIALISTS:
        d = json.loads(json.dumps(s))
        for side, h in zip(("j", "s"), s["img"]):
            p = mk("specialists", "%s_%s.jpg" % (s["id"], side))
            save_img(Image.open(src(h)), p, 531, 90)
            d[side]["image"] = "res://assets/specialists/%s_%s.jpg" % (s["id"], side)
        del d["img"]
        specs.append(d)
    leaders = {}
    for col, h in DC.TEAM_LEADERS.items():
        save_img(Image.open(src(h)), mk("specialists", "leader_%s.jpg" % col), 531, 90)
        leaders[col] = "res://assets/specialists/leader_%s.jpg" % col
    journals = []
    for j in DC.JOURNALS:
        d = dict(j)
        idx = int(j["id"][1:])
        im = grid_cut("FCFF9553", 4, 2, idx) if j.get("anchor") else grid_cut("55CB787C", 6, 4, idx)
        save_img(im, mk("journals", j["id"] + ".jpg"), 560, 90)
        d["image"] = "res://assets/journals/%s.jpg" % j["id"]
        for k in ("you", "others", "slots"):
            d.setdefault(k, [])
        d.setdefault("points", 0)
        journals.append(d)
    save_img(Image.open(src("41DB2B31")), mk("journals", "back.jpg"), 560, 88)
    save_img(Image.open(src("9CDC0633")), mk("journals", "back_anchor.jpg"), 560, 88)
    dive = []
    for t in DC.DIVE_TOKENS:
        d = dict(t)
        save_img(Image.open(src(t["img"])), mk("dive", t["id"] + ".jpg"), 295, 92)
        d["image"] = "res://assets/dive/%s.jpg" % t["id"]
        del d["img"]
        dive.append(d)
    save_img(Image.open(src(DC.DIVE_BACK)), mk("dive", "back.jpg"), 295, 92)
    return {"specialists": specs, "leaders": leaders, "leader": DC.TEAM_LEADER, "journals": journals, "dive": dive}


# ───────────────────────── missioni ─────────────────────────
MISSION_IMG = {1: "56BF2B11", 2: "EF7AAEA5", 3: "6EAD8FB7", 4: "573103D4", 5: "D7B615F1", 6: "62A14DC8",
               7: "6DDBA2FD", 8: "990F1CDB", 9: "DCEB2449", 10: "8E72070B"}
SW, SH = 3189.0, 2126.0


def build_missions():
    out = {}
    for mid, h in MISSION_IMG.items():
        save_img(Image.open(src(h)), mk("missions", "m%d.jpg" % mid), 2400, 88)
    save_img(Image.open(src("C78AAB83")), mk("missions", "back.jpg"), 1200, 85)
    for mid, m in DM.MISSIONS.items():
        d = json.loads(json.dumps(m))
        lat = m.get("lattice")
        if lat:
            v1 = lat["v1"]
            a = math.radians(lat["ang"])
            v2 = [v1[0] * math.cos(a) - v1[1] * math.sin(a), v1[0] * math.sin(a) + v1[1] * math.cos(a)]
            L = math.hypot(*v1)
        else:
            L = 212.0

        def at(i, j):
            if m.get("hex_px"):
                return [float(i), float(j)]
            return [lat["O"][0] + i * v1[0] + j * v2[0], lat["O"][1] + i * v1[1] + j * v2[1]]

        hexes = []
        px = []
        key = {}
        for spec in m["hexes"]:
            i, j, content, pts = spec[:4]
            extra = spec[4] if len(spec) > 4 else {}
            p = extra.get("px") or at(i, j)
            hx = {"ij": [i, j], "pos": [round(p[0] / SW, 4), round(p[1] / SH, 4)], "r": "" if content == "INF" else content,
                  "pts": pts, "inf": content == "INF"}
            for k2, v in extra.items():
                if k2 not in ("px", "from", "from_px"):
                    hx[k2] = v
            key[(i, j)] = len(hexes)
            hexes.append(hx)
            px.append(p)
        # adiacenza geometrica (gli infiniti fuori reticolo si raggiungono solo dalle frecce)
        for a_i, ha in enumerate(hexes):
            ha["adj"] = []
            if "px" in (m["hexes"][a_i][4] if len(m["hexes"][a_i]) > 4 else {}):
                continue
            for b_i, hb in enumerate(hexes):
                if a_i == b_i or "px" in (m["hexes"][b_i][4] if len(m["hexes"][b_i]) > 4 else {}):
                    continue
                if m.get("depth_rows") and (hb.get("inf") or ha.get("inf")):
                    continue
                dist = math.hypot(px[a_i][0] - px[b_i][0], px[a_i][1] - px[b_i][1])
                if dist < L * 1.18:
                    ha["adj"].append(b_i)
        # frecce a senso unico verso gli infiniti
        for a_i, spec in enumerate(m["hexes"]):
            extra = spec[4] if len(spec) > 4 else {}
            fr = []
            for f in extra.get("from", []):
                fr.append(key[tuple(f)])
            for f in extra.get("from_px", []):
                fr.append(key[tuple(f)])
            if fr:
                hexes[a_i]["from"] = fr
        ent = [tuple(e) for e in m.get("entries", [])] + [tuple(e) for e in m.get("entries_px", [])]
        for (i, j), k in key.items():
            hexes[k]["entry"] = (i, j) in ent
        d["hexes"] = hexes
        d["hex_r"] = round(L / 2 / SW, 4)
        d["image"] = "res://assets/missions/m%d.jpg" % mid
        if "start_hex" in m:
            i, j = m["start_hex"]
            p = at(i, j)
            d["start_hex"] = [round(p[0] / SW, 4), round(p[1] / SH, 4)]
        if "cleanup" in d:
            d["cleanup"]["px"] = [[round(x / SW, 4), round(y / SH, 4)] for x, y in m["cleanup"]["px"]]
        for k2 in ("lattice", "entries", "entries_px", "hex_px"):
            d.pop(k2, None)
        out[str(mid)] = d
    return out


# ───────────────────────── giocatori ─────────────────────────
PLAYERS = {
    "yellow": {"name": "Giallo", "color": "#f2c418", "mat": "D9131999", "disc": "407A053C", "vessel": "9B7B1FA9", "impact": "9D64821E"},
    "purple": {"name": "Viola", "color": "#8a2db0", "mat": "E7234F31", "disc": "3A195054", "vessel": "561D1824", "impact": "014BA673"},
    "white": {"name": "Bianco", "color": "#e9e9e9", "mat": "1659A508", "disc": "28F10BEA", "vessel": "2B4AB698", "impact": "948C2B7D"},
    "red": {"name": "Rosso", "color": "#e3262e", "mat": "72A5E838", "disc": "35F90A26", "vessel": "0940F4E6", "impact": "3BEA3501"},
}


def build_players():
    out = {}
    for col, p in PLAYERS.items():
        save_img(Image.open(src(p["mat"])), mk("mats", col + ".jpg"), 2000, 88)
        for kind in ("disc", "vessel", "impact"):
            im = Image.open(src(p[kind])).convert("RGBA")
            save_img(im, mk("tokens", "%s_%s.png" % (kind, col)), 300)
        out[col] = {"name": p["name"], "color": p["color"], "mat": "res://assets/mats/%s.jpg" % col,
                    "disc": "res://assets/tokens/disc_%s.png" % col, "vessel": "res://assets/tokens/vessel_%s.png" % col,
                    "impact": "res://assets/tokens/impact_%s.png" % col,
                    "leader": "res://assets/specialists/leader_%s.jpg" % col}
    save_img(Image.open(src("4FB0C656")).convert("RGBA"), mk("tokens", "wave.png"), 300)
    save_img(Image.open(src("8E8BC0B3")), mk("tokens", "tier5_slot.jpg"), 353)
    tbl = Image.open(src("113B65D0"))
    save_img(tbl, mk("table.jpg"), 2048, 85)
    return out


# Plancia (pixel della texture 2657x1713): tracciati, Ricerca, area di preparazione, token.
MAT = {
    "size": [2657, 1713],
    "track_y": {"rep": 218, "insp": 508, "coord": 800, "ing": 1091},
    "track_x": [524, 660, 825, 990, 1155, 1316, 1478, 1643, 1805, 1966, 2130, 2293, 2450],
    "research": [[1773, 1418], [1928, 1418], [2083, 1418], [2236, 1418], [2388, 1418], [2541, 1418],
                 [1620, 1601], [1773, 1601], [1928, 1601], [2083, 1601], [2236, 1601], [2388, 1601], [2541, 1601]],
    "staging": [35, 1318, 1065, 1676],
    "dive_slot": [1290, 1496],
}

RULES = {
    "rounds": 6,
    "level": [1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5],
    "bracket": [0, 0, 2, 2, 4, 4, 4, 7, 7, 7, 10, 10, 10],
    "track_max": 12, "impact_at": 10, "research_max": 12,
    "vessel_at": [2, 7], "vessels": 3, "discs": 30, "dive_keep": 1,
    "tier_pockets": 3, "t5_per_pocket": 3, "display": 4,
}


def main():
    os.makedirs(DATA, exist_ok=True)
    zones = build_zones()
    cards = build_cards()
    missions = build_missions()
    players = build_players()
    cover = None
    for f in ("cover-700x697.jpg", "copertina.jpg", "copertina.webp", "copertina.png"):
        for base in (os.path.dirname(MODS), EXTRA):
            p = os.path.join(base, f)
            if os.path.exists(p):
                cover = p
                break
        if cover:
            break
    if cover:
        save_img(Image.open(cover), mk("copertina.jpg"), 1400, 92)
    json.dump(zones, open(os.path.join(DATA, "zones.json"), "w"), indent=1, ensure_ascii=False)
    json.dump(cards, open(os.path.join(DATA, "cards.json"), "w"), indent=1, ensure_ascii=False)
    json.dump(missions, open(os.path.join(DATA, "missions.json"), "w"), indent=1, ensure_ascii=False)
    json.dump({"players": players, "mat": MAT, "rules": RULES}, open(os.path.join(DATA, "rules.json"), "w"),
              indent=1, ensure_ascii=False)
    # Fogli missione in italiano (scansioni), allineati ai fogli del mod: sostituiscono gli inglesi.
    ita = os.path.join(os.path.dirname(os.path.abspath(MODS)), "Missioni Italiano.pdf")
    if os.path.exists(ita):
        import subprocess
        subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "allinea_missioni.py"),
                        ita, MODS, PROJ], check=False)
    if missing:
        print("IMMAGINI MANCANTI nella cache:", sorted(set(missing)))
    print("zone %d, specialisti %d, diari %d, missioni %d" % (len(zones), len(cards["specialists"]),
                                                                len(cards["journals"]), len(missions)))


if __name__ == "__main__":
    main()
