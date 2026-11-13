#!/usr/bin/env python3
"""Fase 8B — Covis do Ferreiro Andarilho (pedido do dono, 13/11/2026).

Gera, a partir das tabelas abaixo:
  - data/world/covis.json            regras e os 5 covis (dias, entradas, receitas, prêmios)
  - data/items/items.json            peças rara/épica dos 5 conjuntos, fragmentos, essências,
                                     licença e os conjuntos com combos (troca só as chaves daqui)
  - data/maps/covil_<chefe>.json     as 5 arenas
  - data/i18n/strings.csv            chaves CV_* (troca só as dele)

Rodar:  python -X utf8 tools/content/gen_covis.py
Os números de equilíbrio ficam aqui; nunca editar as saídas à mão.
"""
import csv
import io
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import json_compact  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]

SLOTS = ["weapon", "helmet", "chest", "gloves", "pants", "boots", "bracelet", "belt"]
SLOT_PT = {"weapon": "arma", "helmet": "elmo", "chest": "peitoral", "gloves": "luvas", "pants": "calca",
           "boots": "botas", "bracelet": "pulseira", "belt": "cinto"}
# Base item of each slot (epic, level 40): its stats are scaled to the set level.
BASE = {"weapon": "eq_espada_epico", "helmet": "eq_elmo_epico", "chest": "eq_peitoral_epico",
        "gloves": "eq_luvas_epico", "pants": "eq_calca_epico", "boots": "eq_botas_epico",
        "bracelet": "eq_pulseira_epico", "belt": "eq_cinto_epico"}
GLYPH = {"weapon": "/", "helmet": "^", "chest": "#", "gloves": "m", "pants": "n", "boots": "b",
         "bracelet": "o", "belt": "="}
RARE_COLOR = "#4da3ff"
EPIC_COLOR = "#b46bff"

RULES = {
    "_comment": "Covis do Ferreiro Andarilho (Fase 8B). Gerado por tools/content/gen_covis.py; não editar à mão. Abertos nos dias open_weekdays (0 = domingo); free_per_day entradas por dia somando todos os covis, depois cada entrada gasta 1 license_item. Prêmio do chefe: frag fragmentos (min-max) e uma essência com ess_chance. Peça rara = frag_cost fragmentos (arma: frag_cost_weapon) + ouro (gold_rare × nível); épica = a rara + ess_cost essências + ouro (gold_epic × nível). Combos épicos ficam epic_combo_mult mais fortes.",
    "open_weekdays": [1, 3, 5, 0],
    "free_per_day": 10,
    "license_item": "licenca_covil",
    "frag": [2, 4],
    "ess_chance": 0.5,
    "frag_cost": 8,
    "frag_cost_weapon": 12,
    "ess_cost": 10,
    "gold_rare": 30,
    "gold_epic": 90,
    "rare_mult": 0.95,
    "epic_mult": 1.25,
    "epic_combo_mult": 1.5,
}

