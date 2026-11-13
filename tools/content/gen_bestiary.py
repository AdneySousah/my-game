#!/usr/bin/env python3
"""Fase 8E — Bestiário e Maestria (pedido do dono, 13/11/2026).

Gera:
  - data/world/bestiary.json   uma ficha por monstro (ordem, família, marcos de abates, bônus,
                               onde aparece — tirado dos mapas) e as regras da Maestria
  - data/i18n/strings.csv      chaves BS_* (troca só as dele)

Rodar:  python -X utf8 tools/content/gen_bestiary.py
"""
import csv
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import json_compact  # noqa: E402

# Display order and family of each monster (forms of a boss count for the boss).
ORDER = [
    ("bandido", "bandidos"), ("arqueiro", "arqueiros"), ("orc", "orcs"), ("esqueleto", "esqueletos"),
    ("bandido_estrada", "bandidos"), ("orc_saqueador", "orcs"), ("golem", "golens"), ("gorvan", "gorvan"),
    ("bandido_deserto", "bandidos"), ("homem_lagarto", "lagartos"), ("esqueleto_antigo", "esqueletos"), ("severin", "severin"),
    ("sahra", "sahra"), ("orc_neve", "orcs"), ("morto_gelo", "mortos"), ("golem_gelo", "golens"),
    ("guardiao_gelo", "guardioes"), ("brannoc", "brannoc"), ("lagarto_pantano", "lagartos"), ("morto_pantano", "mortos"),
    ("cultista", "cultistas"), ("guardiao_espinhos", "guardioes"), ("velyra", "velyra"), ("guarda_lei", "guardas"),
    ("arqueiro_lei", "guardas"), ("carcereiro", "guardas"), ("cassian", "cassian"), ("sentinela_celeste", "celestes"),
    ("vigia_celeste", "celestes"), ("vaelor", "vaelor"),
    ("procurado_pradoluz", "procurados"), ("procurado_qaressa", "procurados"), ("procurado_hrimvald", "procurados"),
    ("procurado_lysthael", "procurados"), ("procurado_altarea", "procurados"),
]
FORMS = {"espantalho": "gorvan", "sahra_areia": "sahra", "brannoc_gelo": "brannoc", "velyra_driade": "velyra",
         "cassian_colosso": "cassian", "vaelor_desmascarado": "vaelor", "vaelor_corrompido": "vaelor",
         "severin_2": "severin", "severin_3": "severin"}
