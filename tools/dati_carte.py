# -*- coding: utf-8 -*-
"""Specialisti, Giornali e token Immersione di Endeavor: Deep Sea, trascritti dalle immagini del mod
(controllati con le descrizioni del mod cinese "Full Script").

Ricompense: rep insp coord ing (attributi), any (a scelta), low (il più basso), res (+1 Ricerca),
impact, disc, promote.  Azioni: travel sonar dive cons journal promote copy.
"acts": {"mode": "one"|"all", "list": [...]}: "one" = una a scelta (simbolo "/"), "all" = tutte, in
qualunque ordine. Le immagini sono identificate dall'hash dell'URL nel mod.
"""

SPECIALISTS = [
    # id, tier, (img junior, img senior), junior, senior
    {"id": "sonar_operator", "tier": 1, "count": 5, "img": ["EA1A34D8", "CF504CBE"],
     "j": {"name": "Operatore sonar", "en": "Sonar Operator", "gain": ["coord"], "acts": {"mode": "one", "list": ["sonar"]}},
     "s": {"name": "Ingegnere acustico", "en": "Acoustics Engineer", "gain": ["coord"], "acts": {"mode": "one", "list": ["travel", "sonar"]}}},
    {"id": "reef_diver", "tier": 1, "count": 5, "img": ["A2D08EF6", "2CEAB3C8"],
     "j": {"name": "Sub di barriera", "en": "Reef Diver", "gain": ["rep"], "acts": {"mode": "one", "list": ["dive"]}},
     "s": {"name": "Fotografo subacqueo", "en": "Underwater Photographer", "gain": ["rep"], "acts": {"mode": "one", "list": ["dive", "journal"]}}},
    {"id": "pilot", "tier": 1, "count": 5, "img": ["3B5E8B39", "612BEB90"],
     "j": {"name": "Pilota", "en": "Pilot", "gain": ["impact"], "acts": {"mode": "one", "list": ["travel"]}},
     "s": {"name": "Skipper", "en": "Skipper", "gain": ["insp", "coord"], "acts": {"mode": "one", "list": ["travel"]}}},
    {"id": "marine_engineer", "tier": 2, "count": 4, "img": ["332E886A", "1B151E53"],
     "j": {"name": "Ingegnere navale", "en": "Marine Engineer", "gain": ["ing", "ing"], "acts": {"mode": "one", "list": []}},
     "s": {"name": "Architetto navale", "en": "Naval Architect", "gain": [], "acts": {"mode": "one", "list": ["travel", "journal"]}}},
    {"id": "navigator", "tier": 2, "count": 4, "img": ["7305FAC0", "560EB0B4"],
     "j": {"name": "Navigatore", "en": "Navigator", "gain": ["insp"], "acts": {"mode": "one", "list": ["travel", "sonar"]}},
     "s": {"name": "Idrografo", "en": "Hydrographer", "gain": [], "acts": {"mode": "all", "list": ["sonar", "dive"]}}},
    {"id": "ecologist", "tier": 2, "count": 4, "img": ["E0A284D4", "A3B42C06"],
     "j": {"name": "Ecologa", "en": "Ecologist", "gain": [], "acts": {"mode": "one", "list": ["travel", "cons"]}},
     "s": {"name": "Ecotossicologa", "en": "Ecotoxicologist", "gain": ["coord", "coord"], "acts": {"mode": "one", "list": ["dive", "cons"]}}},
    {"id": "field_researcher", "tier": 3, "count": 3, "img": ["4CF92531", "3B8BC1D1"],
     "j": {"name": "Ricercatore sul campo", "en": "Field Researcher", "gain": [], "acts": {"mode": "all", "list": ["sonar", "journal"]}},
     "s": {"name": "Scienziato marino", "en": "Marine Scientist", "gain": [], "acts": {"mode": "all", "list": ["travel", "journal"]}}},
    {"id": "marine_biologist", "tier": 3, "count": 3, "img": ["477910C0", "871DE92D"],
     "j": {"name": "Biologo marino", "en": "Marine Biologist", "gain": ["insp", "insp"], "acts": {"mode": "one", "list": ["cons", "journal"]}},
     "s": {"name": "Acquacoltore", "en": "Aquaculturist", "gain": [], "acts": {"mode": "all", "list": ["cons", "cons"]}}},
    {"id": "rov_operator", "tier": 3, "count": 3, "img": ["D2BB41C6", "60D72551"],
     "j": {"name": "Operatrice ROV", "en": "R.O.V. Operator", "gain": [], "acts": {"mode": "all", "list": ["travel", "dive"]}},
     "s": {"name": "Videografa degli abissi", "en": "Deep-Sea Videographer", "gain": ["rep", "rep"], "acts": {"mode": "all", "list": ["dive", "cons"]}}},
    {"id": "vessel_captain", "tier": 4, "count": 2, "img": ["FFE49B42", "79BF9D90"],
     "j": {"name": "Capitano", "en": "Vessel Captain", "gain": ["ing"], "acts": {"mode": "all", "list": ["travel", "travel"]}},
     "s": {"name": "Capo spedizione", "en": "Expedition Leader", "gain": ["ing"], "acts": {"mode": "all", "list": ["travel", "sonar"]}}},
    {"id": "deep_sea_diver", "tier": 4, "count": 2, "img": ["D20C09A6", "8671B47E"],
     "j": {"name": "Palombara", "en": "Deep-Sea Diver", "gain": ["impact"], "acts": {"mode": "all", "list": ["dive", "dive"]}},
     "s": {"name": "Biologa degli abissi", "en": "Deep-Sea Biologist", "gain": ["res", "res"], "acts": {"mode": "all", "list": ["travel", "cons"]}}},
    {"id": "oceanographer", "tier": 4, "count": 2, "img": ["6201FC54", "4BBC62FE"],
     "j": {"name": "Oceanografa", "en": "Oceanographer", "gain": ["rep", "insp", "coord", "ing"], "acts": {"mode": "one", "list": ["sonar", "journal"]}},
     "s": {"name": "Ambasciatrice ambientale", "en": "Environmental Ambassador", "gain": ["impact", "impact"], "acts": {"mode": "one", "list": []}}},
    # ── livello 5: tutti diversi; da Senior nessuna azione, un punteggio finale ──
    {"id": "adventurer", "tier": 5, "count": 1, "img": ["210B6B79", "87DAFBDB"],
     "j": {"name": "Avventuriera", "en": "Adventurer", "gain": ["insp", "insp", "insp"], "acts": {"mode": "all", "list": ["sonar", "sonar"]}},
     "s": {"name": "Avventuriera rinomata", "en": "Renowned Adventurer", "gain": [], "acts": {"mode": "one", "list": []}, "score": "zones3",
           "score_text": "1 ogni 3 zone dove hai un gettone o una Nave"}},
    {"id": "biogeographer", "tier": 5, "count": 1, "img": ["03F8B8BA", "1F7A627C"],
     "j": {"name": "Biogeografa", "en": "Biogeographer", "gain": ["ing"], "acts": {"mode": "all", "list": ["travel", "dive", "cons"]}},
     "s": {"name": "Biogeografa rinomata", "en": "Renowned Biogeographer", "gain": [], "acts": {"mode": "one", "list": []}, "score": "cons_zones",
           "score_text": "1 per ogni zona dove hai un gettone Conservazione"}},
    {"id": "mentor", "tier": 5, "count": 1, "img": ["89485C40", "F8523ADE"],
     "j": {"name": "Mentore", "en": "Mentor", "gain": ["coord", "coord"], "acts": {"mode": "one", "list": ["journal", "promote"]}},
     "s": {"name": "Mentore rinomata", "en": "Renowned Mentor", "gain": [], "acts": {"mode": "one", "list": []}, "score": "seniors",
           "score_text": "1 per ogni altro tuo Specialista Senior"}},
    {"id": "fleet_coordinator", "tier": 5, "count": 1, "img": ["4F6B788C", "1E4911BA"],
     "j": {"name": "Coordinatore di flotta", "en": "Fleet Coordinator", "gain": ["ing"], "acts": {"mode": "all", "list": ["travel", "travel", "travel"]}},
     "s": {"name": "Coordinatore di flotta rinomato", "en": "Renowned Fleet Coordinator", "gain": [], "acts": {"mode": "one", "list": []}, "score": "shared_links",
           "score_text": "1 ogni 2 collegamenti completati che condividi con avversari"}},
    {"id": "ocean_historian", "tier": 5, "count": 1, "img": ["741FEDCF", "0F70EE80"],
     "j": {"name": "Storica dell'oceano", "en": "Ocean Historian", "gain": ["coord"], "acts": {"mode": "all", "list": ["dive", "dive", "journal"]}},
     "s": {"name": "Storica dell'oceano rinomata", "en": "Renowned Ocean Historian", "gain": [], "acts": {"mode": "one", "list": []}, "score": "field_sets",
           "score_text": "3 per ogni serie dei quattro simboli di Campo"}},
    {"id": "robotics_engineer", "tier": 5, "count": 1, "img": ["CA287AFD", "3BA94F29"],
     "j": {"name": "Ingegnere robotico", "en": "Robotics Engineer", "gain": ["insp", "insp"], "acts": {"mode": "one", "list": ["copy"]}},
     "s": {"name": "Ingegnere robotico rinomato", "en": "Renowned Robotics Engineer", "gain": [], "acts": {"mode": "one", "list": []}, "score": "flat4",
           "score_text": "4 punti"}},
    {"id": "ichthyologist", "tier": 5, "count": 1, "img": ["463C6769", "683A925E"],
     "j": {"name": "Ittiologo", "en": "Ichthyologist", "gain": ["insp"], "acts": {"mode": "all", "list": ["dive", "cons", "cons"]}},
     "s": {"name": "Ittiologo rinomato", "en": "Renowned Ichthyologist", "gain": [], "acts": {"mode": "one", "list": []}, "score": "cons_one_zone",
           "score_text": "1 per ogni tuo gettone Conservazione in una sola zona"}},
    {"id": "dive_team_leader", "tier": 5, "count": 1, "img": ["C840CDBC", "19F38F53"],
     "j": {"name": "Capo squadra sub", "en": "Dive Team Leader", "gain": ["ing", "ing", "ing"], "acts": {"mode": "all", "list": ["travel", "dive"]}},
     "s": {"name": "Capo squadra sub rinomata", "en": "Renowned Dive Team Leader", "gain": [], "acts": {"mode": "one", "list": []}, "score": "empty_dives",
           "score_text": "1 ogni 2 siti Immersione vuoti nell'oceano"}},
    {"id": "biotechnologist", "tier": 5, "count": 1, "img": ["92EF3129", "419B4458"],
     "j": {"name": "Biotecnologo", "en": "Biotechnologist", "gain": ["res", "res", "res", "res"], "acts": {"mode": "all", "list": ["cons", "journal"]}},
     "s": {"name": "Biotecnologo rinomato", "en": "Renowned Biotechnologist", "gain": [], "acts": {"mode": "one", "list": []}, "score": "journal_depths",
           "score_text": "1 per ogni profondità dove hai un gettone Diario"}},
]