# Combos: "bonus" = stat share (atk_pct = +8% attack...), "effects" = what HeroCombos does.
COVIS = [
    {
        "id": "gorvan", "city": "pradoluz", "boss": "gorvan", "boss_level": 12, "level": 10,
        "unlock": "gorvan_defeated", "set": "colheita_rubra", "color": "#c0392b",
        "pt": "Colheita Rubra", "en": "Crimson Harvest", "boss_pt": "Gorvan", "frag_pt": "Fragmento da Foice", "frag_en": "Scythe Shard",
        "ess_pt": "Essência Rubra", "ess_en": "Crimson Essence",
        "weapon": {"scene": "res://assets/weapons/wpn_foice_gorvan/wpn_foice_gorvan.glb", "length": 0.88, "model_rotation_deg": [0, 0, -58.1], "hold_point": [0.099, -0.043, 0]},
        "weapon_pt": "Foice", "weapon_en": "Scythe",
        "style": "celeiro", "minions": ["orc", "bandido"],
        "bonus": {"2": {"atk_pct": 0.08}},
        "effects": {"4": {"id": "reap", "chance": 0.15, "mult": 0.8, "radius": 2.6},
                    "6": {"id": "heal_on_kill", "value": 0.03},
                    "8": {"id": "skill_boost", "skill": "corte_giratorio", "dmg": 0.4, "pull": 4.0}},
        "combo_pt": ["+8% de ataque", "Golpe comum: 15% de chance de ceifar em volta", "Matar um inimigo cura 3% da vida", "Corte Giratório puxa os inimigos e bate 40% mais forte"],
        "combo_en": ["+8% attack", "Basic hit: 15% chance to reap around you", "Each kill heals 3% of your health", "Whirling Cut pulls enemies in and hits 40% harder"],
    },
    {
        "id": "sahra", "city": "qaressa", "boss": "sahra", "boss_level": 28, "level": 25,
        "unlock": "sahra_defeated", "set": "tempestade_areia", "color": "#e0a640",
        "pt": "Tempestade de Areia", "en": "Sandstorm", "boss_pt": "Sahra", "frag_pt": "Cristal de Areia Viva", "frag_en": "Living Sand Crystal",
        "ess_pt": "Essência da Tempestade", "ess_en": "Storm Essence",
        "weapon": {"scene": "res://assets/weapons/wpn_khopesh/wpn_khopesh.glb", "length": 0.8, "grip": 0.38},
        "weapon_pt": "Khopesh", "weapon_en": "Khopesh",
        "style": "torre", "minions": ["homem_lagarto", "bandido_deserto"],
        "bonus": {"2": {"atk_speed": 0.06}},
        "effects": {"4": {"id": "sand_wave", "every": 4, "mult": 0.9, "length": 5.0},
                    "6": {"id": "dodge_whirl", "radius": 2.8, "slow": 0.4, "time": 3.0},
                    "8": {"id": "skill_boost", "skill": "investida", "dmg": 0.35, "status": {"id": "slow", "time": 3.0, "value": 0.5}}},
        "combo_pt": ["+6% de velocidade de ataque", "Todo 4º golpe comum solta uma onda de areia", "A esquiva deixa um redemoinho que deixa os inimigos lentos", "Investida bate 35% mais forte e deixa os inimigos lentos"],
        "combo_en": ["+6% attack speed", "Every 4th basic hit sends out a sand wave", "Dodging leaves a whirlwind that slows enemies", "Charge hits 35% harder and slows enemies"],
    },
    {
        "id": "brannoc", "city": "hrimvald", "boss": "brannoc", "boss_level": 44, "level": 40,
        "unlock": "brannoc_defeated", "set": "coroa_gelo", "color": "#7fc8ff",
        "pt": "Coroa de Gelo", "en": "Ice Crown", "boss_pt": "Brannoc", "frag_pt": "Lasca de Gelo Eterno", "frag_en": "Everfrost Shard",
        "ess_pt": "Essência do Inverno", "ess_en": "Winter Essence",
        "weapon": {"scene": "res://assets/weapons/wpn_machado_brannoc/wpn_machado_brannoc.glb", "length": 0.85, "grip": 0.28},
        "weapon_pt": "Machado", "weapon_en": "Axe",
        "style": "castelo", "minions": ["morto_gelo", "orc_neve"],
        "bonus": {"2": {"def_pct": 0.1}},
        "effects": {"4": {"id": "parry_freeze", "time": 1.5},
                    "6": {"id": "hurt_cdr", "seconds": 0.5},
                    "8": {"id": "skill_boost", "skill": "golpe_sismico", "dmg": 0.3, "status": {"id": "slow", "time": 3.0, "value": 0.5}}},
        "combo_pt": ["+10% de defesa", "Aparar congela o inimigo por mais 1,5 s", "Tomar dano diminui 0,5 s a recarga das skills", "Golpe Sísmico vira avalanche: 30% mais forte e deixa lento"],
        "combo_en": ["+10% defense", "Parrying freezes the enemy for 1.5 s more", "Taking damage cuts skill cooldowns by 0.5 s", "Seismic Strike becomes an avalanche: 30% harder and slows"],
    },
    {
        "id": "velyra", "city": "lysthael", "boss": "velyra", "boss_level": 56, "level": 55,
        "unlock": "velyra_defeated", "set": "coracao_espinhos", "color": "#9b59b6",
        "pt": "Coração de Espinhos", "en": "Thorn Heart", "boss_pt": "Velyra", "frag_pt": "Semente de Espinho", "frag_en": "Thorn Seed",
        "ess_pt": "Seiva da Dríade", "ess_en": "Dryad Sap",
        "weapon": {"scene": "res://assets/weapons/wpn_lamina_espinhos/wpn_lamina_espinhos.glb", "length": 0.9, "grip": 0.36},
        "weapon_pt": "Lâmina de Espinhos", "weapon_en": "Thorn Blade",
        "style": "topo_torre", "minions": ["lagarto_pantano", "morto_pantano"],
        "bonus": {"2": {"max_hp_pct": 0.08}},
        "effects": {"4": {"id": "thorns", "value": 0.2},
                    "6": {"id": "bleed", "share": 0.15, "ticks": 4},
                    "8": {"id": "skill_boost", "skill": "salto_devastador", "dmg": 0.35, "status": {"id": "slow", "time": 3.0, "value": 0.4}}},
        "combo_pt": ["+8% de vida máxima", "Devolve 20% do dano corpo a corpo recebido", "Golpes críticos fazem sangrar", "Salto Devastador deixa espinhos: 35% mais forte e deixa lento"],
        "combo_en": ["+8% max health", "Returns 20% of melee damage taken", "Critical hits make enemies bleed", "Devastating Leap leaves thorns: 35% harder and slows"],
    },
    {
        "id": "vaelor", "city": "altarea", "boss": "vaelor", "boss_level": 65, "level": 60,
        "unlock": "vaelor_defeated", "set": "juramento_celeste", "color": "#a8d8ff",
        "pt": "Juramento Celeste", "en": "Celestial Oath", "boss_pt": "Vaelor", "frag_pt": "Pena Celeste", "frag_en": "Celestial Feather",
        "ess_pt": "Essência Estelar", "ess_en": "Starlight Essence",
        "weapon": {"scene": "res://assets/weapons/wpn_espada_vaelor/wpn_espada_vaelor.glb", "length": 0.95, "grip": 0.35},
        "weapon_pt": "Espada Celeste", "weapon_en": "Celestial Sword",
        "style": "cidadela", "minions": ["sentinela_celeste", "guarda_lei"],
        "bonus": {"2": {"all_pct": 0.05}},
        "effects": {"4": {"id": "fury_rate", "value": 0.3},
                    "6": {"id": "light_rays", "mult": 0.6, "radius": 3.5},
                    "8": {"id": "skill_boost", "skill": "julgamento", "dmg": 0.4, "pillars": 3}},
        "combo_pt": ["+5% em todos os status", "A luz do Despertar enche 30% mais rápido", "No Despertar, cada golpe solta raios de luz em volta", "Julgamento chama mais 3 colunas de luz e bate 40% mais forte"],
        "combo_en": ["+5% to every stat", "The Awakening light fills 30% faster", "While awakened, each hit sends rays of light around", "Judgment calls 3 more pillars of light and hits 40% harder"],
    },
]

