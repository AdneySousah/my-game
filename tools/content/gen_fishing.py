#!/usr/bin/env python3
"""Fase 8D — Pesca e fogueira (pedido do dono, 13/11/2026).

Gera, a partir das tabelas abaixo:
  - data/world/fishing.json       peixes por água e hora, regras da pesca e receitas da fogueira
  - data/items/items.json         peixes, ingredientes e comidas (troca só os daqui)
  - data/enemies/enemies.json     ingredientes nos drops (entradas com "gen": "fishing")
  - data/shop/shop.json           ingredientes nos comerciantes (entradas com "gen": "fishing")
  - data/i18n/strings.csv         chaves FS_* (troca só as dele)

Rodar:  python -X utf8 tools/content/gen_fishing.py
"""
import csv
import io
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import json_compact  # noqa: E402
from gen_covis import write_items  # noqa: E402

# Fish: difficulty ("pull" = how hard it fights, "reel" = seconds of reeling at best).
FISH = {
    "peixe_tilapia": {"pt": "Tilápia Dourada", "en": "Golden Tilapia", "rarity": "common", "price": 25, "pull": 0.5, "reel": 2.5},
    "peixe_truta": {"pt": "Truta Prateada", "en": "Silver Trout", "rarity": "common", "price": 35, "pull": 0.65, "reel": 3.0},
    "peixe_carpa": {"pt": "Carpa Real", "en": "Royal Carp", "rarity": "rare", "price": 60, "pull": 0.75, "reel": 3.5},
    "peixe_bagre": {"pt": "Bagre do Pântano", "en": "Swamp Catfish", "rarity": "rare", "price": 60, "pull": 0.85, "reel": 3.5},
    "peixe_lua": {"pt": "Peixe-Lua", "en": "Moonfish", "rarity": "epic", "price": 150, "pull": 0.9, "reel": 4.0},
    "peixe_gelo": {"pt": "Peixe de Gelo", "en": "Ice Fish", "rarity": "epic", "price": 150, "pull": 1.0, "reel": 4.0},
    "peixe_sol": {"pt": "Peixe-Sol Lendário", "en": "Legendary Sunfish", "rarity": "legendary", "price": 1200, "pull": 1.25, "reel": 5.0},
}
# Waters: which fish bite (weights; "night": only from 19h to 6h).
POOLS = {
    "rio": [["peixe_tilapia", 50], ["peixe_truta", 35], ["peixe_lua", 12, "night"]],
    "lago": [["peixe_tilapia", 45], ["peixe_carpa", 35], ["peixe_lua", 15, "night"]],
    "oasis": [["peixe_tilapia", 50], ["peixe_carpa", 40], ["peixe_lua", 15, "night"]],
    "pantano": [["peixe_bagre", 55], ["peixe_tilapia", 25], ["peixe_lua", 20, "night"]],
    "gelo": [["peixe_truta", 50], ["peixe_gelo", 35], ["peixe_lua", 10, "night"]],
}
MAPS = {"pradoluz": "lago", "floresta": "rio", "qaressa": "oasis", "dunas": "oasis", "bordas_pantano": "pantano",
        "pantano": "pantano", "vale_degelo": "gelo"}