FAMILY_TEXT = {
    "bandidos": ("Gente que perdeu tudo para os Arautos e resolveu tirar dos outros. Fogem quando a luta aperta.", "People who lost everything to the Heralds and now take from others. They run when the fight turns."),
    "arqueiros": ("Atiram de longe e rolam para o lado depois de cada flecha. Chegue perto rápido.", "They shoot from afar and roll aside after each arrow. Close in fast."),
    "orcs": ("Fortes e lentos. O golpe no chão avisa antes: saia do círculo.", "Strong and slow. Their ground slam warns you first: step out of the circle."),
    "esqueletos": ("Mineiros e soldados que nunca descansaram. A luz os desfaz.", "Miners and soldiers who never found rest. Light undoes them."),
    "golens": ("Pedra e gelo que ganharam vida perto das minas. Batem devagar, mas muito forte.", "Stone and ice brought to life near the mines. Slow blows, but very hard ones."),
    "guardioes": ("Sentinelas antigas que protegem o caminho até um Arauto.", "Ancient sentinels guarding the way to a Herald."),
    "lagartos": ("Caçadores rápidos do deserto e do pântano. Avançam em linha reta com a lança.", "Quick hunters of the desert and the swamp. They charge straight with the spear."),
    "mortos": ("Os que o frio ou a lama não deixaram partir. O fogo e a luz os assustam.", "Those the cold or the mud would not let go. Fire and light scare them."),
    "cultistas": ("Seguidores da fé no Soberano. Lançam esferas de energia de longe.", "Followers of the faith in the Sovereign. They throw energy orbs from afar."),
    "guardas": ("A lei de ferro da capital: escudos, flechas e grilhões.", "The capital's iron law: shields, arrows and shackles."),
    "celestes": ("Soldados de luz da Cidadela. O raio atravessa a armadura deles.", "Soldiers of light from the Citadel. Lightning goes through their armor."),
    "procurados": ("Feras marcadas no cartaz de Procurado da cidade. Um por dia, sempre mais forte que você.", "Beasts on the city's Wanted poster. One a day, always stronger than you."),
    "gorvan": ("Arauto da Colheita. Tomou o trigo de Pradoluz e virou um espantalho gigante.", "Herald of the Harvest. Took Pradoluz's wheat and became a giant scarecrow."),
    "severin": ("O cavaleiro da lei que caça Lio pelo continente. Rival, nunca inimigo de verdade.", "The knight of the law who hunts Lio across the land. A rival, never truly an enemy."),
    "sahra": ("Arauta da Areia. Vendia a água de Qaressa a peso de ouro.", "Herald of the Sand. Sold Qaressa's water for its weight in gold."),
    "brannoc": ("Arauto do Frio. Deixou Hrimvald congelar para provar sua força.", "Herald of the Cold. Let Hrimvald freeze to prove his strength."),
    "velyra": ("Arauta do Silêncio. Proibiu as canções de Lys'Thaël.", "Herald of Silence. Forbade the songs of Lys'Thaël."),
    "cassian": ("Arauto da Lei. Transformou a capital numa prisão.", "Herald of the Law. Turned the capital into a prison."),
    "vaelor": ("O Soberano Alado, que se declarou deus. Há um segredo por trás da máscara.", "The Winged Sovereign, who called himself a god. There is a secret behind the mask."),
}
NORMAL = {"kills": [50, 200, 1000], "bonus": [0.02, 0.04, 0.06]}
BOSS = {"kills": [1, 5, 20], "bonus": [0.02, 0.04, 0.06]}
MASTERY = {
    "_comment": "Depois do nível máximo a XP enche a barra da Maestria: cada xp_per_point_mult × a XP do último nível vale 1 ponto, gasto num dos ramos (sem limite).",
    "xp_per_point_mult": 1.0,
    "branches": {
        "atk": {"stat": "atk_pct", "per": 0.01, "pt": "Ataque", "en": "Attack", "fx_pt": "+1% de ataque por ponto", "fx_en": "+1% attack per point"},
        "def": {"stat": "def_pct", "per": 0.01, "pt": "Defesa", "en": "Defense", "fx_pt": "+1% de defesa por ponto", "fx_en": "+1% defense per point"},
        "hp": {"stat": "max_hp_pct", "per": 0.01, "pt": "Vida", "en": "Health", "fx_pt": "+1% de vida máxima por ponto", "fx_en": "+1% max health per point"},
        "util": {"stat": "crit_chance", "per": 0.004, "pt": "Precisão", "en": "Precision", "fx_pt": "+0,4% de chance de crítico por ponto", "fx_en": "+0.4% critical chance per point"},
    },
}
UI_TEXTS = {
    "BS_TITLE": ("Bestiário", "Bestiary"), "BS_UNKNOWN": ("???", "???"),
    "BS_UNKNOWN_TEXT": ("Ainda não enfrentado. Derrote um para conhecer.", "Not met yet. Defeat one to learn about it."),
    "BS_KILLS": ("Derrotados: %d", "Defeated: %d"), "BS_NEXT": ("Próximo marco: %d (+%d%% de dano contra ele)", "Next mark: %d (+%d%% damage against it)"),
    "BS_MAXED": ("Todos os marcos alcançados.", "Every mark reached."), "BS_BONUS": ("Bônus: +%d%% de dano contra ele", "Bonus: +%d%% damage against it"),
    "BS_WHERE": ("Onde aparece: %s", "Where: %s"), "BS_WEAK": ("Fraco a: %s", "Weak to: %s"), "BS_RESIST": ("Resiste a: %s", "Resists: %s"),
    "BS_NONE": ("nada", "nothing"), "BS_HIDDEN": ("Fraqueza: derrote mais para descobrir.", "Weakness: defeat more to find out."),
    "BS_PROGRESS": ("%d de %d conhecidos", "%d of %d known"),
    "BS_MASTERY": ("Maestria", "Mastery"),
    "BS_MASTERY_LOCKED": ("A Maestria abre no nível %d. Depois dele, a XP continua valendo pontos para sempre.", "Mastery opens at level %d. After it, XP keeps turning into points forever."),
    "BS_MASTERY_INFO": ("Cada barra cheia de XP dá 1 ponto. Escolha onde gastar:", "Each full XP bar gives 1 point. Choose where to spend it:"),
    "BS_MASTERY_POINTS": ("Pontos para gastar: %d", "Points to spend: %d"), "BS_MASTERY_RANK": ("Nível %d · agora %s", "Rank %d · now %s"),
}