TEAM_LEADERS = {  # colore giocatore -> immagine del Capo squadra
    "yellow": "D3E88197", "purple": "2BD1ED35", "white": "50BB3112", "red": "EC4D98EB",
}
TEAM_LEADER = {"name": "Capo squadra", "en": "Team Leader", "gain": [],
               "acts": {"mode": "one", "list": ["travel", "sonar", "dive", "cons", "journal"]}}

# Giornali: foglio 6x4 (j00..j23) e Giornali àncora 4x2 (a00..a07), in ordine di lettura.
# fields: simboli di Campo; you: guadagni per chi pubblica; others: per tutti gli altri;
# points: punti a fine partita; slots: azioni (un disco per spazio, resta per sempre).
# Azioni dei Giornali: dive2 (Immersione + un altro token dallo stesso sito), travel1 (Viaggio con
# Tecnologia +1), cons_depth (Conservazione alla stessa profondità di una tua Nave), promote,
# discover35 (Scoperta 3-5).
JOURNALS = [
    {"id": "j00", "cost": 3, "fields": ["yellow"], "you": ["insp", "impact", "promote"], "en": "Improving Working Environments for Marine Studies"},
    {"id": "j01", "cost": 4, "fields": ["yellow", "green"], "you": ["rep", "rep", "promote"], "slots": ["cons_depth", "cons_depth"], "en": "Protecting Threatened Marine Habitats"},
    {"id": "j02", "cost": 2, "fields": ["yellow", "brown"], "you": ["coord", "ing", "promote"], "others": ["coord"], "en": "Advanced Sonar Communication Techniques"},
    {"id": "j03", "cost": 3, "fields": ["brown", "green"], "you": ["rep", "promote"], "others": ["res", "res"], "slots": ["promote"], "en": "Publication Guide for Undersea Research"},
    {"id": "j04", "cost": 2, "fields": ["brown", "green"], "you": ["promote"], "others": ["insp"], "slots": ["travel1", "travel1"], "en": "The Rising Tide of Achievement"},
    {"id": "j05", "cost": 3, "fields": ["brown", "green"], "you": ["insp", "insp", "promote"], "others": ["coord"], "slots": ["dive2"], "en": "Enhancing Research Productivity"},
    {"id": "j06", "cost": 3, "fields": ["brown", "green"], "you": ["impact", "promote"], "others": ["res", "res"], "slots": ["cons_depth", "cons_depth"], "en": "The Interlinked Ecosystem"},
    {"id": "j07", "cost": 2, "fields": ["blue", "yellow"], "points": 2, "you": ["ing", "ing"], "en": "Advanced Pressure-Venting Technology"},
    {"id": "j08", "cost": 3, "fields": ["blue", "yellow"], "points": 2, "you": ["coord", "promote"], "en": "AI models for Deep-Sea Research"},
    {"id": "j09", "cost": 3, "fields": ["blue", "yellow"], "points": 2, "you": ["rep", "promote"], "en": "Publicity's Role in Scientific Advancement"},
    {"id": "j10", "cost": 3, "fields": ["yellow", "green"], "you": ["coord", "promote"], "slots": ["dive2"], "en": "Understanding Life in the Deepest Sea"},
    {"id": "j11", "cost": 3, "fields": ["blue", "green"], "points": 3, "slots": ["discover35"], "en": "Deepwater Satellite Imaging"},
    {"id": "j12", "cost": 4, "fields": ["blue", "green"], "points": 2, "slots": ["promote", "promote"], "en": "The Nautical Journals"},
    {"id": "j13", "cost": 4, "fields": ["blue", "brown"], "points": 2, "you": ["rep", "insp", "coord"], "others": ["disc"], "en": "Volunteer Model for Underwater Conservation"},
    {"id": "j14", "cost": 2, "fields": ["blue"], "points": 4, "en": "Feasibility Report: Aquadome Permanent Lab"},
    {"id": "j15", "cost": 0, "fields": ["blue", "brown"], "points": 3, "others": ["ing"], "en": "Fluorescence-Detecting Optical Systems"},
    {"id": "j16", "cost": 0, "fields": ["blue"], "points": 2, "en": "Holographic Ocean Floor Visualization"},
    {"id": "j17", "cost": 4, "fields": ["blue", "yellow"], "points": 2, "you": ["impact", "impact", "ing"], "en": "Autonomous Microplastic Reclamation Filters"},
    {"id": "j18", "cost": 2, "fields": ["brown"], "you": ["coord", "coord", "promote"], "others": ["coord"], "en": "Networking for Underwater Communication"},
    {"id": "j19", "cost": 2, "fields": ["brown"], "you": ["insp", "insp", "promote"], "others": ["insp"], "en": "Benefits of Inter-Team Data-Sharing"},
    {"id": "j20", "cost": 3, "fields": ["green"], "you": ["promote"], "slots": ["discover35"], "en": "Review of Current Oceanography Research"},
    {"id": "j21", "cost": 1, "fields": ["green"], "you": ["promote"], "slots": ["travel1"], "en": "Safe Movement Procedures"},
    {"id": "j22", "cost": 4, "fields": ["yellow", "brown"], "you": ["rep", "rep", "impact", "promote"], "others": ["low"], "en": "Documentation of New Life"},
    {"id": "j23", "cost": 3, "fields": ["yellow"], "you": ["ing", "impact", "promote"], "en": "Social Structures of Marine Mammals"},
    {"id": "a00", "anchor": True, "cost": 2, "fields": ["brown"], "you": ["ing", "ing", "promote"], "others": ["ing"], "en": "Organic Casing for Deep-Sea Exploration"},
    {"id": "a01", "anchor": True, "cost": 0, "fields": ["blue", "brown"], "points": 1, "you": ["promote"], "others": ["ing"], "en": "Uncharted Deep-Sea Organic Life"},
    {"id": "a02", "anchor": True, "cost": 2, "fields": ["brown"], "you": ["rep", "rep", "promote"], "others": ["rep"], "en": "Optimizing Multi-Team Discovery Announcements"},
    {"id": "a03", "anchor": True, "cost": 3, "fields": ["yellow", "brown"], "you": ["insp", "insp", "promote"], "others": ["disc"], "en": "Effective Communication of Ecosystemic Risk"},
    {"id": "a04", "anchor": True, "cost": 1, "fields": ["green"], "you": ["promote"], "slots": ["cons_depth"], "en": "Extending Conservation Area of Effectiveness"},
    {"id": "a05", "anchor": True, "cost": 3, "fields": ["yellow", "green"], "you": ["coord", "promote"], "slots": ["travel1"], "en": "Mobile Techniques for Underwater Exploration"},
    {"id": "a06", "anchor": True, "cost": 2, "fields": ["yellow"], "you": ["coord", "promote"], "en": "Understanding Oceanic Shifts"},
    {"id": "a07", "anchor": True, "cost": 2, "fields": ["yellow"], "you": ["rep", "promote"], "en": "Reef Photography with Swarm Camera Systems"},
]