RULES = {
    "_comment": "Pesca e fogueira (Fase 8D). Gerado por tools/content/gen_fishing.py; não editar à mão. Perto da água (reach m da margem), fora de luta, o Atacar vira 'Pescar'. bite: segundos até o peixe morder; react: segundos para fisgar. Puxar: segurar Atacar enche o progresso (1/reel por s) e a tensão (tension_up × pull); soltar baixa a tensão (tension_down); o peixe dá puxões (surge). Tensão cheia arrebenta a linha. legendary: chance do peixe lendário (de dia, qualquer água). Comidas: 1 por vez, os bônus valem 'minutes' minutos.",
    "reach": 2.2,
    "bite": [2.5, 6.0],
    "react": 1.0,
    "tension_up": 0.42,
    "tension_down": 0.6,
    "surge": [0.08, 0.2],
    "legendary": {"fish": "peixe_sol", "chance": 0.015},
}
INGREDIENTS = {
    "erva_silvestre": {"pt": "Erva Silvestre", "en": "Wild Herbs", "price": 8},
    "carne_crua": {"pt": "Carne Crua", "en": "Raw Meat", "price": 10},
    "cogumelo": {"pt": "Cogumelo da Mata", "en": "Forest Mushroom", "price": 10},
}
# Dishes: ingredients (any common fish = "peixe_comum"), bonus (stat -> value) and minutes.
DISHES = [
    {"id": "comida_peixe_assado", "pt": "Peixe Assado", "en": "Grilled Fish", "needs": {"peixe_comum": 1},
     "bonus": {"max_hp_pct": 0.08}, "min": 10, "rarity": "common", "fx_pt": "+8% de vida máxima", "fx_en": "+8% max health"},
    {"id": "comida_espeto_carne", "pt": "Espeto de Carne", "en": "Meat Skewer", "needs": {"carne_crua": 2},
     "bonus": {"atk_pct": 0.08}, "min": 10, "rarity": "common", "fx_pt": "+8% de ataque", "fx_en": "+8% attack"},
    {"id": "comida_sopa_cogumelo", "pt": "Sopa de Cogumelos", "en": "Mushroom Soup", "needs": {"cogumelo": 2, "erva_silvestre": 1},
     "bonus": {"mp_regen_pct": 0.3}, "min": 10, "rarity": "common", "fx_pt": "+30% de recuperação de MP", "fx_en": "+30% MP regeneration"},
    {"id": "comida_ensopado_peixe", "pt": "Ensopado de Peixe", "en": "Fish Stew", "needs": {"peixe_comum": 2, "erva_silvestre": 1},
     "bonus": {"def_pct": 0.1, "max_hp_pct": 0.05}, "min": 10, "rarity": "rare", "fx_pt": "+10% de defesa e +5% de vida", "fx_en": "+10% defense and +5% health"},
    {"id": "comida_truta_ervas", "pt": "Truta com Ervas", "en": "Herb Trout", "needs": {"peixe_truta": 1, "erva_silvestre": 2},
     "bonus": {"max_stamina_pct": 0.2}, "min": 10, "rarity": "rare", "fx_pt": "+20% de fôlego", "fx_en": "+20% stamina"},
    {"id": "comida_bagre_picante", "pt": "Bagre Picante", "en": "Spicy Catfish", "needs": {"peixe_bagre": 1, "carne_crua": 1},
     "bonus": {"crit_chance": 0.06}, "min": 10, "rarity": "rare", "fx_pt": "+6% de chance de crítico", "fx_en": "+6% critical chance"},
    {"id": "comida_peixe_lua", "pt": "Peixe-Lua Glaceado", "en": "Glazed Moonfish", "needs": {"peixe_lua": 1, "erva_silvestre": 1},
     "bonus": {"skill_dmg": 0.15}, "min": 10, "rarity": "epic", "fx_pt": "+15% de dano das skills", "fx_en": "+15% skill damage"},
    {"id": "comida_sopa_gelo", "pt": "Sopa Gelada", "en": "Frost Soup", "needs": {"peixe_gelo": 1, "cogumelo": 1},
     "bonus": {"def_pct": 0.15}, "min": 10, "rarity": "epic", "fx_pt": "+15% de defesa", "fx_en": "+15% defense"},
    {"id": "comida_banquete_sol", "pt": "Banquete do Sol", "en": "Sun Feast", "needs": {"peixe_sol": 1, "carne_crua": 1, "cogumelo": 1, "erva_silvestre": 1},
     "bonus": {"all_pct": 0.1}, "min": 20, "rarity": "legendary", "fx_pt": "+10% em todos os status", "fx_en": "+10% to every stat"},
]
DISH_ICON = {"comida_peixe_assado": "comida_peixe_assado", "comida_espeto_carne": "comida_espeto_carne"}
# Monsters that drop ingredients (chance).
DROPS = {
    "orc": [("carne_crua", 0.3)], "orc_saqueador": [("carne_crua", 0.3)], "orc_neve": [("carne_crua", 0.3)],
    "homem_lagarto": [("carne_crua", 0.25)], "lagarto_pantano": [("carne_crua", 0.25), ("cogumelo", 0.15)],
    "bandido": [("erva_silvestre", 0.2)], "bandido_estrada": [("erva_silvestre", 0.2)], "bandido_deserto": [("erva_silvestre", 0.15)],
    "arqueiro": [("erva_silvestre", 0.2)], "esqueleto": [("cogumelo", 0.2)], "esqueleto_antigo": [("cogumelo", 0.2)],
    "morto_pantano": [("cogumelo", 0.25)], "morto_gelo": [("cogumelo", 0.15)], "cultista": [("erva_silvestre", 0.2)],
}
SHOP = [("erva_silvestre", 20), ("cogumelo", 25), ("carne_crua", 30)]

UI_TEXTS = {
    "FS_FISH": ("Pescar", "Fish"), "FS_WAIT": ("Esperando o peixe morder...", "Waiting for a bite..."),
    "FS_NOW": ("Agora! Toque em Atacar!", "Now! Tap Attack!"),
    "FS_REEL": ("Segure Atacar para puxar. Solte se a linha ficar vermelha!", "Hold Attack to reel. Let go if the line turns red!"),
    "FS_GOT": ("Pescou: %s!", "Caught: %s!"), "FS_ESCAPED": ("O peixe escapou...", "The fish got away..."),
    "FS_SNAPPED": ("A linha arrebentou!", "The line snapped!"), "FS_NOTHING": ("Nada mordeu.", "Nothing bit."),
    "FS_COOK": ("Cozinhar", "Cook"), "FS_COOK_TITLE": ("Fogueira", "Campfire"),
    "FS_COOK_INFO": ("Cozinhe com peixes e ingredientes. Uma comida por vez: a nova troca a anterior.", "Cook with fish and ingredients. One meal at a time: a new one replaces the old."),
    "FS_EAT": ("Comer", "Eat"), "FS_EATEN": ("Você comeu %s.", "You ate %s."),
    "FS_ACTIVE": ("Comida ativa: %s (%s)", "Active meal: %s (%s)"), "FS_NO_ACTIVE": ("Nenhuma comida ativa.", "No active meal."),
    "FS_ANY_FISH": ("Peixe comum", "Common fish"), "FS_MINUTES": ("%d min", "%d min"),
    "FS_PEIXE_COMUM_DESC": ("Tilápia, truta, carpa ou bagre.", "Tilapia, trout, carp or catfish."),
}


