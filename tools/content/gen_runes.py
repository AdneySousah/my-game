#!/usr/bin/env python3
"""Fase 8C — Runas e elementos (pedido do dono, 13/11/2026).

Gera, a partir das tabelas abaixo:
  - data/skills/runes.json        regras das 6 runas (3 níveis), elementos, fusão e quedas
  - data/items/items.json         itens runa_<tipo>_<nível> (troca só os daqui)
  - data/enemies/enemies.json     "weak" / "resist" / "undead" de cada inimigo
  - data/i18n/strings.csv         chaves RN_* (troca só as dele)

Rodar:  python -X utf8 tools/content/gen_runes.py
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

ROMAN = ["I", "II", "III"]

RUNES = {
    "fogo": {"element": "fogo", "color": "#ff7a2a", "pt": "Runa de Fogo", "en": "Fire Rune",
             "desc_pt": "A skill deixa o chão queimando por %s s (%s%% do ataque a cada meio segundo).",
             "desc_en": "The skill leaves the ground burning for %s s (%s%% of attack every half second).",
             "levels": [{"dps": 0.12, "radius": 2.4, "time": 3.0}, {"dps": 0.18, "radius": 2.6, "time": 3.5}, {"dps": 0.25, "radius": 2.8, "time": 4.0}]},
    "gelo": {"element": "gelo", "color": "#8fd8ff", "pt": "Runa de Gelo", "en": "Ice Rune",
             "desc_pt": "Deixa os inimigos lentos e tem %s%% de chance de congelar por 1 s.",
             "desc_en": "Slows enemies and has a %s%% chance to freeze them for 1 s.",
             "levels": [{"slow": 0.4, "time": 3.0, "freeze": 0.15}, {"slow": 0.45, "time": 3.0, "freeze": 0.25}, {"slow": 0.5, "time": 3.5, "freeze": 0.35}]},
    "raio": {"element": "raio", "color": "#ffe04a", "pt": "Runa de Raio", "en": "Lightning Rune",
             "desc_pt": "Cada acerto salta para mais %s inimigos com %s%% do dano.",
             "desc_en": "Each hit jumps to %s more enemies with %s%% of the damage.",
             "levels": [{"chains": 2, "mult": 0.3, "range": 5.0}, {"chains": 3, "mult": 0.4, "range": 5.5}, {"chains": 4, "mult": 0.5, "range": 6.0}]},
    "sangue": {"element": "", "color": "#d0304a", "pt": "Runa de Sangue", "en": "Blood Rune",
               "desc_pt": "Cura %s%% do dano que a skill causa.",
               "desc_en": "Heals %s%% of the damage the skill deals.",
               "levels": [{"heal": 0.06}, {"heal": 0.09}, {"heal": 0.12}]},
    "luz": {"element": "luz", "color": "#fff2b0", "pt": "Runa de Luz", "en": "Light Rune",
            "desc_pt": "+%s%% de dano em chefes e em mortos-vivos.",
            "desc_en": "+%s%% damage to bosses and the undead.",
            "levels": [{"bonus": 0.25}, {"bonus": 0.4}, {"bonus": 0.6}]},
    "eco": {"element": "", "color": "#b07aff", "pt": "Runa do Eco", "en": "Echo Rune",
            "desc_pt": "Um eco da skill acerta de novo com %s%% do dano.",
            "desc_en": "An echo of the skill hits again with %s%% of the damage.",
            "levels": [{"mult": 0.4, "delay": 0.5}, {"mult": 0.55, "delay": 0.5}, {"mult": 0.7, "delay": 0.5}]},
}

RULES = {
    "_comment": "Runas e elementos (Fase 8C). Gerado por tools/content/gen_runes.py; não editar à mão. Cada skill tem 1 encaixe de runa (Session.skill_runes). merge runas iguais viram 1 do nível seguinte. Elemento da skill = o da runa: em inimigo com 'weak' igual, dano × weak_mult; com 'resist' igual, × resist_mult. Quedas: chance de 1 runa nível 1 (level2_chance de vir nível 2) por chefe da história (boss), chefe de covil (covil), Procurado (wanted), missão do quadro (board) e monstro comum (mob).",
    "merge": 3,
    "weak_mult": 1.5,
    "resist_mult": 0.6,
    "drops": {"boss": 0.6, "covil": 0.3, "wanted": 1.0, "board": 0.3, "mob": 0.004, "level2_chance": 0.12},
}

# Weakness / resistance of every enemy (by kind). undead: Light rune bonus.
UNDEAD = {"esqueleto", "esqueleto_antigo", "morto_gelo", "morto_pantano"}
ELEMENTS = {
    "bandido": ("raio", ""), "bandido_estrada": ("raio", ""), "arqueiro": ("raio", ""), "bandido_deserto": ("gelo", "fogo"),
    "orc": ("fogo", ""), "orc_saqueador": ("fogo", ""), "orc_neve": ("fogo", "gelo"),
    "esqueleto": ("luz", "gelo"), "esqueleto_antigo": ("luz", "gelo"),
    "golem": ("gelo", "raio"), "golem_gelo": ("fogo", "gelo"), "guardiao_gelo": ("fogo", "gelo"),
    "gorvan": ("fogo", "gelo"), "espantalho": ("fogo", "gelo"), "procurado_pradoluz": ("gelo", "raio"),
    "homem_lagarto": ("gelo", "fogo"), "sahra": ("gelo", "fogo"), "sahra_areia": ("gelo", "fogo"), "procurado_qaressa": ("gelo", "fogo"),
    "morto_gelo": ("fogo", "gelo"), "brannoc": ("fogo", "gelo"), "brannoc_gelo": ("fogo", "gelo"), "procurado_hrimvald": ("fogo", "gelo"),
    "lagarto_pantano": ("fogo", "raio"), "morto_pantano": ("luz", "raio"), "guardiao_espinhos": ("fogo", "raio"),
    "velyra": ("fogo", "raio"), "velyra_driade": ("fogo", "raio"), "procurado_lysthael": ("fogo", "raio"),
    "cultista": ("luz", "fogo"), "guarda_lei": ("raio", "luz"), "arqueiro_lei": ("raio", "luz"), "carcereiro": ("raio", ""),
    "cassian": ("raio", "luz"), "cassian_colosso": ("raio", "luz"), "procurado_altarea": ("raio", "luz"),
    "sentinela_celeste": ("raio", "luz"), "vigia_celeste": ("raio", "luz"),
    "vaelor": ("raio", "luz"), "vaelor_desmascarado": ("raio", "luz"), "vaelor_corrompido": ("luz", "raio"),
    "severin": ("", ""), "severin_2": ("", ""), "severin_3": ("", ""),
}
ELEMENT_PT = {"fogo": ("Fogo", "Fire"), "gelo": ("Gelo", "Ice"), "raio": ("Raio", "Lightning"), "luz": ("Luz", "Light")}

UI_TEXTS = {
    "RN_SOCKET": ("Runa da skill", "Skill rune"),
    "RN_EMPTY": ("Sem runa. Toque numa runa abaixo para encaixar.", "No rune. Tap a rune below to set it."),
    "RN_NONE_OWNED": ("Você ainda não tem runas. Elas caem de chefes, Procurados, covis e do quadro de missões.", "You have no runes yet. They drop from bosses, wanted bosses, lairs and the quest board."),
    "RN_REMOVE": ("Tirar runa", "Remove rune"),
    "RN_MERGE": ("Fundir 3", "Merge 3"),
    "RN_WEAK": ("Fraco!", "Weak!"),
    "RN_RESIST": ("Resiste", "Resists"),
    "RN_ELEMENT": ("Elemento: %s", "Element: %s"),
    "RN_FROZEN": ("Congelado!", "Frozen!"),
}


def item_id(kind: str, lvl: int) -> str:
    return "runa_%s_%d" % (kind, lvl)


def desc_args(kind: str, lv: dict) -> tuple:
    if kind == "fogo":
        return (("%g" % lv["time"]), str(round(lv["dps"] * 100)))
    if kind == "gelo":
        return (str(round(lv["freeze"] * 100)),)
    if kind == "raio":
        return (str(lv["chains"]), str(round(lv["mult"] * 100)))
    if kind == "sangue":
        return (str(round(lv["heal"] * 100)),)
    if kind == "luz":
        return (str(round(lv["bonus"] * 100)),)
    return (str(round(lv["mult"] * 100)),)


def build() -> tuple:
    items, texts = {}, {}
    for kind, r in RUNES.items():
        for i, lv in enumerate(r["levels"]):
            n = i + 1
            iid = item_id(kind, n)
            items[iid] = {"name": "RN_ITEM_%s_%d" % (kind.upper(), n), "desc": "RN_ITEM_%s_%d_DESC" % (kind.upper(), n),
                          "type": "rune", "rarity": ["rare", "epic", "legendary"][i], "stack": 99,
                          "price": [80, 300, 1000][i], "color": r["color"], "glyph": "R", "icon": "runa_" + kind,
                          "rune": kind, "rune_level": n}
            texts["RN_ITEM_%s_%d" % (kind.upper(), n)] = ("%s %s" % (r["pt"], ROMAN[i]), "%s %s" % (r["en"], ROMAN[i]))
            a = desc_args(kind, lv)
            texts["RN_ITEM_%s_%d_DESC" % (kind.upper(), n)] = (r["desc_pt"] % a, r["desc_en"] % a)
    for el, (pt, en) in ELEMENT_PT.items():
        texts["RN_EL_" + el.upper()] = (pt, en)
    texts.update(UI_TEXTS)
    return items, texts


def write_enemies() -> None:
    path = ROOT / "data" / "enemies" / "enemies.json"
    s = path.read_text(encoding="utf-8")
    # Take out what this script wrote before.
    s = re.sub(r'"weak": "[a-z]*", "resist": "[a-z]*", ("undead": true, )?', "", s)
    data = json.loads(s)["enemies"]
    missing = [k for k in data if k not in ELEMENTS]
    if missing:
        raise SystemExit("faltam elementos para: %s" % missing)
    for eid, (weak, resist) in ELEMENTS.items():
        m = re.search(r'\n\s*"%s":\s*\{' % re.escape(eid), s)
        if not m:
            raise SystemExit("inimigo não achado: " + eid)
        ins = '"weak": "%s", "resist": "%s", %s' % (weak, resist, '"undead": true, ' if eid in UNDEAD else "")
        s = s[:m.end()] + ins + s[m.end():]
    json.loads(s)
    path.write_text(s, encoding="utf-8")


def write_texts(texts: dict) -> None:
    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body, seen = rows[0], [], set()
    for r in rows[1:]:
        if not r or r[0].startswith("RN_") or r[0] in seen:
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
    rules["runes"] = {k: {"element": v["element"], "color": v["color"], "levels": v["levels"]} for k, v in RUNES.items()}
    json_compact.write(str(ROOT / "data" / "skills" / "runes.json"), rules)
    write_enemies()
    write_texts(texts)
    print("ok: %d runas, %d textos" % (len(items), len(texts)))


if __name__ == "__main__":
    main()