# Arena look: copied from each boss's own map.
STYLES = {
    "celeiro": {"ground": "#56463a", "indoor": True, "sky": "#100c10", "ambient": 0.5, "ambient_color": "#9a8a7a", "sun": 0.3, "sun_color": "#ffd7a0",
                "patches": {"color": "#6b5638", "count": 50}, "props": ["prp_feno", "prp_trigo", "prp_barril", "prp_caixa", "prp_lampiao_mina"]},
    "torre": {"ground": "#d9a865", "sky": "#e7a27c", "ambient": 0.56, "sun": 1.15,
              "patches": {"color": "#c99550", "count": 60}, "props": ["env_coluna_ruina", "prp_jarro_agua", "prp_braseiro", "prp_estatua_alada"]},
    "castelo": {"ground": "#cdd6df", "sky": "#6f7f9c", "ambient": 0.55, "sun": 0.9, "sun_color": "#cfdcff", "biome": {"snow": 1.0},
                "patches": {"color": "#e9eef3", "count": 80}, "props": ["prp_estandarte_gelo", "prp_braseiro_frio", "prp_cristal_gelo", "prp_estatua_alada"], "wall": "env_muralha"},
    "topo_torre": {"ground": "#5d6b4c", "indoor": True, "sky": "#2a1d3d", "ambient": 0.62, "sun": 0.65,
                   "patches": {"color": "#4a5a3c", "count": 60}, "props": ["prp_raiz_gigante", "prp_lanterna_elfica", "prp_cogumelo_gigante", "prp_arvore_torta"]},
    "cidadela": {"ground": "#d6cce6", "indoor": True, "sky": "#e6d2ff", "ambient": 0.6, "sun": 0.8,
                 "patches": {"color": "#e8e0f2", "count": 50}, "props": ["prp_nuvem", "env_coluna_celeste", "prp_estatua_alada"]},
}