def build() -> tuple:
    items, texts = {}, {}
    for fid, f in FISH.items():
        items[fid] = {"name": "FS_ITEM_" + fid.upper(), "desc": "FS_ITEM_FISH_DESC", "type": "fish", "rarity": f["rarity"],
                      "stack": 99, "price": f["price"], "color": "#5aa8d8", "glyph": "f"}
        texts["FS_ITEM_" + fid.upper()] = (f["pt"], f["en"])
    texts["FS_ITEM_FISH_DESC"] = ("Um peixe fresco. Venda ou leve para a fogueira.", "A fresh fish. Sell it or take it to a campfire.")
    for iid, g in INGREDIENTS.items():
        items[iid] = {"name": "FS_ITEM_" + iid.upper(), "desc": "FS_ITEM_ING_DESC", "type": "material", "rarity": "common",
                      "stack": 99, "price": g["price"], "color": "#8ab04a", "glyph": "i"}
        texts["FS_ITEM_" + iid.upper()] = (g["pt"], g["en"])
    texts["FS_ITEM_ING_DESC"] = ("Ingrediente para cozinhar na fogueira.", "An ingredient to cook at a campfire.")
    for d in DISHES:
        key = "FS_ITEM_" + d["id"].upper()
        items[d["id"]] = {"name": key, "desc": key + "_DESC", "type": "food", "rarity": d["rarity"], "stack": 20,
                          "price": 0, "color": "#e0a050", "glyph": "c", "food": {"bonus": d["bonus"], "minutes": d["min"]}}
        texts[key] = (d["pt"], d["en"])
        texts[key + "_DESC"] = ("%s por %d min." % (d["fx_pt"], d["min"]), "%s for %d min." % (d["fx_en"], d["min"]))
    texts.update(UI_TEXTS)
    return items, texts


def write_enemies() -> None:
    path = ROOT / "data" / "enemies" / "enemies.json"
    s = path.read_text(encoding="utf-8")
    s = re.sub(r'\n[ \t]*\{"item": "[a-z_]+", "chance": [0-9.]+, "count": 1, "gen": "fishing"\},', "", s)
    data = json.loads(s)["enemies"]
    for eid, drops in DROPS.items():
        assert eid in data, eid
        m = re.search(r'\n\s*"%s":\s*\{' % re.escape(eid), s)
        d = s.index('"drops": [', m.end())
        at = d + len('"drops": [')
        # One entry per line, with the indent of the list's own items.
        line_start = s.rfind("\n", 0, d) + 1
        indent = re.match(r"[ \t]*", s[line_start:]).group(0) + "  "
        ins = "".join('\n%s{"item": "%s", "chance": %s, "count": 1, "gen": "fishing"},' % (indent, i, c) for i, c in drops)
        s = s[:at] + ins + s[at:]
    json.loads(s)
    path.write_text(s, encoding="utf-8")


def write_shop() -> None:
    path = ROOT / "data" / "shop" / "shop.json"
    s = path.read_text(encoding="utf-8")
    s = re.sub(r'\{"id": "[a-z_]+", "buy": [0-9]+, "gen": "fishing"\}, ', "", s)
    ins = "".join('{"id": "%s", "buy": %d, "gen": "fishing"}, ' % (i, b) for i, b in SHOP)
    s = s.replace('"goods": [', '"goods": [' + ins)
    json.loads(s)
    path.write_text(s, encoding="utf-8")


def write_texts(texts: dict) -> None:
    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body, seen = rows[0], [], set()
    for r in rows[1:]:
        if not r or r[0].startswith("FS_") or r[0] in seen:
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
    items, texts = build()
    write_items(ROOT / "data" / "items" / "items.json", items, {})
    rules = dict(RULES)
    rules["fish"] = {k: {"pull": v["pull"], "reel": v["reel"]} for k, v in FISH.items()}
    rules["common_fish"] = ["peixe_tilapia", "peixe_truta", "peixe_carpa", "peixe_bagre"]
    rules["pools"] = POOLS
    rules["maps"] = MAPS
    rules["recipes"] = [{"id": d["id"], "needs": d["needs"]} for d in DISHES]
    json_compact.write(str(ROOT / "data" / "world" / "fishing.json"), rules)
    write_enemies()
    write_shop()
    write_texts(texts)
    print("ok: %d itens, %d textos" % (len(items), len(texts)))


if __name__ == "__main__":
    main()
