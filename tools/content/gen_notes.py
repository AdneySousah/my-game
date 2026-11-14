#!/usr/bin/env python3
"""Notas de atualização ("Novidades") e textos do aviso de versão nova (pedido do dono, 14/11/2026).

Gera:
  - data/updates/notes.json    uma entrada por versão (a mais nova primeiro) com as chaves dos itens
  - data/i18n/strings.csv      chaves NOTES_* e UPD_* (troca só as dele)

Antes de cada versão nova para a Play: subir version/code e version/name em export_presets.cfg,
config/version em project.godot e escrever a versão aqui no topo de VERSIONS (o teste
"notes" falha se a versão do jogo não tiver nota). Texto para o jogador, curto, sem termos
técnicos, em pt_BR e en lado a lado.

Rodar:  python -X utf8 tools/content/gen_notes.py
"""
import csv
import io
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import json_compact  # noqa: E402

# Newest first. "date" as AAAA-MM-DD; each item is (pt_BR, en).
VERSIONS = [
    {"name": "0.4.1", "date": "2026-11-14", "items": [
        ("Tela de Novidades: mostra o que mudou em cada versão e abre sozinha depois de uma atualização. Fica também em Opções.",
         "What's New screen: shows what changed in each version and opens by itself after an update. Also in Options."),
        ("Quando sair uma versão nova na Google Play, o jogo avisa na tela inicial e atualiza sem você precisar abrir a loja.",
         "When a new version is out on Google Play, the title screen tells you and updates the game without opening the store."),
    ]},
    {"name": "0.4.0", "date": "2026-11-13", "items": [
        ("Botão Defesa: segure para bloquear e toque na hora certa para aparar. Inimigos empurrados ficam tontos.",
         "Guard button: hold to block and tap at the right moment to parry. Knocked-back enemies get dizzy."),
        ("O Despertar: depois da Sahra, encha a luz e segure Atacar por 3 segundos para lutar mais forte.",
         "The Awakening: after Sahra, fill the light and hold Attack for 3 seconds to fight stronger."),
        ("Covis do Ferreiro Andarilho (seg, qua, sex e dom): chefes com conjuntos próprios e combos.",
         "The Wandering Smith's Lairs (Mon, Wed, Fri and Sun): bosses with their own gear sets and combos."),
        ("Runas nas skills e elementos: cada monstro tem fraquezas e resistências.",
         "Runes for your skills and elements: every monster has weaknesses and resistances."),
        ("Pesca nos rios e lagos e comidas na fogueira com bônus.",
         "Fishing in rivers and lakes, and campfire food with bonuses."),
        ("Bestiário com marcos de abates e Maestria depois do nível 100.",
         "Bestiary with kill milestones, and Mastery after level 100."),
        ("Casa do herói em Pradoluz: baú, cama para descansar, suporte de armas e troféus.",
         "The hero's house in Pradoluz: chest, a bed to rest, a weapon rack and trophies."),
        ("Eventos nos campos: horda, caravana, chefe errante e chuva de estrelas.",
         "Field events: horde, caravan, wandering boss and star shower."),
        ("Fenda sem fim (a partir do nível 30): andares sorteados, bênçãos e recorde.",
         "Endless Rift (from level 30): random floors, blessings and your best record."),
        ("Gráficos no Automático: o jogo escolhe a qualidade pelo celular e baixa sozinho se pesar. Menos travadinhas e suporte a celulares de 32 bits.",
         "Automatic graphics: the game picks the quality for your phone and lowers it if it gets slow. Fewer stutters and support for 32-bit phones."),
    ]},
    {"name": "0.3.6", "date": "2026-11-13", "items": [
        ("Pós-jogo: Modo Infernal, conjuntos que mudam o visual do Lio e títulos novos.",
         "Post-game: Infernal Mode, gear sets that change Lio's look and new titles."),
        ("Skills gastam MP, 3 atalhos de poção, até 3 missões na lateral e viagem pelo mapa-múndi.",
         "Skills use MP, 3 potion shortcuts, up to 3 quests on the side and travel through the world map."),
        ("Dificuldade Extrema e Procurado diário em cada cidade.",
         "Extreme difficulty and a daily Wanted bounty in every town."),
        ("Lagos e rios novos com vitórias-régias, sapos e peixes; músicas e sons novos.",
         "New lakes and rivers with water lilies, frogs and fish; new music and sounds."),
        ("Mochilas extras, o visual Anjo Dourado e gráficos Baixo, Médio e Alto.",
         "Extra backpacks, the Golden Angel look and Low, Medium and High graphics."),
    ]},
]

UI = {
    "NOTES_TITLE": ("Novidades", "What's New"),
    "NOTES_VERSION": ("Versão %s  •  %s", "Version %s  •  %s"),
    "NOTES_BUTTON": ("Novidades", "What's New"),
    "UPD_TITLE": ("Versão nova!", "New version!"),
    "UPD_TEXT": ("Uma versão nova do jogo está na Google Play. Atualize para ter as novidades e correções; seu progresso continua salvo.",
                 "A new version of the game is on Google Play. Update to get the news and fixes; your progress stays saved."),
    "UPD_NOW": ("Atualizar agora", "Update now"),
    "UPD_LATER": ("Depois", "Later"),
    "UPD_FAILED": ("Não deu para atualizar agora. Tente de novo mais tarde ou pela Google Play.",
                   "Couldn't update right now. Try again later or through Google Play."),
}


def key_of(name: str, i: int) -> str:
    return "NOTES_%s_%d" % (name.replace(".", "_"), i + 1)


def main() -> None:
    texts = dict(UI)
    versions = []
    for v in VERSIONS:
        keys = []
        for i, (pt, en) in enumerate(v["items"]):
            k = key_of(v["name"], i)
            texts[k] = (pt, en)
            keys.append(k)
        versions.append({"name": v["name"], "date": v["date"], "items": keys})
    doc = {"_comment": "Notas de atualização (tela Novidades). Gerado por tools/content/gen_notes.py; não editar à mão. A mais nova primeiro; 'items' são chaves do strings.csv.",
           "versions": versions}
    out = ROOT / "data" / "updates" / "notes.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    json_compact.write(str(out), doc)
    cpath = ROOT / "data" / "i18n" / "strings.csv"
    rows = list(csv.reader(io.StringIO(cpath.read_text(encoding="utf-8"))))
    header, body, seen = rows[0], [], set()
    for r in rows[1:]:
        if not r or r[0].startswith("NOTES_") or r[0].startswith("UPD_") or r[0] in seen:
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
    print("ok: %d versões, %d textos" % (len(versions), len(texts)))


if __name__ == "__main__":
    main()