# Texts of the Wandering Smith's window and messages (CovilPanel, Covis, HeroCombos).
UI_TEXTS = {
    "CV_DAY_0": ("domingo", "Sunday"), "CV_DAY_1": ("segunda", "Monday"), "CV_DAY_2": ("terça", "Tuesday"),
    "CV_DAY_3": ("quarta", "Wednesday"), "CV_DAY_4": ("quinta", "Thursday"), "CV_DAY_5": ("sexta", "Friday"),
    "CV_DAY_6": ("sábado", "Saturday"), "CV_AND": ("e", "and"),
    "CV_NO_LAIR": ("Esta cidade não tem covil.", "This city has no lair."),
    "CV_LOCKED": ("Covil fechado", "Lair locked"), "CV_CLOSED": ("Fechado hoje", "Closed today"),
    "CV_NO_ENTRIES": ("Sem entradas hoje", "No entries left today"),
    "CV_NEED_ITEMS": ("Faltam materiais", "Missing materials"), "CV_NEED_GOLD": ("Falta ouro", "Not enough gold"),
    "CV_NEED_RARE": ("Precisa da peça rara", "Needs the rare piece"),
    "CV_LEVEL": ("nível %d", "level %d"),
    "CV_LOCKED_TEXT": ("Vença %s na história para o Andarilho abrir este covil.", "Beat %s in the story so the Wanderer opens this lair."),
    "CV_CLOSED_TEXT": ("O covil está fechado hoje. Abre %s.", "The lair is closed today. It opens on %s."),
    "CV_OPEN_TEXT": ("Aberto hoje! Entradas grátis: %d de %d · Licenças: %d", "Open today! Free entries: %d of %d · Licenses: %d"),
    "CV_ENTER": ("Entrar no covil", "Enter the lair"),
    "CV_COMBOS": ("Combos do conjunto (vestindo %d peças):", "Set combos (wearing %d pieces):"),
    "CV_PIECES": ("%d peças:", "%d pieces:"),
    "CV_FORGE": ("Forjar peças", "Forge pieces"),
    "CV_THE_RARE": ("a peça rara", "the rare piece"),
    "CV_GOLD": ("%d de ouro", "%d gold"),
    "CV_FORGE_RARE": ("Forjar rara", "Forge rare"), "CV_FORGE_EPIC": ("Promover a épica", "Make it epic"),
    "CV_WON": ("Covil vencido!", "Lair cleared!"),
    "CV_BLEED": ("Sangrando", "Bleeding"),
}