def where_map() -> dict:
    out = {}
    names = {}
    for f in sorted((ROOT / "data" / "maps").glob("*.json")):
        m = json.loads(f.read_text(encoding="utf-8"))
        mid = m.get("id", f.stem)
        if mid.startswith("interior_") or mid.startswith("covil_"):
            continue
        names[mid] = m.get("name", mid)
        found = set()
        for z in m.get("enemy_zones", []):
            found |= set(z.get("types", {}).keys())
        for b in m.get("bosses", []):
            found.add(b.get("id", ""))
        for e in found:
            root = FORMS.get(e, e)
            out.setdefault(root, [])
            if mid not in out[root]:
                out[root].append(mid)
    boards = json.loads((ROOT / "data" / "world" / "boards.json").read_text(encoding="utf-8"))
    for city, w in boards.get("wanted", {}).items():
        if isinstance(w, dict) and "enemy" in w:
            out.setdefault(w["enemy"], []).extend([mm for mm in w.get("maps", []) if mm not in out.get(w["enemy"], [])])
    return out


def main() -> None:
    enemies = json.loads((ROOT / "data" / "enemies" / "enemies.json").read_text(encoding="utf-8"))["enemies"]
    places = where_map()
    entries = []
    texts = dict(UI_TEXTS)
    for eid, fam in ORDER:
        assert eid in enemies, eid
        boss = bool(enemies[eid].get("boss", False))
        tiers = BOSS if boss else NORMAL
        entries.append({"id": eid, "family": fam, "boss": boss, "kills": tiers["kills"], "bonus": tiers["bonus"],
                        "model": enemies[eid].get("model", ""), "maps": places.get(eid, [])})
    for fam, (pt, en) in FAMILY_TEXT.items():
        texts["BS_FAM_" + fam.upper()] = (pt, en)
    missing = [e for e in enemies if e not in dict(ORDER) and e not in FORMS]
    if missing:
        raise SystemExit("faltam no bestiário: %s" % missing)
    mastery = json.loads(json.dumps(MASTERY))
    for k, b in mastery["branches"].items():
        texts["BS_BRANCH_" + k.upper()] = (b.pop("pt"), b.pop("en"))
        texts["BS_BRANCH_" + k.upper() + "_FX"] = (b.pop("fx_pt"), b.pop("fx_en"))
    doc = {"_comment": "Bestiário e Maestria (Fase 8E). Gerado por tools/content/gen_bestiary.py; não editar à mão. Cada ficha: marcos de abates ('kills') e o bônus de dano contra o monstro em cada marco ('bonus'); a fraqueza aparece no 1º marco. 'forms': formas de chefe que contam para o chefe.",
           "entries": entries, "forms": FORMS, "mastery": mastery}
    json_compact.write(str(ROOT / "data" / "world" / "bestiary.json"), doc)
    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body, seen = rows[0], [], set()
    for r in rows[1:]:
        if not r or r[0].startswith("BS_") or r[0] in seen:
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
    print("ok: %d fichas, %d textos" % (len(entries), len(texts)))


if __name__ == "__main__":
    main()