# Token Immersione (36): Ricerca + effetto. Immagini 295x295.
DIVE_TOKENS = [
    {"id": "promote", "res": 4, "fx": "promote", "n": 2, "img": "B7702412"},
    {"id": "impact", "res": 3, "fx": "impact", "n": 4, "img": "57ADB346"},
    {"id": "sonar", "res": 3, "fx": "sonar", "n": 2, "img": "FDADC882"},
    {"id": "any", "res": 4, "fx": "any", "n": 4, "img": "87D4B604"},
    {"id": "dive", "res": 3, "fx": "dive", "n": 2, "img": "4EAF7078"},
    {"id": "travel", "res": 3, "fx": "travel", "n": 4, "img": "72A93B63"},
    {"id": "journal", "res": 3, "fx": "journal", "n": 2, "img": "1C4D293F"},
    {"id": "disc", "res": 3, "fx": "disc", "n": 4, "img": "5E15CB17"},
    {"id": "plain", "res": 4, "fx": "", "n": 6, "img": "D0D87E26"},
    {"id": "cons", "res": 3, "fx": "cons1", "n": 2, "img": "576138EE"},
    {"id": "trade", "res": 3, "fx": "trade", "n": 2, "img": "54B72521"},
    {"id": "low", "res": 3, "fx": "low", "n": 2, "img": "2AAC1912"},
]
DIVE_BACK = "3ADA77F9"