def scaled_stats(slot: str, level: int, mult: float, items: dict) -> dict:
    base = items[BASE[slot]]["stats"]
    k = (level + 10) / 50.0 * mult
    out = {}
    for s, v in base.items():
        if isinstance(v, float) and v < 1.0:
            out[s] = round(v * k, 3)
        else:
            out[s] = max(1, round(v * k))
    return out


def piece_id(slot: str, cv: dict, rarity: str) -> str:
    return "eq_%s_%s_%s" % (SLOT_PT[slot], cv["id"], rarity)


def build_items(items_doc: dict) -> tuple:
    """Returns (new items {id: dict}, new sets {id: dict}, texts)."""
    base_items = items_doc["items"]
    items = {}
    sets = {}
    texts = {}
    for cv in COVIS:
        frag = "mat_frag_" + cv["id"]
        ess = "mat_ess_" + cv["id"]
        items[frag] = {"name": "CV_ITEM_FRAG_" + cv["id"].upper(), "desc": "CV_ITEM_FRAG_DESC", "type": "material", "rarity": "rare",
                       "stack": 999, "price": 20 + cv["level"], "color": cv["color"], "glyph": "*", "covil": cv["id"]}
        items[ess] = {"name": "CV_ITEM_ESS_" + cv["id"].upper(), "desc": "CV_ITEM_ESS_DESC", "type": "material", "rarity": "epic",
                      "stack": 999, "price": 60 + cv["level"] * 2, "color": cv["color"], "glyph": "e", "covil": cv["id"]}
        texts["CV_ITEM_FRAG_" + cv["id"].upper()] = (cv["frag_pt"], cv["frag_en"])
        texts["CV_ITEM_ESS_" + cv["id"].upper()] = (cv["ess_pt"], cv["ess_en"])
        for rarity, mult, color, rar in [("raro", RULES["rare_mult"], RARE_COLOR, "rare"), ("epico", RULES["rare_mult"] * RULES["epic_mult"], EPIC_COLOR, "epic")]:
            for slot in SLOTS:
                pid = piece_id(slot, cv, rarity)
                key = "CV_ITEM_%s_%s" % (SLOT_PT[slot].upper(), cv["id"].upper())
                it = {"name": key, "desc": "CV_ITEM_PIECE_DESC", "type": "equipment", "gear_slot": slot, "rarity": rar,
                      "level": cv["level"], "stack": 1, "price": int(cv["level"] * (6 if rar == "rare" else 15)),
                      "stats": scaled_stats(slot, cv["level"], mult, base_items), "set": cv["set"], "color": color,
                      "glyph": GLYPH[slot], "icon": "eq_%s_%s" % (SLOT_PT[slot], cv["id"]), "covil": cv["id"]}
                if slot == "weapon":
                    it["weapon"] = cv["weapon"]
                items[pid] = it
            slot_names = {"weapon": (cv["weapon_pt"], cv["weapon_en"]), "helmet": ("Elmo", "Helm"), "chest": ("Peitoral", "Chestplate"),
                          "gloves": ("Luvas", "Gauntlets"), "pants": ("Calça", "Leg Guards"), "boots": ("Botas", "Boots"),
                          "bracelet": ("Pulseira", "Bracelet"), "belt": ("Cinto", "Belt")}
            for slot in SLOTS:
                pt, en = slot_names[slot]
                texts["CV_ITEM_%s_%s" % (SLOT_PT[slot].upper(), cv["id"].upper())] = ("%s %s" % (pt, cv["pt"]), "%s %s" % (cv["en"], en))
        sets[cv["set"]] = {"name": "CV_SET_" + cv["id"].upper(), "covil": cv["id"], "bonus": cv["bonus"],
                                        "effects": cv["effects"], "combo_text": ["CV_COMBO_%s_%d" % (cv["id"].upper(), n) for n in (2, 4, 6, 8)]}
        texts["CV_SET_" + cv["id"].upper()] = ("Conjunto %s" % cv["pt"], "%s Set" % cv["en"])
        for i, n in enumerate((2, 4, 6, 8)):
            texts["CV_COMBO_%s_%d" % (cv["id"].upper(), n)] = (cv["combo_pt"][i], cv["combo_en"][i])
    items["licenca_covil"] = {"name": "CV_ITEM_LICENCA", "desc": "CV_ITEM_LICENCA_DESC", "type": "material", "rarity": "epic",
                              "stack": 999, "price": 0, "color": "#d9a62e", "glyph": "L"}
    texts["CV_ITEM_LICENCA"] = ("Licença do Covil", "Lair License")
    texts["CV_ITEM_LICENCA_DESC"] = ("Uma entrada a mais num covil, depois das 10 do dia.", "One more lair entry after the 10 of the day.")
    texts["CV_ITEM_FRAG_DESC"] = ("Cai do chefe do covil. O Ferreiro Andarilho forja peças raras com ele.", "Dropped by the lair's boss. The Wandering Smith forges rare pieces with it.")
    texts["CV_ITEM_ESS_DESC"] = ("Rara, cai do chefe do covil. Com 10, o Ferreiro Andarilho promove uma peça a épica.", "Rare, dropped by the lair's boss. With 10, the Wandering Smith makes a piece epic.")
    texts["CV_ITEM_PIECE_DESC"] = ("Peça de chefe forjada pelo Ferreiro Andarilho. Vestindo várias do mesmo conjunto, ganha combos.", "A boss piece forged by the Wandering Smith. Wear several of the same set to unlock combos.")
    return items, sets, texts


def write_items(path: Path, items: dict, sets: dict) -> None:
    """items.json is laid out by hand, one entry per line: this script's lines are taken
    out and written again (right after the "items" / "sets" openings), the rest stays."""
    lines = path.read_text(encoding="utf-8").split("\n")
    mine = set(items) | set(sets)
    key_re = re.compile(r'^\s{4}"([^"]+)"\s*:')
    out = []
    for ln in lines:
        m = key_re.match(ln)
        if m and m.group(1) in mine:
            continue
        out.append(ln)
        if ln.strip() == '"items": {':
            out += ['    "%s": %s,' % (k, json.dumps(v, ensure_ascii=False)) for k, v in items.items()]
        elif ln.strip() == '"sets": {':
            out += ['    "%s": %s,' % (k, json.dumps(v, ensure_ascii=False)) for k, v in sets.items()]
    path.write_text("\n".join(out), encoding="utf-8")


def build_map(cv: dict) -> dict:
    st = STYLES[cv["style"]]
    m = {"_comment": "Covil do Ferreiro Andarilho (Fase 8B). Gerado por tools/content/gen_covis.py; não editar à mão.",
         "id": "covil_" + cv["id"], "name": "CV_MAP_" + cv["id"].upper(), "size": [40, 44], "seed": 300 + len(cv["id"]),
         "covil": cv["id"], "loading": "load_" + cv["style"]}
    for k in ("ground", "indoor", "sky", "ambient", "ambient_color", "sun", "sun_color", "patches", "biome"):
        if k in st:
            m[k] = st[k]
    m["spawns"] = {"start": [0, 15, 0]}
    m["exits"] = [{"to": "__return", "spawn": "start", "pos": [0, 19.5], "size": [6, 2], "label": "CV_EXIT"}]
    # An eight-sided arena; the entrance (south) closes while the boss fights.
    r = 15.0
    pts = [(-6, 18), (-14, 12), (-17, 0), (-14, -12), (-6, -17), (6, -17), (14, -12), (17, 0), (14, 12), (6, 18)]
    walls = []
    for a, b in zip(pts, pts[1:]):
        w = {"from": [a[0], a[1]], "to": [b[0], b[1]]}
        if st.get("wall"):
            w["id"] = st["wall"]
        walls.append(w)
    walls.append(dict({"from": [-6, 18], "to": [-3, 18]}, **({"id": st["wall"]} if st.get("wall") else {})))
    walls.append(dict({"from": [3, 18], "to": [6, 18]}, **({"id": st["wall"]} if st.get("wall") else {})))
    m["walls"] = walls
    m["arena"] = {"gate": [[-3, 17.4], [3, 17.4]]}
    props = []
    # Along the walls (two rings) and a pair framing the boss.
    spots = [(-12, -8), (12, -8), (-12, 6), (12, 6), (-7, -13), (7, -13), (-13, -1), (13, -1),
             (-10, 12), (10, 12), (-3, -15), (3, -15), (-14.5, 3), (14.5, 3), (-14.5, -5), (14.5, -5),
             (-4, -10), (4, -10)]
    for i, (x, z) in enumerate(spots):
        props.append({"id": st["props"][i % len(st["props"])], "pos": [x, z]})
    m["props"] = props
    m["paths"] = [{"points": [[0, 19], [0, -6]], "width": 2.6, "color": st["patches"]["color"]}]
    m["bosses"] = [{"id": cv["boss"], "pos": [0, -7], "level": cv["boss_level"], "yaw": 0, "covil": cv["id"]}]
    # A few helpers with the boss; they do not come back (respawn: an hour).
    m["enemy_zones"] = [{"pos": [0, -4], "radius": 6, "max": 3, "types": {e: 1 for e in cv["minions"]},
                         "level": [cv["boss_level"] - 2, cv["boss_level"] - 1], "respawn": 3600}]
    return m


def write_texts(texts: dict) -> None:
    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body, seen = rows[0], [], set()
    for r in rows[1:]:
        if not r or r[0].startswith("CV_") or r[0] in seen:
            continue
        seen.add(r[0])
        body.append(r)
    for key, (pt, en) in texts.items():
        body.append([key, pt, en])
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(header)
    w.writerows(body)
    cpath.write_text(buf.getvalue(), encoding="utf-8")


def main() -> None:
    ipath = ROOT / "data" / "items" / "items.json"
    items_doc = json.loads(ipath.read_text(encoding="utf-8"))
    new_items, new_sets, texts = build_items(items_doc)
    write_items(ipath, new_items, new_sets)
    json.loads(ipath.read_text(encoding="utf-8"))
    covis = dict(RULES)
    covis["covis"] = {}
    for cv in COVIS:
        covis["covis"][cv["id"]] = {"city": cv["city"], "boss": cv["boss"], "level": cv["level"], "unlock": cv["unlock"],
                                   "set": cv["set"], "map": "covil_" + cv["id"], "color": cv["color"],
                                   "frag": "mat_frag_" + cv["id"], "ess": "mat_ess_" + cv["id"],
                                   "pieces": {s: [piece_id(s, cv, "raro"), piece_id(s, cv, "epico")] for s in SLOTS}}
        texts["CV_MAP_" + cv["id"].upper()] = ("Covil do %s" % cv["boss_pt"] if cv["id"] not in ("sahra", "velyra") else "Covil da %s" % cv["boss_pt"],
                                              "%s's Lair" % cv["boss_pt"])
        mpath = ROOT / "data" / "maps" / ("covil_%s.json" % cv["id"])
        json_compact.write(str(mpath), build_map(cv))
    json_compact.write(str(ROOT / "data" / "world" / "covis.json"), covis)
    texts["CV_EXIT"] = ("Sair do covil", "Leave the lair")
    texts.update(UI_TEXTS)
    write_texts(texts)
    print("ok: %d covis, %d textos" % (len(COVIS), len(texts)))


if __name__ == "__main__":
    main()
